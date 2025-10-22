// Importación de módulos necesarios
const fs = require('fs');                      // (Contexto) Acceso a sistema de archivos
const fsPromises = fs.promises;               // (Contexto) API basada en Promesas
const path = require('path');                 // (Contexto) Manejo de rutas
const PDFDocument = require('pdfkit');        // (Contexto) Generación de PDF
const yargs = require('yargs');               // (Contexto) CLI args
const readline = require('readline-sync');    // (Contexto) Entradas síncronas por consola

// --- CONFIGURACIÓN GLOBAL ---

// 1) Extensiones permitidas para escanear solo código fuente.
const EXTENSIONS = ['.dart', '.py'];

// 2) Archivos “extra” (top-level o rutas fijas) a incluir si existen.
//    (Contexto) Estos NO dependen de EXTENSIONS.
const EXTRA_FILES = [
  'pubspec.yaml',
  'pubspec.lock',
  'analysis_options.yaml',
  '.gitignore',
  // Android específicos fijos frecuentes:
  'android/build.gradle',
  'android/settings.gradle',
  'android/gradle.properties',
  'android/gradle/wrapper/gradle-wrapper.properties',
  'android/app/build.gradle',
  'android/app/proguard-rules.pro',
];

// 3) CLI con yargs.
//    - type: pdf|txt
//    - individual: un archivo por entrada vs combinado
//    - output: carpeta de salida
//    - include-secrets: incluye google-services.json, key.properties, etc. (por defecto NO)
const argv = yargs
  .option('type', {
    alias: 't',
    choices: ['pdf', 'txt'],
    default: 'pdf'
  })
  .option('individual', {
    alias: 'i',
    type: 'boolean',
    default: false
  })
  .option('output', {
    alias: 'o',
    type: 'string'
  })
  .option('include-secrets', {
    alias: 'S',
    type: 'boolean',
    default: false,
    describe: 'Incluir archivos sensibles de Android (google-services.json, key.properties, *.keystore). Úsalo bajo tu responsabilidad.'
  })
  .argv;

// --- FUNCIONES AUXILIARES ---

/**
 * Obtiene recursivamente archivos por extensión dentro de un directorio.
 * @param {string} dir - Directorio base de búsqueda.
 * @param {string[]} exts - Extensiones válidas (ej: ['.dart','.py']).
 * @param {string[]} [archivos=[]] - Acumulador.
 * @returns {Promise<string[]>}
 *
 * Paso a paso:
 *  1) Leer entradas del directorio.
 *  2) Para cada entrada:
 *     2.1) Si es directorio -> recursión (exceptuar folders “pesados” o irrelevantes).
 *     2.2) Si es archivo y su extensión está permitida -> acumular.
 */
async function obtenerArchivosPorExtensiones(dir, exts, archivos = []) {
  const items = await fsPromises.readdir(dir, { withFileTypes: true });
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      // (Contexto) Excluir carpetas que no aportan código fuente deseado
      if (item.name === '.dart_tool' || item.name === 'build' || item.name === '.firebase' ||
          item.name === '.vscode' || item.name === 'ios' || item.name === 'windows' ||
          item.name === 'web' || item.name === 'linux' || item.name === 'macos') {
        continue;
      }
      await obtenerArchivosPorExtensiones(fullPath, exts, archivos);
    } else if (item.isFile() && exts.includes(path.extname(item.name).toLowerCase())) {
      archivos.push(fullPath);
    }
  }
  return archivos;
}

// 1) Caché de archivos para evitar re-escaneos
let archivosCache;

/**
 * Escanea selectivamente el directorio /android para recolectar SOLO archivos de configuración.
 * Evita arrastrar /build, /app/intermediates, etc.
 *
 * @param {string} projRoot - Raíz del proyecto.
 * @param {boolean} includeSecrets - Si true, incluye archivos potencialmente sensibles.
 * @returns {Promise<string[]>}
 *
 * Diseño:
 *  - Lista blanca por NOMBRE de archivo (gradle, manifests, proguard, props).
 *  - Recorre /android de forma recursiva, pero:
 *    * Ignora carpetas conocidas de build/.gradle.
 *    * Filtra por nombres permitidos.
 *    * Añade secretos solo si includeSecrets === true.
 */
