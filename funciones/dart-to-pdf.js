const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const yargs = require('yargs');

// Parsear opciones de línea de comandos
const argv = yargs
  .option('type', {
    alias: 't',
    describe: 'Tipo de salida: pdf o txt',
    choices: ['pdf', 'txt'],
    default: 'pdf'
  })
  .option('individual', {
    alias: 'i',
    type: 'boolean',
    describe: 'Generar archivos individuales para cada .dart',
    default: false
  })
  .option('output', {
    alias: 'o',
    type: 'string',
    describe: 'Ruta de salida: archivo (para combinado) o carpeta (para individual)'
  })
  .argv;

// Función recursiva para obtener todos los archivos .dart en un directorio
function obtenerArchivosDart(dir, archivos = []) {
  const items = fs.readdirSync(dir, { withFileTypes: true });
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      obtenerArchivosDart(fullPath, archivos);
    } else if (item.isFile() && path.extname(item.name).toLowerCase() === '.dart') {
      archivos.push(fullPath);
    }
  }
  return archivos;
}

// Formatea fecha y hora en español para usar en el nombre de archivos
function formatearFechaHora() {
  const now = new Date();
  const dias = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
  const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
  const diaSemana = dias[now.getDay()];
  const dia = now.getDate();
  const mes = meses[now.getMonth()];
  const año = now.getFullYear();
  let hora = now.getHours();
  const minutos = now.getMinutes();
  const ampm = hora >= 12 ? 'PM' : 'AM';
  hora = hora % 12 || 12;
  const minStr = minutos < 10 ? `0${minutos}` : minutos;
  return `${diaSemana}_${dia}_${mes}_${año}_${hora}h${minStr}m${ampm}`;
}

// Genera un archivo combinado (PDF o TXT)
function generarCombinado(rutaLib, rutaSalida, tipo) {
  const archivos = obtenerArchivosDart(rutaLib);

  if (tipo === 'txt') {
    const writeStream = fs.createWriteStream(rutaSalida, 'utf8');
    archivos.forEach(archivo => {
      let contenido = fs.readFileSync(archivo, 'utf8').replace(/\r\n/g, '\n');
      writeStream.write(`Archivo: ${path.relative(rutaLib, archivo)}\n`);
      writeStream.write(contenido + '\n\n');
    });
    writeStream.end();
    writeStream.on('finish', () => console.log(`TXT combinado generado en: ${rutaSalida}`));
  } else {
    const doc = new PDFDocument({ autoFirstPage: false });
    const stream = fs.createWriteStream(rutaSalida);
    doc.pipe(stream);
    archivos.forEach(archivo => {
      let contenido = fs.readFileSync(archivo, 'utf8').replace(/\r\n/g, '\n');
      doc.addPage();
      doc.font('Courier').fontSize(10).text(`Archivo: ${path.relative(rutaLib, archivo)}`);
      doc.moveDown();
      doc.text(contenido, { width: 450, align: 'left' });
    });
    doc.end();
    stream.on('finish', () => console.log(`PDF combinado generado en: ${rutaSalida}`));
  }
}

// Genera archivos individuales (PDF o TXT)
function generarIndividual(rutaLib, carpetaSalida, tipo) {
  const archivos = obtenerArchivosDart(rutaLib);
  archivos.forEach(archivo => {
    const relativo = path.relative(rutaLib, archivo).replace(/[\\/]/g, '_');
    const contenido = fs.readFileSync(archivo, 'utf8').replace(/\r\n/g, '\n');
    if (tipo === 'txt') {
      const nombre = `${relativo}.txt`;
      const data = `Archivo: ${relativo}\nRuta: ${archivo}\n\n${contenido}`;
      fs.writeFileSync(path.join(carpetaSalida, nombre), data, 'utf8');
      console.log(`TXT generado: ${nombre}`);
    } else {
      const nombre = `${relativo}.pdf`;
      const doc = new PDFDocument({ autoFirstPage: false });
      const stream = fs.createWriteStream(path.join(carpetaSalida, nombre));
      doc.pipe(stream);
      doc.addPage();
      doc.font('Courier').fontSize(10).text(`Archivo: ${relativo}`);
      doc.moveDown();
      doc.text(`Ruta: ${archivo}`);
      doc.moveDown();
      doc.text(contenido, { width: 450, align: 'left' });
      doc.end();
      stream.on('finish', () => console.log(`PDF generado: ${nombre}`));
    }
  });
}

