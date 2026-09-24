#!/usr/bin/env node
/**
 * inject-ui.mjs — inyecta un botón propio dentro de un diagrama de archify.
 *
 * Nunca modifica el artefacto de entrada: lee y escribe una copia. Pensado para
 * encadenarse después de `archify deliver`.
 *
 * Uso:
 *   node inject-ui.mjs <entrada.html> <salida.html> --href <url> [opciones]
 *
 * Opciones:
 *   --href <url>        destino del enlace (obligatorio)
 *   --label <texto>     texto visible del botón (por defecto: ninguno, solo la flecha)
 *   --ancla <nombre>    header-row | toolbar | body  (por defecto: header-row)
 *   --clase <nombre>    marcador del botón, permite varios botones distintos
 *                       en el mismo diagrama (por defecto: archify-back)
 *   --titulo <texto>    atributo title y, si no hay label, nombre accesible
 *                       (por defecto: "Volver")
 *   --lang <código>     atributo lang del control (por defecto: es)
 *   --sin-icono         no agregar la flecha (requiere --label)
 *   --help              muestra esta ayuda
 *
 * El control es solo la flecha salvo que se pase --label: el nombre accesible
 * queda en aria-label/title, que el visor no dibuja.
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';

const ESTILO = `  <style id="archify-ui-style">
    /* Réplica de .toolbar button del visor: usa sus tokens, así el control
       hereda el tema claro/oscuro y los presets sin duplicar la paleta. */
    .archify-ui-btn {
      flex: 0 0 auto;
      display: inline-flex;
      align-items: center;
      gap: .375rem;
      min-height: 2.75rem;
      padding: .5rem .875rem;
      border-radius: .625rem;
      border: 1px solid var(--toolbar-border);
      background: var(--toolbar-bg);
      color: var(--toolbar-text);
      backdrop-filter: blur(10px);
      box-shadow: 0 4px 14px rgba(0, 0, 0, .08);
      transition: background .15s, border-color .15s, color .15s;
      font-family: inherit;
      font-size: .75rem;
      font-weight: 500;
      line-height: 1;
      text-decoration: none;
      white-space: nowrap;
      cursor: pointer;
    }
    .archify-ui-btn:hover {
      background: var(--toolbar-hover);
      border-color: color-mix(in srgb, var(--arrow) 62%, var(--toolbar-border));
    }
    .archify-ui-btn:focus-visible { outline: 2px solid var(--arrow-emphasis); outline-offset: 2px; }
    .archify-ui-btn svg { width: .95rem; height: .95rem; flex: 0 0 auto; }

    html[data-present="true"] .archify-ui-btn { display: none; }
    html[data-preset="editorial"] .archify-ui-btn { border-radius: .3rem; }

    @media (max-width: 360px) {
      .archify-ui-btn span { display: none; }
      .archify-ui-btn { padding-right: .58rem; padding-left: .58rem; }
    }

    .archify-ui-btn--flotante { position: fixed; top: 1rem; left: 1rem; z-index: 60; }
  </style>