async function obtenerArchivosAndroidConfig(projRoot, includeSecrets = false) {
  // (Contexto) Directorio base Android
  const ANDROID_DIR = path.join(projRoot, 'android');

  // 1) Si /android no existe, salir rápido.
  try { await fsPromises.access(ANDROID_DIR); } catch { return []; }

  // 2) Carpetas a ignorar para no cargar artefactos de build.
  const IGNORE_DIRS = new Set([
    'build', '.gradle', '.idea', 'app/build', 'intermediates', 'outputs'
  ]);

  // 3) Nombres permitidos (config “no sensible”).
  //    (Contexto) Se filtra por nombre exacto o regex simples.
  const SAFE_NAMES = new Set([
    'build.gradle', 'settings.gradle', 'gradle.properties',
    'gradle-wrapper.properties', 'proguard-rules.pro',
    'AndroidManifest.xml',
    // Soporte .kts por si migraste a Kotlin DSL
    'build.gradle.kts', 'settings.gradle.kts'
  ]);

  // 4) Patrones adicionales para localizar Manifests en flavors/buildTypes.
  const SAFE_REGEX = [
    /AndroidManifest\.xml$/i,
    /proguard.*\.pro$/i,
    /gradle-wrapper\.properties$/i,
  ];

  // 5) Archivos sensibles (solo se agregan si includeSecrets=true).
  const SECRET_NAMES = new Set([
    'google-services.json',      // (Riesgo) API keys y config Firebase
    'key.properties',            // (Riesgo) ruta keystore y contraseña
  ]);
  const SECRET_REGEX = [
    /\.keystore$/i,              // (Riesgo) keystores
    /\.jks$/i,                   // (Riesgo) keystores
  ];

  // 6) Recorrido DFS acotado.
  const resultados = [];
  async function walk(dir) {
    const entries = await fsPromises.readdir(dir, { withFileTypes: true });
    for (const ent of entries) {
      const full = path.join(dir, ent.name);
      if (ent.isDirectory()) {
        // 6.1) Saltar directorios ignorados
        const rel = path.relative(ANDROID_DIR, full).replace(/\\/g, '/');
        if ([...IGNORE_DIRS].some(ig => rel === ig || rel.startsWith(ig + '/'))) continue;
        await walk(full);
      } else if (ent.isFile()) {
        const base = path.basename(full);
        const isSafe =
          SAFE_NAMES.has(base) ||
          SAFE_REGEX.some(r => r.test(base));
        const isSecret =
          SECRET_NAMES.has(base) ||
          SECRET_REGEX.some(r => r.test(base));

        // 6.2) Incluir seguro
        if (isSafe) {
          resultados.push(full);
          continue;
        }
        // 6.3) Incluir secretos SOLO si se pidió explícitamente
        if (includeSecrets && isSecret) {
          resultados.push(full);
        }
      }
    }
  }

  // 7) Ejecutar recorrido
  await walk(ANDROID_DIR);

  // 8) Además, si existen, añade rutas fijas ya conocidas (por si el walker se saltó algo)
  const candidatosFijos = [
    'android/build.gradle',
    'android/settings.gradle',
    'android/gradle.properties',
    'android/gradle/wrapper/gradle-wrapper.properties',
    'android/app/build.gradle',
    'android/app/proguard-rules.pro',
    'android/app/src/main/AndroidManifest.xml',
    'android/app/src/debug/AndroidManifest.xml',
    'android/app/src/profile/AndroidManifest.xml',
  ];
  if (includeSecrets) {
    candidatosFijos.push('android/app/google-services.json', 'android/key.properties');
  }
  for (const rel of candidatosFijos) {
    const full = path.join(projRoot, rel);
    try {
      const st = await fsPromises.stat(full);
      if (st.isFile() && !resultados.includes(full)) resultados.push(full);
    } catch { /* no-op */ }
  }

  return resultados;
}

/**
 * Reúne todos los archivos relevantes del proyecto:
 *  - Código en /lib (EXTENSIONS)
 *  - EXTRA_FILES explícitos
 *  - Configuración Android (segura + opcional secretos)
 *
 * @param {string} projRoot
 * @returns {Promise<string[]>}
 *
 * Paso a paso:
 *  1) Si hay caché, devolverla.
 *  2) Escanear /lib por extensiones.
 *  3) Probar presencia de EXTRA_FILES.
 *  4) Escanear /android con lista blanca y (opcional) secretos.
 *  5) Unir y cachear.
 */
async function obtenerTodosArchivos(projRoot) {
  if (!archivosCache) {
    // 2) /lib por extensiones
    const archivosCodigo = await obtenerArchivosPorExtensiones(path.join(projRoot, 'lib'), EXTENSIONS);

    // 3) EXTRA_FILES si existen
    const archivosExtra = [];
    for (const rel of EXTRA_FILES) {
      const full = path.join(projRoot, rel);
      try {
        await fsPromises.access(full);
        const stat = await fsPromises.stat(full);
        if (stat.isFile()) archivosExtra.push(full);
      } catch { /* omitido si no existe */ }
    }

    // 4) Config de Android (segura + secretos opcionales)
    const archivosAndroid = await obtenerArchivosAndroidConfig(projRoot, argv['include-secrets']);

    // 5) Unir listas
    archivosCache = [...archivosCodigo, ...archivosExtra, ...archivosAndroid];
  }
  return archivosCache;
}

/**
 * Formatea un timestamp "dd_mm_yyyy_hhMMampm" para nombres de salida.
 */
function formatearFechaHoraBackup() {
  const now = new Date();
  const dd = String(now.getDate()).padStart(2, '0');
  const mm = String(now.getMonth() + 1).padStart(2, '0');
  const yyyy = now.getFullYear();
  let h = now.getHours();
  const m = now.getMinutes();
  const ampm = h >= 12 ? 'PM' : 'AM';
  h = h % 12 || 12;
  const mStr = String(m).padStart(2, '0');
  return `${dd}_${mm}_${yyyy}_${h}${mStr}${ampm}`;
}

// --- FUNCIONES PRINCIPALES DE GENERACIÓN ---

/**
 * Genera salidas individuales (PDF/TXT) por archivo.
 * @param {string} projRoot
 * @param {string} tipo - 'pdf' | 'txt'
 *
 * Pasos:
 *  1) Resolver carpeta base de salida y nombre de subcarpeta.
 *  2) Crear directorio destino con timestamp.
 *  3) Obtener lista de archivos relevantes (código + config + android).
 *  4) Por cada archivo:
 *     4.1) Derivar nombre relativo y “safeName”.
 *     4.2) Leer contenido (si no es PDF).
 *     4.3) Escribir TXT o PDF con encabezado/cola de archivo.
 */