// Configuración de rutas
// en la ruta predeterminada si no se pasa --output
// de lo contrario usar la ruta proporcionada
const rutaLib = path.resolve(__dirname, '../lib');
const timestamp = formatearFechaHora();
const tipoSalida = argv.type;

if (argv.individual) {
  const carpetaBase = argv.output
    ? path.resolve(process.cwd(), argv.output)
    : path.resolve(__dirname, `salida_individual_${tipoSalida}_${timestamp}`);
  fs.mkdirSync(carpetaBase, { recursive: true });
  generarIndividual(rutaLib, carpetaBase, tipoSalida);
} else {
  const ext = tipoSalida;
  const nombreDefault = `todos_los_dart_${timestamp}.${ext}`;
  const rutaSalida = argv.output
    ? path.resolve(process.cwd(), argv.output)
    : path.resolve(__dirname, nombreDefault);
  generarCombinado(rutaLib, rutaSalida, tipoSalida);
}

// Instrucciones:
// 1. Instala dependencias:
//    npm install pdfkit yargs
// 2. Coloca este archivo en D:\proyectos\salud_materna\funciones
// 3. Ejecuta:
//    node dart-to-pdf.js                        # PDF combinado en carpeta del script
//    node dart-to-pdf.js -o ./salida           # combinado en ./salida
//    node dart-to-pdf.js -t txt -o out.txt      # TXT combinado en out.txt
//    node dart-to-pdf.js -t pdf -i              # PDFs individuales
//    node dart-to-pdf.js -i -o ./docs           # individuales en ./docs
//    node dart-to-pdf.js -t txt -i -o ./txts    # TXTs individuales en ./txts



