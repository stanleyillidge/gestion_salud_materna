/*
 * Función en Node.js para convertir una tabla de un archivo Excel (.xlsx)
 * en un archivo JSON.
 *
 * Requiere instalar la dependencia:
 *   npm install xlsx
 *
 * Uso:
 *   const { excelToJson } = require('./excelToJson');
 *   excelToJson('ruta/archivo.xlsx', 'ruta/salida.json');
 */

const xlsx = require('xlsx');
const fs = require('fs');

/**
 * Lee la primera hoja de un archivo Excel y la convierte a JSON.
 *
 * @param {string} inputPath - Ruta al archivo .xlsx de entrada.
 * @param {string} outputPath - Ruta al archivo .json de salida.
 */
function excelToJson(inputPath, outputPath) {
  // Leer el workbook
  const workbook = xlsx.readFile(inputPath);
  // Obtener nombre de la primera hoja
  const firstSheetName = workbook.SheetNames[0];
  // Obtener la hoja
  const sheet = workbook.Sheets[firstSheetName];
  // Convertir a arreglo de objetos
  const data = xlsx.utils.sheet_to_json(sheet, { defval: null });

  // Escribir JSON con identación de 2 espacios
  fs.writeFileSync(outputPath, JSON.stringify(data, null, 2), 'utf8');
  console.log(`Archivo JSON generado en: ${outputPath}`);
}

module.exports = { excelToJson };
excelToJson(
    'D:/proyectos/salud_materna/funciones/datos_nuevos_con_riesgo_ponderado_critico_modif.xlsx',
    'datos_nuevos_con_riesgo_ponderado_critico_modif.json'
);