async function generarIndividual(projRoot, tipo) {
  const base = argv.output
    ? path.resolve(process.cwd(), argv.output)
    : readline.questionPath('Ruta base para carpeta de salida: ', {
        isDirectory: true,
        create: true,
        exists: null,
      });

  const name = readline.question('Nombre de carpeta (sin espacios): ', {
    limit: /^[a-zA-Z0-9_.-]+$/,
    limitMessage: 'Nombre de carpeta inválido. Use solo letras, números, guiones bajos, puntos o guiones.'
  }).replace(/\s+/g, '_');

  const outDir = path.resolve(base, `${name}_backup_${formatearFechaHoraBackup()}`);
  await fsPromises.mkdir(outDir, { recursive: true });

  const archivos = await obtenerTodosArchivos(projRoot);

  for (const file of archivos) {
    const relativePath = path.relative(projRoot, file);
    const originalFileNameWithExt = path.basename(file);

    // (Contexto) safeName = ruta relativa transformada a nombre plano
    const safeName = relativePath.replace(/[\/\\]/g, '_');

    const content = file.endsWith('.pdf')
      ? null
      : (await fsPromises.readFile(file, 'utf8')).replace(/\r\n/g, '\n');

    const headerComment =
      `--- START OF FILE ${originalFileNameWithExt} ---\n\n` +
      `Archivo: ${relativePath}\n` +
      `Ruta: ${file}\n`;

    if (tipo === 'txt') {
      const txtContent = `${headerComment}\n${content ?? ''}\n--- END OF FILE ${originalFileNameWithExt} ---\n`;
      const outputFileName = `${safeName}.txt`;
      await fsPromises.writeFile(path.join(outDir, outputFileName), txtContent, 'utf8');
      console.log(`TXT: ${outputFileName}`);
    } else {
      const doc = new PDFDocument({ autoFirstPage: false });
      const outputFileName = `${safeName}.pdf`;
      const stream = fs.createWriteStream(path.join(outDir, outputFileName));
      doc.pipe(stream);

      doc.addPage().font('Courier').fontSize(10).text(headerComment, { continued: true });

      if (content) {
        doc.text(content, { width: 500, align: 'left' });
      }
      doc.text(`\n--- END OF FILE ${originalFileNameWithExt} ---\n`, { align: 'left' });
      doc.end();
      await new Promise(resolve => stream.on('finish', resolve));
      console.log(`PDF: ${outputFileName}`);
    }
  }
}

/**
 * Genera un único archivo combinado (PDF/TXT) con todos los contenidos.
 * @param {string} projRoot
 * @param {string} salida
 * @param {string} tipo - 'pdf' | 'txt'
 *
 * Pasos:
 *  1) Obtener lista de archivos relevantes.
 *  2) Abrir stream de salida (TXT) o doc PDF.
 *  3) Escribir por bloques: encabezado + contenido + pie.
 */
async function generarCombinado(projRoot, salida, tipo) {
  const archivos = await obtenerTodosArchivos(projRoot);

  if (tipo === 'txt') {
    const ws = fs.createWriteStream(salida, 'utf8');
    for (const file of archivos) {
      const relativePath = path.relative(projRoot, file);
      const originalFileNameWithExt = path.basename(file);
      const content = file.endsWith('.pdf')
        ? ''
        : (await fsPromises.readFile(file, 'utf8')).replace(/\r\n/g, '\n');

      ws.write(
        `--- START OF FILE ${originalFileNameWithExt} ---\n\n` +
        `Archivo: ${relativePath}\nRuta: ${file}\n\n` +
        `${content}\n` +
        `--- END OF FILE ${originalFileNameWithExt} ---\n\n`
      );
    }
    ws.end();
    await new Promise(resolve => ws.on('finish', resolve));
    console.log(`TXT combinado: ${salida}`);
  } else {
    const doc = new PDFDocument({ autoFirstPage: false });
    const stream = fs.createWriteStream(salida);
    doc.pipe(stream);

    for (const file of archivos) {
      const relativePath = path.relative(projRoot, file);
      const originalFileNameWithExt = path.basename(file);
      const content = file.endsWith('.pdf')
        ? ''
        : (await fsPromises.readFile(file, 'utf8')).replace(/\r\n/g, '\n');

      doc.addPage().font('Courier').fontSize(10)
        .text(
          `--- START OF FILE ${originalFileNameWithExt} ---\n\n` +
          `Archivo: ${relativePath}\nRuta: ${file}\n`,
          { continued: true }
        );
      if (content) {
        doc.text(content, { width: 500, align: 'left', continued: true });
      }
      doc.text(`\n--- END OF FILE ${originalFileNameWithExt} ---\n`, { align: 'left' });
    }

    doc.end();
    await new Promise(resolve => stream.on('finish', resolve));
    console.log(`PDF combinado: ${salida}`);
  }
}

// --- EJECUCIÓN PRINCIPAL ---
(async () => {
  // 1) Raíz del proyecto = carpeta padre del script
  const projRoot = path.resolve(__dirname, '..');

  // 2) Tipo de salida
  const tipo = argv.type;

  // 3) Rama individual vs combinado
  if (argv.individual) {
    await generarIndividual(projRoot, tipo);
  } else {
    const ts = formatearFechaHoraBackup();
    const filename = `flutter_backup_${ts}.${tipo}`;
    const outPath = argv.output
      ? path.join(path.resolve(process.cwd(), argv.output), filename)
      : path.resolve(__dirname, filename);

    if (argv.output) {
      await fsPromises.mkdir(path.resolve(process.cwd(), argv.output), { recursive: true });
    }
    await generarCombinado(projRoot, outPath, tipo);
  }
})();