/* const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const yargs = require('yargs');

// Parsear opciones de línea de comandos
const argv = yargs
  .option('type', {
    alias: 't',
    describe: 'Tipo de salida: pdf o txt',
    choices: ['pdf', 'txt'],
    default: 'pdf'
  })
  .option('individual', {
    alias: 'i',
    type: 'boolean',
    describe: 'Generar archivos individuales para cada .dart',
    default: false
  })
  .argv;

// Función recursiva para obtener todos los archivos .dart en un directorio
function obtenerArchivosDart(dir, archivos = []) {
  const items = fs.readdirSync(dir, { withFileTypes: true });
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      obtenerArchivosDart(fullPath, archivos);
    } else if (item.isFile() && path.extname(item.name).toLowerCase() === '.dart') {
      archivos.push(fullPath);
    }
  }
  return archivos;
}

// Formatea fecha y hora en español para usar en el nombre de archivos
function formatearFechaHora() {
  const now = new Date();
  const dias = ['domingo', 'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado'];
  const meses = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio', 'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];
  const diaSemana = dias[now.getDay()];
  const dia = now.getDate();
  const mes = meses[now.getMonth()];
  const año = now.getFullYear();
  let hora = now.getHours();
  const minutos = now.getMinutes();
  const ampm = hora >= 12 ? 'PM' : 'AM';
  hora = hora % 12 || 12;
  const minStr = minutos < 10 ? `0${minutos}` : minutos;
  return `${diaSemana}_${dia}_${mes}_${año}_${hora}h${minStr}m${ampm}`;
}

// Genera un archivo combinado (PDF o TXT) con todo el contenido
function generarCombinado(rutaLib, rutaSalida, tipo) {
  const archivos = obtenerArchivosDart(rutaLib);

  if (tipo === 'txt') {
    const writeStream = fs.createWriteStream(rutaSalida, 'utf8');
    archivos.forEach(archivo => {
      let contenido = fs.readFileSync(archivo, 'utf8').replace(/\r\n/g, '\n');
      writeStream.write(`Archivo: ${path.relative(rutaLib, archivo)}\n`);
      writeStream.write(contenido + '\n\n');
    });
    writeStream.end();
    writeStream.on('finish', () => {
      console.log(`TXT combinado generado en: ${rutaSalida}`);
    });
  } else {
    const doc = new PDFDocument({ autoFirstPage: false });
    const stream = fs.createWriteStream(rutaSalida);
    doc.pipe(stream);
    archivos.forEach(archivo => {
      let contenido = fs.readFileSync(archivo, 'utf8').replace(/\r\n/g, '\n');
      doc.addPage();
      doc.font('Courier').fontSize(10).text(`Archivo: ${path.relative(rutaLib, archivo)}`);
      doc.moveDown();
      doc.text(contenido, { width: 450, align: 'left' });
    });
    doc.end();
    stream.on('finish', () => {
      console.log(`PDF combinado generado en: ${rutaSalida}`);
    });
  }
}

// Genera archivos individuales (PDF o TXT) en una carpeta de salida
function generarIndividual(rutaLib, carpetaSalida, tipo) {
  const archivos = obtenerArchivosDart(rutaLib);
  archivos.forEach(archivo => {
    const relativo = path.relative(rutaLib, archivo).replace(/[\\/]/g, '_');
    let nombreBase = `${relativo}`;
    const contenido = fs.readFileSync(archivo, 'utf8').replace(/\r\n/g, '\n');

    if (tipo === 'txt') {
      const nombre = `${nombreBase}.txt`;
      const data = `Archivo: ${relativo}\nRuta: ${archivo}\n\n${contenido}`;
      fs.writeFileSync(path.join(carpetaSalida, nombre), data, 'utf8');
      console.log(`TXT generado: ${nombre}`);
    } else {
      const nombre = `${nombreBase}.pdf`;
      const doc = new PDFDocument({ autoFirstPage: false });
      const stream = fs.createWriteStream(path.join(carpetaSalida, nombre));
      doc.pipe(stream);
      doc.addPage();
      doc.font('Courier').fontSize(10).text(`Archivo: ${relativo}`);
      doc.moveDown();
      doc.text(`Ruta: ${archivo}`);
      doc.moveDown();
      doc.text(contenido, { width: 450, align: 'left' });
      doc.end();
      stream.on('finish', () => {
        console.log(`PDF generado: ${nombre}`);
      });
    }
  });
}

// Configuración de rutas
const rutaLib = path.resolve(__dirname, '../lib');
const timestamp = formatearFechaHora();
const tipoSalida = argv.type;

if (argv.individual) {
  const carpeta = `salida_individual_${tipoSalida}_${timestamp}`;
  const rutaCarpeta = path.resolve(__dirname, carpeta);
  fs.mkdirSync(rutaCarpeta, { recursive: true });
  generarIndividual(rutaLib, rutaCarpeta, tipoSalida);
} else {
  const ext = tipoSalida;
  const nombreArchivo = `todos_los_dart_${timestamp}.${ext}`;
  const rutaSalida = path.resolve(__dirname, nombreArchivo);
  generarCombinado(rutaLib, rutaSalida, tipoSalida);
}

// Instrucciones:
// 1. Instala dependencias:
//    npm install pdfkit yargs
// 2. Coloca este archivo en D:\proyectos\salud_materna\funciones
// 3. Ejecuta:
//    node convertirDartAPDF.js --type pdf      # combinado PDF (por defecto)
//    node convertirDartAPDF.js --type txt      # combinado TXT
//    node convertirDartAPDF.js -t pdf -i       # archivos PDF individuales
//    node convertirDartAPDF.js -t txt -i       # archivos TXT individuales
 */