const fs = require('node:fs/promises');
const { createObjectCsvWriter } = require('csv-writer');

// Lista de campos JSON relevantes (Tabla #1)
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

const inputJsonFile = 'datos.json'; // Reemplaza con el nombre de tu archivo JSON
const outputCsvFile = 'datosEntrenamiento.csv';

async function generateTrainingData() {
    try {
        const rawData = await fs.readFile(inputJsonFile, 'utf-8');
        const jsonData = JSON.parse(rawData);

        const muerteCeroData = jsonData.filter(record => record.con_fin_muerte === 0);
        const muerteUnoData = jsonData.filter(record => record.con_fin_muerte === 1);

        // Función para samplear datos aleatoriamente
        const sampleData = (data, count) => {
            const shuffled = [...data].sort(() => 0.5 - Math.random());
            return shuffled.slice(0, count);
        };

        const sampledMuerteCeroData = sampleData(muerteCeroData, 300);
        const sampledMuerteUnoData = sampleData(muerteUnoData, 200);

        const trainingData = [
            ...sampledMuerteCeroData.map(record => {
                let textInput = {};
                relevantFields.forEach(field => {
                    if (record.hasOwnProperty(field)) { // Verifica si el campo existe en el registro
                        const value = record[field];
                        if (value !== '  -   -' && value !== 'SIN INFORMACION' && value !== 'NA' && value !== '') { // Filtra valores no deseados
                            textInput[field] = value;
                        }
                    }
                });
                return {
                    text_input: JSON.stringify(textInput),
                    output: JSON.stringify({ con_fin_muerte: record.con_fin_muerte })
                };
            }),
            ...sampledMuerteUnoData.map(record => {
                let textInput = {};
                relevantFields.forEach(field => {
                    if (record.hasOwnProperty(field)) { // Verifica si el campo existe en el registro
                        const value = record[field];
                        if (value !== '  -   -' && value !== 'SIN INFORMACION' && value !== 'NA' && value !== '') { // Filtra valores no deseados
                            textInput[field] = value;
                        }
                    }
                });
                return {
                    text_input: JSON.stringify(textInput),
                    output: JSON.stringify({ con_fin_muerte: record.con_fin_muerte })
                };
            })
        ];


        const csvWriter = createObjectCsvWriter({
            path: outputCsvFile,
            header: [
                { id: 'text_input', title: 'text_input' },
                { id: 'output', title: 'output' }
            ]
        });

        await csvWriter.writeRecords(trainingData);

        console.log(`Archivo CSV "${outputCsvFile}" creado con éxito.`);

    } catch (error) {
        console.error('Error al generar el archivo CSV:', error);
    }
}

generateTrainingData();

/* const fs = require('fs');
const path = require('path');
const { promisify } = require('util');

const writeFileAsync = promisify(fs.writeFile);

async function createTrainingDataFromJSON(jsonFilePath, relevantFields) {
    try {
        const rawData = fs.readFileSync(jsonFilePath, 'utf-8');
        const jsonData = JSON.parse(rawData);

        if (!Array.isArray(jsonData)) {
            console.error('Error: Input JSON file should contain an array of objects.');
            return;
        }

        const trainingData = [];

        for (const record of jsonData) {
            const textInputObject = {};
            for (const field of relevantFields) {
                if (record.hasOwnProperty(field)) {
                    textInputObject[field] = record[field];
                } else {
                    textInputObject[field] = null; // Or handle missing fields as needed
                }
            }

            const outputObject = {
                con_fin_muerte: record.con_fin_muerte
            };

            trainingData.push({
                text_input: JSON.stringify(textInputObject),
                output: JSON.stringify(outputObject)
            });
        }

        // Function to convert training data array to CSV string
        function convertArrayToCSV(data) {
            const header = "text_input,output\n";
            const csvRows = data.map(item => {
                const textInputCSV = JSON.stringify(item.text_input).replace(/,/g, ';'); // Escape commas in JSON strings
                const outputCSV = JSON.stringify(item.output).replace(/,/g, ';');      // Escape commas in JSON strings
                return `${textInputCSV},${outputCSV}`;
            });
            return header + csvRows.join('\n');
        }

        const chunkSize = 500;
        const numChunks = Math.ceil(trainingData.length / chunkSize);

        for (let i = 0; i < numChunks; i++) {
            const start = i * chunkSize;
            const end = Math.min((i + 1) * chunkSize, trainingData.length);
            const chunkData = trainingData.slice(start, end);
            const csvData = convertArrayToCSV(chunkData);
            const fileName = `datosEntrenamiento${i + 1}.csv`;
            const filePath = path.join(__dirname, fileName); // Save in the same directory as the script

            await writeFileAsync(filePath, csvData, 'utf-8');
            console.log(`Archivo ${fileName} creado con ${chunkData.length} registros.`);
        }

        console.log('Proceso completado. Archivos CSV de datos de entrenamiento creados.');

    } catch (error) {
        console.error('Error al procesar el archivo JSON o escribir CSV:', error);
    }
}

// Lista de campos JSON relevantes (Tabla #1) donde "Valor del JSON mme-0653" no era "Desconocido"
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

// Ruta al archivo JSON de entrada (ajusta la ruta si es necesario)
const inputJsonFilePath = path.join(__dirname, 'datos.json'); // Reemplaza 'data.json' con tu archivo JSON

createTrainingDataFromJSON(inputJsonFilePath, relevantFields); */


/* const fs = require('fs');

// Lista de campos JSON relevantes (Tabla #1)
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

// Nombre del archivo JSON de entrada (Tabla#1)
const inputJsonFile = 'datos_tabla1.json'; // Reemplaza con el nombre de tu archivo si es diferente
// Nombre del archivo JSON de salida (datosEntrenamiento.json)
const outputJsonFile = 'datosEntrenamiento.json';

try {
    // Leer el archivo JSON de entrada
    const rawData = fs.readFileSync(inputJsonFile, 'utf8');
    const jsonData = JSON.parse(rawData);

    const trainingData = [];

    // Verificar si jsonData es un array, si no lo es, convertirlo en un array
    const dataArray = Array.isArray(jsonData) ? jsonData : [jsonData];

    // Iterar sobre cada objeto en el array JSON
    dataArray.forEach(record => {
        const textInput = {};
        relevantFields.forEach(field => {
            if (record.hasOwnProperty(field)) {
                textInput[field] = record[field];
            } else {
                textInput[field] = null; // o puedes decidir omitir el campo si no existe
            }
        });

        const output = {};
        if (record.hasOwnProperty("con_fin_muerte")) {
            output["con_fin_muerte"] = record["con_fin_muerte"];
        } else {
            output["con_fin_muerte"] = null; // o puedes decidir omitir el campo si no existe
        }

        trainingData.push({
            "text_input": textInput,
            "output": output
        });
    });

    // Convertir los datos de entrenamiento a formato JSON
    const trainingDataJson = JSON.stringify(trainingData, null, 2); // El '2' es para la indentación

    // Escribir los datos de entrenamiento en el archivo JSON de salida
    fs.writeFileSync(outputJsonFile, trainingDataJson);

    console.log(`Datos de entrenamiento generados y guardados en ${outputJsonFile}`);

} catch (error) {
    console.error('Error al procesar el archivo JSON:', error);
} */