/* --- Panel de Uso del Script de Backup --------------------------------------

Descripción
-----------
Exporta a PDF o TXT el contenido relevante del proyecto Flutter:
1) Código fuente en /lib con extensiones permitidas (por defecto: .dart, .py).
2) Archivos extra de raíz configurados (pubspec.yaml, analysis_options.yaml, etc.).
3) Configuración de Android en /android (Gradle, Manifests, ProGuard, etc.).
   * Opcional: incluir archivos sensibles como google-services.json y keystores.

Requisitos previos
------------------
1) Node.js 16+ (recomendado 18+).
2) Dependencias instaladas:
   npm i pdfkit yargs readline-sync
3) Ubicación: coloca este script en una subcarpeta del proyecto; asume raíz en `..`.

Comandos básicos
----------------
1) Backup combinado (un solo archivo):
   node flutter_backup.js --type=pdf --output ./salidas - Genera ./salidas/flutter_backup_DD_MM_YYYY_HHMMAM|PM.pdf

2) Backup combinado en TXT:
   node flutter_backup.js --type=txt --output ./salidas

3) Archivos individuales (un PDF/TXT por archivo del proyecto):
   node flutter_backup.js --individual --type=pdf --output ./salidas

4) Incluir archivos sensibles de Android (BAJO TU RESPONSABILIDAD):
   node flutter_backup.js --type=pdf --include-secrets --output ./salidas - Añade: android/app/google-services.json, android/key.properties, *.jks/*.keystore

Parámetros CLI
--------------
--type, -t            Tipo de salida: "pdf" | "txt".  (por defecto: pdf)
--individual, -i      Genera archivos individuales en lugar de un combinado. (false)
--output, -o          Carpeta de salida. Si no se especifica:
                      - modo combinado: crea el archivo junto al script
                      - modo individual: te preguntará la ruta por consola
--include-secrets, -S Incluye secretos de Android (APAGADO por defecto). Úsalo
                      solo para auditorías locales, nunca subas esos backups.

Estructura de salida
--------------------
- Combinado:  flutter_backup_DD_MM_YYYY_HHMMAM|PM.pdf|txt
- Individual: <carpeta>_backup_DD_MM_YYYY_HHMMAM|PM/
              ├─ lib_models_user.dart.pdf
              ├─ android_build.gradle.pdf
              └─ ...

Qué se incluye / excluye
------------------------
INCLUYE (por defecto):
- /lib/** con extensiones permitidas: .dart, .py
- Archivos extra fijos: pubspec.yaml, analysis_options.yaml, .gitignore,
  android/build.gradle, android/settings.gradle, android/gradle.properties,
  android/gradle/wrapper/gradle-wrapper.properties, android/app/build.gradle,
  android/app/proguard-rules.pro
- Android (lista blanca):
  * build.gradle(.kts), settings.gradle(.kts), gradle.properties
  * AndroidManifest.xml (todas las variantes: main/debug/profile/flavors)
  * proguard-rules.pro
  * gradle-wrapper.properties

EXCLUYE SIEMPRE:
- Directorios: build, .gradle, .idea, app/build, intermediates, outputs, ios, web,
  windows, linux, macos, .dart_tool, .vscode, .firebase

OPCIONAL (solo con --include-secrets):
- google-services.json, key.properties, *.jks, *.keystore

Ejemplos prácticos
------------------
1) Revisión de configuración Android sin secretos (recomendado):
   node flutter_backup.js --type=pdf --output D:\backups

2) Auditoría completa incluyendo secretos (local, no compartir):
   node flutter_backup.js --type=txt --include-secrets --output ./auditoria

3) Un PDF por archivo para comparar diffs:
   node flutter_backup.js -i -t pdf -o ./salidas

Buenas prácticas y advertencias
-------------------------------
- No subas backups con --include-secrets a repositorios ni los compartas.
- Si necesitas agregar más archivos de config (p.ej. xml/network_security_config),
  amplía la lista blanca en SAFE_NAMES/SAFE_REGEX dentro del script.
- Si tu proyecto usa Gradle con Kotlin DSL, ya se soportan *.kts.
- El script evita arrastrar artefactos pesados de build para mantener salidas pequeñas.

Solución de problemas
---------------------
- "Cannot find module 'pdfkit'": instala dependencias -> npm i pdfkit yargs readline-sync
- Salida vacía o incompleta: verifica que /lib exista y que EXTENSIONS contenga
  las extensiones de tus fuentes.
- Faltan archivos Android: confirma que no estén dentro de carpetas excluidas
  (build/intermediates/outputs) o amplía la lista blanca.
- Tiempos largos: usa --type=txt primero (más rápido) para validar cobertura.

Sugerencias críticas (mejoras)
------------------------------
- Agregar flag --ext=".dart,.py,.js" para personalizar extensiones en tiempo de ejecución.
- Exportar también /test y /tool opcionalmente con --include-tests/--include-tools.
- Soportar patrón de exclusión adicional vía --exclude="carpetaA,carpetaB".
- Emitir un índice (CSV/JSON) con hash y tamaño por archivo para trazabilidad.

--------------------------------------------------------------------------- */



