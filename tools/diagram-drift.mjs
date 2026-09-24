#!/usr/bin/env node
/**
 * Audita si los diagramas siguen siendo fieles al código.
 *
 * Usa la evidencia que archify deja en cada especificación: la revisión del repo que se
 * fijó al entregar (`meta.repository.revision`) y las rutas de código de cada nodo
 * (`components[].sources[].path`).
 *
 * Estados:
 *   roto           alguna ruta de sources no existe en el repo
 *   a revisar      alguno de los archivos documentados cambió entre la revisión y HEAD
 *   al día         el pin está atrás, pero ningún archivo documentado cambió
 *   sin evidencia  la spec no declara revisión ni sources
 *
 * Uso:
 *   node drift.mjs [ruta-repo] [--json] [--estricto] [--diagrama <slug>]
 *
 * Con --estricto sale con código 1 si hay algún diagrama roto o a revisar (para CI).
 */

import { execFileSync } from 'node:child_process';
import { existsSync, readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';

function morir(mensaje) {
  console.error(`drift: ${mensaje}`);
  process.exit(2);
}

function git(repo, args) {
  try {
    return execFileSync('git', args, {
      cwd: repo,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
  } catch {
    return '';
  }
}

function analizarArgumentos(argv) {
  const opciones = { estricto: false };
  const posicionales = [];

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--estricto') {
      opciones.estricto = true;
      continue;
    }
    if (arg === '--json') {
      opciones.json = true;
      continue;
    }
    if (arg === '--help' || arg === '-h') {
      console.log('Uso: node drift.mjs [ruta-repo] [--json] [--estricto] [--diagrama <slug>]');
      process.exit(0);
    }
    if (arg.startsWith('--')) {
      const valor = argv[i + 1];
      if (valor === undefined || valor.startsWith('--')) morir(`falta el valor de ${arg}`);
      opciones[arg.slice(2)] = valor;
      i += 1;
      continue;
    }
    posicionales.push(arg);
  }

  return { posicionales, opciones };
}

function rutasDeEvidencia(spec) {
  const rutas = new Set();
  const recolectar = (lista) => {
    for (const item of lista || []) {
      for (const fuente of item.sources || []) {
        if (typeof fuente.path === 'string' && fuente.path) rutas.add(fuente.path);
      }
    }
  };
  recolectar(spec.components);
  recolectar(spec.nodes);
  return [...rutas].sort();
}

function analizarDiagrama(repo, slug, spec, head) {
  const rutas = rutasDeEvidencia(spec);
  const revision = spec.meta?.repository?.revision || '';
  const faltantes = rutas.filter((ruta) => !existsSync(path.join(repo, ruta)));

  const resultado = {
    slug,
    titulo: spec.meta?.title || slug,
    tipo: spec.diagram_type || 'desconocido',
    estado: 'sin evidencia',
    revision: revision ? revision.slice(0, 7) : null,
    head,
    rutas: rutas.length,
    faltantes,
    archivosCambiados: [],
    commitsDesdeElPin: 0,
    nota: '',
  };

  if (faltantes.length > 0) {
    resultado.estado = 'roto';
    resultado.nota = `${faltantes.length} ruta(s) de sources ya no existen`;
    return resultado;
  }

  if (rutas.length === 0 && !revision) {
    resultado.nota = 'la spec no declara revision ni sources: no hay nada que verificar';
    return resultado;
  }

  if (!revision) {
    resultado.estado = 'sin evidencia';
    resultado.nota = 'declara sources pero no fija una revisión del repo';
    return resultado;
  }

  const pinCompleto = git(repo, ['rev-parse', `${revision}^{commit}`]);
  if (!pinCompleto) {
    resultado.estado = 'roto';
    resultado.nota = `la revisión ${revision} no existe en este repo`;
    return resultado;
  }

  resultado.commitsDesdeElPin = Number(git(repo, ['rev-list', '--count', `${pinCompleto}..HEAD`])) || 0;

  if (pinCompleto === head) {
    resultado.estado = 'al día';
    resultado.nota = 'el pin coincide con HEAD';
    return resultado;
  }

  for (const ruta of rutas) {
    const log = git(repo, ['log', '--oneline', `${pinCompleto}..HEAD`, '--', ruta]);
    if (log) {
      resultado.archivosCambiados.push({ ruta, commits: log.split('\n').length });
    }
  }

  if (resultado.archivosCambiados.length > 0) {
    resultado.estado = 'a revisar';
    resultado.nota =
      `${resultado.archivosCambiados.length} de ${rutas.length} archivo(s) documentados ` +
      `cambiaron desde el pin`;
  } else {
    resultado.estado = 'al día';
    resultado.nota =
      `el pin está ${resultado.commitsDesdeElPin} commit(s) atrás, pero ninguno toca los ` +
      `${rutas.length} archivos documentados`;
  }

  return resultado;
}

function main() {
  const { posicionales, opciones } = analizarArgumentos(process.argv.slice(2));
  const repo = path.resolve(posicionales[0] || process.cwd());

  if (!existsSync(repo)) morir(`no existe ${repo}`);

  const head = git(repo, ['rev-parse', 'HEAD']);
  if (!head) morir(`${repo} no parece un repositorio git`);

  const raiz = path.join(repo, 'docs', 'diagramas');
  if (!existsSync(raiz)) morir(`no existe docs/diagramas/ en ${repo}`);

  const slugs = readdirSync(raiz, { withFileTypes: true })
    .filter((e) => e.isDirectory() && !e.name.startsWith('.') && !e.name.startsWith('_'))
    .map((e) => e.name)
    .filter((slug) => !opciones.diagrama || slug === opciones.diagrama)
    .sort();

  if (slugs.length === 0) morir('no hay diagramas que auditar');

  const resultados = [];
  for (const slug of slugs) {
    const specPath = path.join(raiz, slug, `${slug}.json`);
    if (!existsSync(specPath)) {
      resultados.push({
        slug,
        titulo: slug,
        tipo: 'desconocido',
        estado: 'roto',
        revision: null,
        head: head.slice(0, 7),
        rutas: 0,
        faltantes: [`docs/diagramas/${slug}/${slug}.json`],
        archivosCambiados: [],
        commitsDesdeElPin: 0,
        nota: 'falta la especificación',
      });
      continue;
    }
    resultados.push(analizarDiagrama(repo, slug, JSON.parse(readFileSync(specPath, 'utf8')), head));
  }

  const resumen = resultados.reduce((acc, r) => {
    acc[r.estado] = (acc[r.estado] || 0) + 1;
    return acc;
  }, {});

  if (opciones.json) {
    console.log(JSON.stringify({ repo, head: head.slice(0, 7), resumen, diagramas: resultados }, null, 2));
  } else {
    console.log(`drift · ${repo}`);
    console.log(`  HEAD ${head.slice(0, 7)}  ·  ${resultados.length} diagrama(s)`);
    console.log('');
    for (const r of resultados) {
      const pinta = { roto: 'ROTO      ', 'a revisar': 'A REVISAR ', 'al día': 'AL DÍA    ' }[r.estado] || 'SIN EVID. ';
      console.log(`  ${pinta} ${r.slug}  (${r.tipo})`);
      console.log(`            pin ${r.revision || '—'} · ${r.nota}`);
      for (const f of r.faltantes) console.log(`            falta: ${f}`);
      for (const c of r.archivosCambiados) console.log(`            cambió: ${c.ruta} (${c.commits} commit/s)`);
    }
    console.log('');
    console.log(
      '  resumen: ' +
        Object.entries(resumen)
          .map(([estado, n]) => `${n} ${estado}`)
          .join(' · '),
    );
  }

  const problematicos = resultados.filter((r) => r.estado === 'roto' || r.estado === 'a revisar');
  if (opciones.estricto && problematicos.length > 0) process.exit(1);
}

main();
