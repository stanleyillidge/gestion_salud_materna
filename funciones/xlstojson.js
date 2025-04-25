// Asegúrate de instalar la dependencia: npm install xlsx
const XLSX = require('xlsx');
const fs = require('fs');
const path = require('path');

function convertirExcelAJson(rutaExcel) {
  try {
    // Lee el archivo Excel
    const workbook = XLSX.readFile(rutaExcel);
    // Selecciona la primera hoja del libro
    const nombreHoja = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[nombreHoja];
    // Convierte la hoja a JSON
    const jsonData = XLSX.utils.sheet_to_json(worksheet, { defval: null });

    // Construye el nombre y ruta del archivo JSON en la misma ubicación que este script
    const nombreArchivo = path.basename(rutaExcel, path.extname(rutaExcel)) + '.json';
    const rutaSalida = path.join(__dirname, nombreArchivo);

    // Escribe el archivo JSON
    fs.writeFileSync(rutaSalida, JSON.stringify(jsonData, null, 2));
    console.log(`Archivo JSON generado en: ${rutaSalida}`);
  } catch (error) {
    console.error('Error al convertir el Excel a JSON:', error);
  }
}

// Ejemplo de uso:
const filePath = 'D:/proyectos/salud_materna/funciones/datos.xlsx';

// Ejemplo de uso
convertirExcelAJson(filePath);

const relevantFields = [
    "edad_",
    "num_gestac",
    "num_aborto",
    "num_muerto",
    "endoc_meta",
    "card_cereb",
    "renales",
    "otras_enfe",
    "preclampsi",
    "hemorragia_obst_severa",
    "hem_mas_sever_MM",
    "area_",
    "tip_ss_",
    "no_con_pre",
    "sem_c_pren",
    "cod_mun_r",
    "cod_pre",
    "estrato_",
    "eclampsia",
    "dias_hospi",
    "term_gesta",
    "moc_rel_tg",
    "tip_cas_",
    "num_cesare",
    "caus_princ",
    "rupt_uteri",
    "peso_rnacx"
];