// // Importación de módulos necesarios
// const fs = require('fs'); // Módulo File System base de Node.js
// const fsPromises = fs.promises; // Versión basada en Promesas del módulo File System
// const path = require('path'); // Módulo para trabajar con rutas de archivos y directorios
// const PDFDocument = require('pdfkit'); // Biblioteca para crear documentos PDF
// const yargs = require('yargs'); // Biblioteca para parsear argumentos de línea de comandos
// const readline = require('readline-sync'); // Biblioteca para entrada síncrona del usuario en la consola

// // --- CONFIGURACIÓN GLOBAL ---

// // 1. Definición de extensiones de archivo a incluir en el análisis.
// // const EXTENSIONS = ['.dart', '.js', '.py']; // Solo se procesarán archivos con estas extensiones (código fuente).
// const EXTENSIONS = ['.dart', '.py']; // Solo se procesarán archivos con estas extensiones (código fuente).

// // 2. Lista de archivos adicionales específicos que siempre se incluirán si existen.
// const EXTRA_FILES = [
//   'pubspec.yaml',
//   'pubspec.lock',
//   'analysis_options.yaml',
//   // 'README.md', // Comentado para no incluirlo por defecto
//   // 'CHANGELOG.md', // Comentado
//   '.gitignore',
//   'android/app/build.gradle',
//   // 'android/settings.gradle', // Removido temporalmente para simplificar la salida
//   // 'gradlew', // Removido temporalmente
//   // 'gradle/wrapper/gradle-wrapper.properties', // Removido temporalmente
//   // 'ios/Podfile', // Comentado
//   // 'ios/Runner.xcodeproj/project.pbxproj', // Comentado
//   // 'ios/Runner/Info.plist' // Comentado
// ];

// // 3. Configuración de los argumentos de línea de comandos usando yargs.
// const argv = yargs
//   .option('type', { // Opción para definir el tipo de salida
//     alias: 't', // Alias corto (-t)
//     choices: ['pdf', 'txt'], // Valores permitidos
//     default: 'pdf' // Valor por defecto si no se especifica
//   })
//   .option('individual', { // Opción para generar archivos individuales o uno combinado
//     alias: 'i', // Alias corto (-i)
//     type: 'boolean', // Tipo de dato esperado (verdadero/falso)
//     default: false // Valor por defecto
//   })
//   .option('output', { // Opción para especificar una ruta de salida personalizada
//     alias: 'o', // Alias corto (-o)
//     type: 'string' // Tipo de dato esperado (cadena de texto)
//   })
//   .argv; // Parsea los argumentos proporcionados

// // --- FUNCIONES AUXILIARES ---

// /**
//  Función asíncrona para obtener recursivamente archivos con extensiones específicas.
//  @param {string} dir - El directorio desde donde empezar la búsqueda.
//  @param {string[]} exts - Un array de extensiones de archivo (ej: ['.dart', '.js']).
//  @param {string[]} [archivos=[]] - Un array acumulador para los archivos encontrados (usado en la recursión).
//  @returns {Promise<string[]>} Una promesa que resuelve a un array de rutas completas de archivos.
// */
// async function obtenerArchivosPorExtensiones(dir, exts, archivos = []) {
//   // 1.1. Lee el contenido del directorio actual.
//   const items = await fsPromises.readdir(dir, { withFileTypes: true });
//   // 1.2. Itera sobre cada ítem (archivo o directorio) encontrado.
//   for (const item of items) {
//     const fullPath = path.join(dir, item.name); // Construye la ruta completa del ítem.
//     // 1.3. Si el ítem es un directorio:
//     if (item.isDirectory()) {
//       // 1.3.1. Excluye directorios específicos para evitar procesar archivos no deseados o builds.
//       if (item.name === '.dart_tool' || item.name === 'build' || item.name === '.firebase' || item.name === '.vscode' || item.name === 'ios' || item.name === 'windows' || item.name === 'web' || item.name === 'linux' || item.name === 'macos') {
//         continue; // Salta este directorio y continúa con el siguiente ítem.
//       }
//       // 1.3.2. Llama recursivamente a la función para este subdirectorio.
//       await obtenerArchivosPorExtensiones(fullPath, exts, archivos);
//     }
//     // 1.4. Si el ítem es un archivo y su extensión está en la lista de extensiones permitidas:
//     else if (item.isFile() && exts.includes(path.extname(item.name).toLowerCase())) {
//       archivos.push(fullPath); // Agrega la ruta completa del archivo a la lista.
//     }
//   }
//   return archivos; // Devuelve la lista acumulada de archivos.
// }

// // 1. Caché para almacenar la lista de archivos y evitar escaneos repetidos.
// let archivosCache;

