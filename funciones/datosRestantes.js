const fs = require('node:fs/promises');
const { parse } = require('csv-parse');

const originalJsonFile = 'datos.json'; // Reemplaza con el nombre de tu archivo JSON original
const trainingCsvFile = 'datosEntrenamiento.csv';
const outputJsonFile = 'datosRestantes.json';

// Lista de campos JSON relevantes (Tabla #1) - DEBE SER LA MISMA QUE EN generate_data.js
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

async function processData() {
    try {
        const rawOriginalData = await fs.readFile(originalJsonFile, 'utf-8');
        const originalJsonData = JSON.parse(rawOriginalData);

        const trainingCsvData = await fs.readFile(trainingCsvFile, 'utf-8');
        const trainingRecords = await new Promise((resolve, reject) => {
            parse(trainingCsvData, {
                columns: true,
                skip_empty_lines: true
            }, (err, records) => {
                if (err) {
                    reject(err);
                } else {
                    resolve(records);
                }
            });
        });

        // Extrae los text_input JSONs del CSV y parsealos a objetos
        const trainingInputTexts = trainingRecords.map(record => JSON.parse(record.text_input));

        const remainingData = originalJsonData.filter(originalRecord => {
            let originalTextInput = {};
            relevantFields.forEach(field => {
                if (originalRecord.hasOwnProperty(field)) {
                    const value = originalRecord[field];
                    if (value !== '  -   -' && value !== 'SIN INFORMACION' && value !== 'NA' && value !== '') {
                        originalTextInput[field] = value;
                    }
                }
            });

            // Busca si un text_input del CSV coincide con el text_input del registro original
            return !trainingInputTexts.some(csvTextInput => {
                return Object.keys(csvTextInput).every(key => csvTextInput[key] == originalTextInput[key]);
            });
        });

        const muerteUnoRestantes = remainingData.filter(record => record.con_fin_muerte === 1);
        const muerteCeroRestantes = remainingData.filter(record => record.con_fin_muerte === 0);

        const outputTrainingData = [
            ...muerteUnoRestantes.map(record => {
                let textInput = {};
                relevantFields.forEach(field => {
                    if (record.hasOwnProperty(field)) {
                        const value = record[field];
                        if (value !== '  -   -' && value !== 'SIN INFORMACION' && value !== 'NA' && value !== '') {
                            textInput[field] = value;
                        }
                    }
                });
                return {
                    text_input: JSON.stringify(textInput),
                    output: JSON.stringify({ con_fin_muerte: record.con_fin_muerte })
                };
            }),
            ...muerteCeroRestantes.map(record => {
                let textInput = {};
                relevantFields.forEach(field => {
                    if (record.hasOwnProperty(field)) {
                        const value = record[field];
                        if (value !== '  -   -' && value !== 'SIN INFORMACION' && value !== 'NA' && value !== '') {
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

        const outputJsonString = JSON.stringify(outputTrainingData, null, 2); // Indentado para legibilidad
        await fs.writeFile(outputJsonFile, outputJsonString);

        console.log(`Archivo JSON "${outputJsonFile}" creado con éxito con los datos restantes.`);

    } catch (error) {
        console.error('Error al procesar los datos:', error);
    }
}

processData();