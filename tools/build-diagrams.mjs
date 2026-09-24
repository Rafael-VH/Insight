#!/usr/bin/env node
/**
 * Genera el dashboard de diagramas y lo deja listo para GitHub Pages.
 *
 * Salidas (todas generadas: no editarlas a mano):
 *   docs/index.html                         el dashboard
 *   docs/404.html                           página no encontrada del sitio
 *   docs/diagramas/manifest.json            datos del listado
 *   docs/diagramas/<slug>/index.html        el diagrama + el botón de volver
 *
 * Uso:  node tools/build-diagrams.mjs [--sin-boton] [--inyector <ruta>]
 *
 * Config: tools/dashboard.config.json (lo escribe scripts/scaffold.mjs).
 */

import { execFileSync, spawnSync } from 'node:child_process';
import { existsSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docsDir = path.join(repoRoot, 'docs');
const diagramasDir = path.join(docsDir, 'diagramas');
const configPath = path.join(repoRoot, 'tools', 'dashboard.config.json');
const plantillaPath = path.join(repoRoot, 'tools', 'dashboard.template.html');
const plantilla404Path = path.join(repoRoot, 'tools', '404.template.html');

const TIPOS = new Set(['architecture', 'workflow', 'sequence', 'dataflow', 'lifecycle']);

const ETIQUETA_TIPO = {
  architecture: 'Arquitectura',
  workflow: 'Proceso',
  sequence: 'Secuencia',
  dataflow: 'Flujo de datos',
  lifecycle: 'Ciclo de vida',
};

// Cada tipo de diagrama usa nombres distintos para sus elementos; mapeamos
// "nodos" y "relaciones" al array real de la spec (en lugar de asumir
// components/connections, que solo existe en architecture).
const CAMPOS_POR_TIPO = {
  architecture: { nodos: 'components', relaciones: 'connections' },
  workflow: { nodos: 'nodes', relaciones: 'edges' },
  sequence: { nodos: 'participants', relaciones: 'messages' },
  dataflow: { nodos: 'nodes', relaciones: 'flows' },
  lifecycle: { nodos: 'states', relaciones: 'transitions' },
};

const INYECTOR_POR_DEFECTO = path.join(
  homedir(),
  '.agents',
  'skills',
  'archify-ui-injection',
  'scripts',
  'inject-ui.mjs',
);

function aPosix(ruta) {
  return ruta.split(path.sep).join('/');
}

function morir(mensaje) {
  console.error(`build-diagrams: ${mensaje}`);
  process.exit(1);
}

function leerJson(ruta, errores) {
  try {
    return JSON.parse(readFileSync(ruta, 'utf8'));
  } catch (error) {
    errores.push(`${aPosix(path.relative(repoRoot, ruta))}: JSON inválido (${error.message})`);
    return null;
  }
}

function normalizarEtiquetas(valor) {
  if (!Array.isArray(valor)) return [];
  const limpias = valor
    .filter((etiqueta) => typeof etiqueta === 'string')
    .map((etiqueta) => etiqueta.trim())
    .filter(Boolean);
  return [...new Set(limpias)];
}

function fechaDeActualizacion(relPath, absPath) {
  try {
    const salida = execFileSync('git', ['log', '-1', '--date=short', '--format=%cd', '--', relPath], {
      cwd: repoRoot,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    if (salida) return salida;
  } catch {
    // Sin git disponible: caemos al mtime.
  }
  return statSync(absPath).mtime.toISOString().slice(0, 10);
}

function leerConfig() {
  if (!existsSync(configPath)) {
    morir(
      `falta tools/dashboard.config.json. Copiá los archivos con ` +
        `scripts/scaffold.mjs de la skill archify-diagrams-dashboard, o creá el archivo a mano.`,
    );
  }

  const config = JSON.parse(readFileSync(configPath, 'utf8'));

  for (const clave of ['titulo', 'repoUrl', 'rama']) {
    if (!config[clave]) morir(`tools/dashboard.config.json no define "${clave}"`);
  }

  return {
    titulo: config.titulo,
    descripcion: config.descripcion || 'Diagramas interactivos del proyecto.',
    repoUrl: config.repoUrl.replace(/\/+$/, ''),
    rama: config.rama,
    basePath: config.basePath || `/${config.repoUrl.split('/').pop()}/`,
    etiquetaBoton: config.etiquetaBoton || '',
    hrefBoton: config.hrefBoton || '../../index.html',
    inyector: config.inyector || '',
  };
}

function recolectar() {
  const errores = [];

  if (!existsSync(diagramasDir)) {
    return { diagramas: [], errores: ['no existe docs/diagramas/'] };
  }

  const slugs = readdirSync(diagramasDir, { withFileTypes: true })
    .filter((entrada) => entrada.isDirectory() && !entrada.name.startsWith('.') && !entrada.name.startsWith('_'))
    .map((entrada) => entrada.name)
    .sort();

  const diagramas = [];

  for (const slug of slugs) {
    const dir = path.join(diagramasDir, slug);
    const htmlAbs = path.join(dir, `${slug}.html`);
    const specAbs = path.join(dir, `${slug}.json`);

    if (!existsSync(htmlAbs)) {
      errores.push(`docs/diagramas/${slug}/: falta ${slug}.html`);
      continue;
    }
    if (!existsSync(specAbs)) {
      errores.push(`docs/diagramas/${slug}/: falta ${slug}.json`);
      continue;
    }

    const spec = leerJson(specAbs, errores);
    if (!spec) continue;

    const tipo = typeof spec.diagram_type === 'string' ? spec.diagram_type : 'architecture';
    if (!TIPOS.has(tipo)) {
      errores.push(`docs/diagramas/${slug}/${slug}.json: diagram_type desconocido "${tipo}"`);
    }

    const extraAbs = path.join(dir, 'dashboard.json');
    const extra = existsSync(extraAbs) ? leerJson(extraAbs, errores) ?? {} : {};

    const htmlRel = aPosix(path.relative(repoRoot, htmlAbs));
    const campos = CAMPOS_POR_TIPO[tipo] || { nodos: 'components', relaciones: 'connections' };

    diagramas.push({
      slug,
      titulo: typeof spec.meta?.title === 'string' && spec.meta.title ? spec.meta.title : slug,
      tipo,
      tipoTexto: ETIQUETA_TIPO[tipo] || tipo,
      descripcion: typeof extra.descripcion === 'string' ? extra.descripcion : '',
      etiquetas: normalizarEtiquetas(extra.etiquetas),
      destacado: extra.destacado === true,
      nodos: Array.isArray(spec[campos.nodos]) ? spec[campos.nodos].length : 0,
      relaciones: Array.isArray(spec[campos.relaciones]) ? spec[campos.relaciones].length : 0,
      capitulos: Array.isArray(spec.meta?.views) ? spec.meta.views.length : 0,
      actualizado: fechaDeActualizacion(htmlRel, htmlAbs),
      // Los enlaces apuntan a la copia publicada (con el botón), no al artefacto.
      archivo: aPosix(path.join(path.relative(docsDir, dir), 'index.html')),
      especificacion: aPosix(path.relative(docsDir, specAbs)),
      artefacto: htmlAbs,
      destino: path.join(dir, 'index.html'),
    });
  }

  diagramas.sort((a, b) => {
    if (a.destacado !== b.destacado) return a.destacado ? -1 : 1;
    if (a.actualizado !== b.actualizado) return a.actualizado < b.actualizado ? 1 : -1;
    return a.titulo.localeCompare(b.titulo, 'es');
  });

  return { diagramas, errores };
}

function rellenar(plantilla, valores) {
  let salida = plantilla;
  for (const [clave, valor] of Object.entries(valores)) {
    salida = salida.split(`__${clave}__`).join(valor);
  }
  return salida;
}

function escribirDashboard(config, diagramas) {
  const plantilla = readFileSync(plantillaPath, 'utf8');
  if (!plantilla.includes('__DIAGRAMAS__')) {
    morir('tools/dashboard.template.html no contiene __DIAGRAMAS__');
  }

  // Igual que el manifest: sin campos absolutos, para que los datos embebidos
  // sean idénticos en cualquier máquina (CI ubuntu incluida).
  const publicables = diagramas.map(({ artefacto, destino, ...resto }) => resto);
  const datos = JSON.stringify({ total: publicables.length, diagramas: publicables }).replace(/</g, '\\u003c');
  const html = rellenar(plantilla, {
    TITULO: config.titulo,
    DESCRIPCION: config.descripcion,
    REPO_URL: config.repoUrl,
    REPO_LABEL: config.repoUrl.replace(/^https?:\/\/(www\.)?github\.com\//, ''),
    RAMA: config.rama,
    DIAGRAMAS: datos,
  });

  writeFileSync(path.join(docsDir, 'index.html'), html, 'utf8');
}

function escribir404(config) {
  if (!existsSync(plantilla404Path)) return false;
  const plantilla = readFileSync(plantilla404Path, 'utf8');
  const html = rellenar(plantilla, {
    TITULO: config.titulo,
    BASE_PATH: config.basePath,
  });
  writeFileSync(path.join(docsDir, '404.html'), html, 'utf8');
  return true;
}

function escribirManifest(diagramas) {
  const manifest = {
    generado_por: 'tools/build-diagrams.mjs',
    total: diagramas.length,
    diagramas: diagramas.map(({ artefacto, destino, ...resto }) => resto),
  };
  writeFileSync(
    path.join(diagramasDir, 'manifest.json'),
    `${JSON.stringify(manifest, null, 2)}\n`,
    'utf8',
  );
}

function publicarPaginas(config, diagramas, opciones) {
  let inyector = opciones.inyector || config.inyector || INYECTOR_POR_DEFECTO;
  const sinBoton = opciones.sinBoton;

  if (!sinBoton && !existsSync(inyector)) {
    morir(
      `no encuentro el inyector de botones en ${inyector}.\n` +
        `  Instalá la skill archify-ui-injection, pasá --inyector <ruta> a inject-ui.mjs,\n` +
        `  o usá --sin-boton si no querés el botón de volver.`,
    );
  }

  let inyectados = 0;

  for (const diagrama of diagramas) {
    if (sinBoton) {
      writeFileSync(diagrama.destino, readFileSync(diagrama.artefacto, 'utf8'), 'utf8');
      continue;
    }

    const argsInyector = [
      inyector,
      diagrama.artefacto,
      diagrama.destino,
      '--href',
      config.hrefBoton,
      '--clase',
      `archify-back-${diagrama.slug}`,
    ];
    if (config.etiquetaBoton) argsInyector.push('--label', config.etiquetaBoton);

    const resultado = spawnSync(process.execPath, argsInyector, {
      stdio: ['ignore', 'pipe', 'pipe'],
      encoding: 'utf8',
    });

    if (resultado.status !== 0) {
      morir(
        `el inyector falló para ${diagrama.slug}:\n` +
          `${resultado.stderr || resultado.stdout || '(sin salida)'}`,
      );
    }
    inyectados += 1;
  }

  return inyectados;
}

function main() {
  const argv = process.argv.slice(2);
  const opciones = { sinBoton: argv.includes('--sin-boton'), inyector: '' };

  const posInyector = argv.indexOf('--inyector');
  if (posInyector !== -1) {
    const valor = argv[posInyector + 1];
    if (!valor || valor.startsWith('--')) morir('--inyector requiere una ruta');
    opciones.inyector = valor;
  }

  const config = leerConfig();
  const { diagramas, errores } = recolectar();

  if (errores.length > 0) {
    console.error('No se pudo generar el dashboard:');
    for (const error of errores) console.error(`  - ${error}`);
    process.exit(1);
  }

  if (diagramas.length === 0) {
    morir('no hay diagramas en docs/diagramas/');
  }

  escribirManifest(diagramas);
  escribirDashboard(config, diagramas);
  const con404 = escribir404(config);
  const inyectados = publicarPaginas(config, diagramas, opciones);

  const partes = [`docs/index.html`, `docs/diagramas/manifest.json`];
  if (con404) partes.push('docs/404.html');
  partes.push(inyectados ? `${inyectados} página(s) con botón` : `${diagramas.length} página(s) sin botón`);

  console.log(`OK · ${diagramas.length} diagrama(s) → ${partes.join(', ')}`);
}

main();