// /**
//  Función asíncrona para obtener todos los archivos relevantes del proyecto (código y extras).
//  Utiliza una caché para mejorar el rendimiento en ejecuciones subsecuentes.
//  @param {string} projRoot - La ruta raíz del proyecto.
//  @returns {Promise<string[]>} Una promesa que resuelve a un array de rutas completas de archivos.
// */
// async function obtenerTodosArchivos(projRoot) {
//   // 2.1. Si la caché ya tiene datos, los devuelve directamente.
//   if (!archivosCache) {
//     // 2.2. Obtiene los archivos de código fuente del directorio 'lib'.
//     const archivosCodigo = await obtenerArchivosPorExtensiones(path.join(projRoot, 'lib'), EXTENSIONS);
//     const archivosExtra = [];
//     // 2.3. Itera sobre la lista EXTRA_FILES para agregar archivos específicos.
//     for (const rel of EXTRA_FILES) {
//       const full = path.join(projRoot, rel); // Construye la ruta completa del archivo extra.
//       try {
//         await fsPromises.access(full); // Verifica si el archivo existe y es accesible.
//         const stat = await fsPromises.stat(full); // Obtiene estadísticas del archivo.
//         if (stat.isFile()) { // Se asegura de que es un archivo y no un directorio.
//           archivosExtra.push(full);
//         }
//       } catch (e) {
//         // console.warn(`Advertencia: No se pudo acceder al archivo extra ${full}: ${e.message}`);
//       }
//     }
//     // 2.4. Combina los archivos de código y los archivos extra, y los guarda en la caché.
//     archivosCache = archivosCodigo.concat(archivosExtra);
//   }
//   return archivosCache; // Devuelve la lista de archivos (desde la caché o recién generada).
// }

// /**
//  Formatea la fecha y hora actual para usarla en nombres de archivo de backup.
//  @returns {string} Una cadena con el formato "dd_mm_yyyy_hhMMampm".
// */
// function formatearFechaHoraBackup() {
//   const now = new Date();
//   const dd = String(now.getDate()).padStart(2, '0');
//   const mm = String(now.getMonth() + 1).padStart(2, '0'); // Meses son 0-indexados
//   const yyyy = now.getFullYear();
//   let h = now.getHours();
//   const m = now.getMinutes();
//   const ampm = h >= 12 ? 'PM' : 'AM';
//   h = h % 12 || 12; // Convierte la hora a formato 12h (0h se convierte a 12 AM)
//   const mStr = String(m).padStart(2, '0');
//   return `${dd}_${mm}_${yyyy}_${h}${mStr}${ampm}`;
// }

// // --- FUNCIONES PRINCIPALES DE GENERACIÓN ---

// /**
//  Genera archivos de salida individuales (PDF o TXT) para cada archivo del proyecto.
//  Modificación: Ahora el nombre del documento exportado incluye la ruta completa del archivo 
//  (convertida a un nombre válido reemplazando '/' o '\' por '_').
//  @param {string} projRoot - La ruta raíz del proyecto.
//  @param {string} tipo - El tipo de salida ('pdf' o 'txt').
// */
// // ... (resto de importaciones y funciones auxiliares como antes)

// async function generarIndividual(projRoot, tipo) {
//   // 1.1. Determina la ruta base para la carpeta de salida.
//   const base = argv.output
//     ? path.resolve(process.cwd(), argv.output)
//     : readline.questionPath('Ruta base para carpeta de salida: ', {
//       isDirectory: true,
//       create: true,
//       exists: null,
//     });
//   // 1.2. Pregunta al usuario por el nombre de la carpeta de backup.
//   const name = readline.question('Nombre de carpeta (sin espacios): ', {
//     limit: /^[a-zA-Z0-9_.-]+$/,
//     limitMessage: 'Nombre de carpeta inválido. Use solo letras, números, guiones bajos, puntos o guiones.'
//   }).replace(/\s+/g, '_');

//   // 1.3. Construye la ruta completa del directorio de salida, incluyendo un timestamp.
//   const outDir = path.resolve(base, `${name}_backup_${formatearFechaHoraBackup()}`);
//   await fsPromises.mkdir(outDir, { recursive: true });

//   // 1.5. Obtiene la lista de todos los archivos a procesar.
//   const archivos = await obtenerTodosArchivos(projRoot);
//   // 1.6. Itera sobre cada archivo del proyecto.
//   for (const file of archivos) {
//     const relativePath = path.relative(projRoot, file); // Ruta relativa (sin "D:\\proyectos\\classroomadmin\\" delante)
//     const originalFileNameWithExt = path.basename(file);

//     // --- CHANGE: usar relativePath para generar el nombre final sin prefijo ---
//     // Ahora safeName se basa en relativePath, de modo que
//     // no incluirá "D:_proyectos_classroomadmin_".
//     const safeName = relativePath.replace(/[\/\\]/g, '_');
//     // Por ejemplo, si relativePath === "lib\\models\\user.dart",
//     // entonces safeName === "lib_models_user.dart".
//     // --- END CHANGE ---

//     const content = file.endsWith('.pdf')
//       ? null
//       : (await fsPromises.readFile(file, 'utf8')).replace(/\r\n/g, '\n');

//     const headerComment =
//       `--- START OF FILE ${originalFileNameWithExt} ---\n\n` +
//       `Archivo: ${relativePath}\n` +
//       `Ruta: ${file}\n`;

//     if (tipo === 'txt') {
//       const txtContent = `${headerComment}\n${content}\n--- END OF FILE ${originalFileNameWithExt} ---\n`;
//       const outputFileName = `${safeName}.txt`;
//       await fsPromises.writeFile(path.join(outDir, outputFileName), txtContent, 'utf8');
//       console.log(`TXT: ${outputFileName}`);
//     } else { // PDF
//       const doc = new PDFDocument({ autoFirstPage: false });
//       const outputFileName = `${safeName}.pdf`;
//       const stream = fs.createWriteStream(path.join(outDir, outputFileName));
//       doc.pipe(stream);