`;

const FLECHA =
  '<svg viewBox="0 0 24 24" aria-hidden="true" focusable="false">' +
  '<path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" ' +
  'stroke-linejoin="round" d="M19 12H5m0 0 6-6m-6 6 6 6"/></svg>';

const ANCLAS = {
  'header-row': /<div class="header-row"[^>]*>/,
  toolbar: /<div class="toolbar"[^>]*>/,
  body: /<body[^>]*>/,
};

function ayuda() {
  return [
    'Uso: node inject-ui.mjs <entrada.html> <salida.html> --href <url> [opciones]',
    '',
    'Opciones:',
    '  --href <url>      destino del enlace (obligatorio)',
    '  --label <texto>   texto visible del botón (por defecto: ninguno, solo la flecha)',
    '  --ancla <nombre>  header-row | toolbar | body (por defecto: header-row)',
    '  --clase <nombre>  marcador del botón (por defecto: archify-back)',
    '  --titulo <texto>  title y, si no hay label, nombre accesible (por defecto: "Volver")',
    '  --lang <código>   atributo lang (por defecto: es)',
    '  --sin-icono       no agregar la flecha (requiere --label)',
    '  --help            muestra esta ayuda',
  ].join('\n');
}

function morir(mensaje) {
  console.error(`inject-ui: ${mensaje}`);
  process.exit(1);
}

function escapar(texto) {
  return String(texto)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function analizarArgumentos(argv) {
  const posicionales = [];
  const opciones = { label: '', ancla: 'header-row', clase: 'archify-back', lang: 'es' };

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--help' || arg === '-h') return { ayuda: true };
    if (arg === '--sin-icono') {
      opciones.icono = false;
      continue;
    }
    if (arg.startsWith('--')) {
      const clave = arg.slice(2);
      const valor = argv[i + 1];
      if (valor === undefined || valor.startsWith('--')) morir(`falta el valor de ${arg}`);
      opciones[clave] = valor;
      i += 1;
      continue;
    }
    posicionales.push(arg);
  }

  return { posicionales, opciones };
}

function main() {
  const { ayuda: pedirAyuda, posicionales, opciones } = analizarArgumentos(process.argv.slice(2));

  if (pedirAyuda) {
    console.log(ayuda());
    return;
  }

  if (posicionales.length !== 2) morir(`esperaba <entrada.html> y <salida.html>\n\n${ayuda()}`);

  const [entrada, salida] = posicionales;
  const href = opciones.href;
  const label = opciones.label;
  const marcador = opciones.clase;
  const ancla = opciones.ancla;

  if (!href) morir(`falta --href\n\n${ayuda()}`);
  if (!existsSync(entrada)) morir(`no existe ${entrada}`);
  if (!(ancla in ANCLAS)) morir(`--ancla debe ser uno de: ${Object.keys(ANCLAS).join(', ')}`);

  let html = readFileSync(entrada, 'utf8');
  const bytesEntrada = Buffer.byteLength(html);

  if (html.includes(`data-archify-ui="${marcador}"`)) {
    writeFileSync(salida, html, 'utf8');
    console.log(`OK · el botón "${marcador}" ya estaba inyectado → ${salida}`);
    return;
  }

  if (!html.includes('</head>')) morir('el HTML no tiene </head>');
  if (!html.includes('archify-ui-btn')) html = html.replace('</head>', `${ESTILO}</head>`);

  // Sin --label el control es solo la flecha: el nombre accesible queda en
  // aria-label/title, que el visor no dibuja.
  const titulo = opciones.titulo || label || 'Volver';
  const nombre = label || titulo;
  const icono = opciones.icono === false ? '' : FLECHA;
  const texto = label ? `<span>${escapar(label)}</span>` : '';

  if (!icono && !texto) morir('sin flecha ni --label el botón quedaría vacío');

  const boton =
    `<a class="archify-ui-btn no-print" data-archify-ui="${escapar(marcador)}" ` +
    `href="${escapar(href)}" aria-label="${escapar(nombre)}" title="${escapar(titulo)}" ` +
    `lang="${escapar(opciones.lang)}">${icono}${texto}</a>`;

  const encontrada = ANCLAS[ancla].exec(html);
  const usarFlotante = !encontrada;
  const anclaFinal = encontrada || ANCLAS.body.exec(html);

  if (!anclaFinal) morir('el HTML no tiene <body>');

  const botonFinal = usarFlotante
    ? boton.replace('class="archify-ui-btn ', 'class="archify-ui-btn archify-ui-btn--flotante ')
    : boton;

  const corte = anclaFinal.index + anclaFinal[0].length;
  html = html.slice(0, corte) + botonFinal + html.slice(corte);

  writeFileSync(salida, html, 'utf8');

  const anclaUsada = encontrada ? ancla : 'body (flotante)';
  console.log(
    `OK · botón "${marcador}" inyectado en ${anclaUsada} · ` +
      `${bytesEntrada} → ${Buffer.byteLength(html)} bytes → ${salida}`,
  );
}

main();