//       doc.addPage().font('Courier').fontSize(10)
//         .text(headerComment, { continued: true });

//       if (content) {
//         doc.text(content, { width: 500, align: 'left' });
//       }
//       doc.text(`\n--- END OF FILE ${originalFileNameWithExt} ---\n`, { align: 'left' });
//       doc.end();
//       await new Promise(resolve => stream.on('finish', resolve));
//       console.log(`PDF: ${outputFileName}`);
//     }
//   }
// }

// /**
//  Genera un único archivo combinado (PDF o TXT) con el contenido de todos los archivos del proyecto.
//  Modificación: Ahora incluye la "ruta completa" en el nombre de cada bloque dentro del combinado.
//  @param {string} projRoot - La ruta raíz del proyecto.
//  @param {string} salida  - La ruta completa del archivo de salida.
//  @param {string} tipo    - El tipo de salida ('pdf' o 'txt').
// */
// async function generarCombinado(projRoot, salida, tipo) {
//   // 2.1. Obtiene la lista de todos los archivos a procesar.
//   const archivos = await obtenerTodosArchivos(projRoot);
//   // 2.2. Genera el archivo de salida según el tipo especificado.
//   if (tipo === 'txt') {
//     // 2.2.1. Si el tipo es TXT:
//     const ws = fs.createWriteStream(salida, 'utf8'); // Crea un stream de escritura.
//     for (const file of archivos) {
//       const relativePath = path.relative(projRoot, file);
//       const originalFileNameWithExt = path.basename(file);
//       // --- NUEVO CÓDIGO: generar un safeName para cada bloque (usualmente no cambia el "combined",
//       //    pero si se quisiera diferenciar dentro del mismo txt, ya se está poniendo la ruta en el contenido) ---
//       // const safeName = file.replace(/[\/\\]/g, '_');
//       const content = file.endsWith('.pdf')
//         ? '' // No incluye contenido de PDFs.
//         : (await fsPromises.readFile(file, 'utf8')).replace(/\r\n/g, '\n');
//       // Escribe el encabezado, contenido y pie de página para cada archivo en el stream.
//       ws.write(`--- START OF FILE ${originalFileNameWithExt} ---\n\nArchivo: ${relativePath}\nRuta: ${file}\n\n${content}\n--- END OF FILE ${originalFileNameWithExt} ---\n\n`);
//     }
//     ws.end(); // Cierra el stream.
//     await new Promise(resolve => ws.on('finish', resolve)); // Espera a que el stream termine.
//     console.log(`TXT combinado: ${salida}`);
//   } else { // PDF
//     // 2.2.2. Si el tipo es PDF:
//     const doc = new PDFDocument({ autoFirstPage: false });
//     const stream = fs.createWriteStream(salida);
//     doc.pipe(stream);
//     for (const file of archivos) {
//       const relativePath = path.relative(projRoot, file);
//       const originalFileNameWithExt = path.basename(file);
//       const content = file.endsWith('.pdf')
//         ? ''
//         : (await fsPromises.readFile(file, 'utf8')).replace(/\r\n/g, '\n');
//       // Añade una nueva página para cada archivo y escribe su encabezado, contenido y pie de página.
//       doc.addPage().font('Courier').fontSize(10)
//         .text(`--- START OF FILE ${originalFileNameWithExt} ---\n\nArchivo: ${relativePath}\nRuta: ${file}\n`, { continued: true });
//       if (content) {
//         doc.text(content, { width: 500, align: 'left', continued: true });
//       }
//       doc.text(`\n--- END OF FILE ${originalFileNameWithExt} ---\n`, { align: 'left' });
//     }
//     doc.end();
//     await new Promise(resolve => stream.on('finish', resolve));
//     console.log(`PDF combinado: ${salida}`);
//   }
// }

// // --- EJECUCIÓN PRINCIPAL DEL SCRIPT (IIFE - Immediately Invoked Function Expression) ---
// (async () => {
//   // 1. Determina la ruta raíz del proyecto (asume que el script está en una subcarpeta).
//   const projRoot = path.resolve(__dirname, '..');
//   // 2. Obtiene el tipo de salida de los argumentos de línea de comandos.
//   const tipo = argv.type;
//   // 3. Verifica si se deben generar archivos individuales o uno combinado.
//   if (argv.individual) {
//     // 3.1. Si es individual, llama a la función correspondiente.
//     await generarIndividual(projRoot, tipo);
//   } else {
//     // 3.2. Si es combinado:
//     const ts = formatearFechaHoraBackup(); // Genera un timestamp para el nombre del archivo.
//     const filename = `flutter_backup_${ts}.${tipo}`; // Crea el nombre del archivo.
//     // Determina la ruta de salida.
//     const outPath = argv.output
//       ? path.join(path.resolve(process.cwd(), argv.output), filename)
//       : path.resolve(__dirname, filename); // Por defecto, en la misma carpeta del script.

//     // Crea el directorio de salida si se especificó con -o y no existe.
//     if (argv.output) {
//       await fsPromises.mkdir(path.resolve(process.cwd(), argv.output), { recursive: true });
//     }
//     // Llama a la función para generar el archivo combinado.
//     await generarCombinado(projRoot, outPath, tipo);
//   }
// })();

// /* --- Panel de Uso del Script de Backup ---

// Este script de Node.js está diseñado para crear copias de seguridad del código fuente y archivos de configuración importantes de un proyecto Flutter. Puede generar archivos individuales para cada archivo del proyecto o un único archivo combinado, tanto en formato TXT como PDF.

// ### Propósito

// Facilitar la creación de "snapshots" del estado actual de los archivos relevantes de un proyecto Flutter, útil para compartir, archivar o como parte de un proceso de revisión de código.

// ### Prerrequisitos

// 1.  **Node.js:** Asegúrate de tener Node.js instalado en tu sistema. Puedes descargarlo desde [nodejs.org](https://nodejs.org/).
// 2.  **Dependencias NPM:** Navega a la carpeta donde reside este script en tu terminal y ejecuta:
//     ```bash
//     npm install pdfkit yargs readline-sync
//     ```

// ### Cómo Ejecutar el Script

// 1.  Guarda el código anterior en un archivo, por ejemplo, `flutter_backup.js`.
// 2.  Abre tu terminal o línea de comandos.
// 3.  Navega hasta el directorio donde guardaste `flutter_backup.js`.
// 4.  Ejecuta el script usando Node.js:
//     ```bash
//     node flutter_backup.js [opciones]
//     ```

// ### Opciones de Línea de Comandos

// El script acepta las siguientes opciones:

// *   `--type <formato>` o `-t <formato>`
//     *   Especifica el formato de salida.
//     *   Valores posibles: `pdf` o `txt`.
//     *   Valor por defecto: `pdf`.
//     *   Ejemplo: `node flutter_backup.js -t txt`

// *   `--individual` o `-i`
//     *   Si se incluye esta opción, el script generará un archivo de salida individual para cada archivo del proyecto.
//     *   Si se omite, generará un único archivo combinado.
//     *   Valor por defecto: `false` (combinado).
//     *   Ejemplo: `node flutter_backup.js -i`

// *   `--output <ruta_directorio>` o `-o <ruta_directorio>`
//     *   Especifica el directorio donde se guardarán los archivos de salida.
//     *   Si se usa con `--individual`, se creará una subcarpeta con timestamp dentro de esta ruta.
//     *   Si se usa sin `--individual`, el archivo combinado se guardará directamente en esta ruta.
//     *   Si se omite, el comportamiento es el siguiente:
//         *   Con `--individual`: Preguntará interactivamente por la ruta base y el nombre de la carpeta.
//         *   Sin `--individual`: El archivo combinado se guardará en la misma carpeta donde se encuentra el script.
//     *   Ejemplo: `node flutter_backup.js -o ./mis_backups`

// ### Salida Generada

// *   **Modo Combinado (por defecto):**
//     *   Se creará un único archivo llamado `flutter_backup_DD_MM_YYYY_HHMMAMPM.[pdf|txt]` (donde `DD_MM_YYYY_HHMMAMPM` es la fecha y hora actual).
//     *   Este archivo contendrá el contenido de todos los archivos procesados, cada uno delimitado por:
//         ```
//         --- START OF FILE nombre_original.ext ---

//         Archivo: ruta/relativa/al/archivo.ext
//         Ruta: ruta/completa/al/archivo.ext

//         [CONTENIDO DEL ARCHIVO]

//         --- END OF FILE nombre_original.ext ---
//         ```

// *   **Modo Individual (`-i`):**
//     *   Se creará una carpeta con el nombre que especifiques (o que el script solicite), seguido de `_backup_` y un timestamp. Ejemplo: `mi_proyecto_backup_01_05_2024_1030AM`.
//     *   Dentro de esta carpeta, cada archivo del proyecto tendrá su propio archivo de salida (`.txt` o `.pdf`), manteniendo el nombre original del archivo pero cambiando la extensión.
//     *   Cada archivo individual también contendrá el mismo formato de encabezado y pie de página que en el modo combinado.

// ### Archivos Incluidos

// *   **Archivos de Código:** Todos los archivos con las extensiones `.dart`, `.js`, `.py` dentro del directorio `lib/` del proyecto.
// *   **Archivos Extra:** Los siguientes archivos específicos de la raíz del proyecto (si existen):
//     *   `pubspec.yaml`
//     *   `pubspec.lock`
//     *   `analysis_options.yaml`
//     *   `.gitignore`
//     *   `android/app/build.gradle`

// ### Exclusiones

// El script excluye automáticamente los siguientes directorios al buscar archivos de código:

// *   `.dart_tool`
// *   `build`
// *   `.firebase`
// *   `.vscode`
// *   `ios`
// *   `windows`
// *   `web`
// *   `linux`
// *   `macos`

// ### Ejemplos de Uso

// *   **Generar un PDF combinado en la carpeta del script:**
//     ```bash
//     node flutter_backup.js
//     ```
// *   **Generar un TXT combinado en la carpeta del script:**
//     ```bash
//     node flutter_backup.js -t txt
//     ```
// *   **Generar archivos PDF individuales (el script preguntará la ruta y nombre de la carpeta):**
//     ```bash
//     node flutter_backup.js -i
//     ```
// *   **Generar archivos TXT individuales en una carpeta específica llamada "backups_txt" dentro de "documentos_proyecto":**
//     ```bash
//     node flutter_backup.js -t txt -i -o ./documentos_proyecto
//     # Luego, cuando pregunte "Nombre de carpeta:", puedes escribir "backups_txt"
//     ```
// *   **Generar un PDF combinado en el directorio `./output_files`:**
//     ```bash
//     node flutter_backup.js -o ./output_files
//     ```
// */