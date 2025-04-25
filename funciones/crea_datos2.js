const fs = require('node:fs'); // Usaremos fs para streams
const csv = require('csv-parser');
const { createObjectCsvWriter } = require('csv-writer');
const path = require('node:path'); // Para manejar rutas de archivo

// --- Configuración ---
const inputCsvFile = 'datos_nuevos_ajustados.csv';
const outputCsvFile = 'datosEntrenamientoNuevo.csv';

// Lista de campos relevantes (Factores Críticos)
const relevantFields = [
    'MANEJO_ESPECIFICO_Ingreso_a_UCI',
    'WAOS_Rotura_uterina_durante_el_parto',
    'PAS_ESTANCIA_MIN',
    'PAD_ESTANCIA_MIN',
    'F_CARDIACA_ESTANCIA_MIN', // Incluida una vez, csv-parser usualmente toma la última con ese nombre
    'F_RESPIRATORIA_INGRESO_ALTA',
    'SaO2_ESTANCIA_MAX',
    'CONSCIENCIA_INGRESO',
    'CREATININA_ESTANCIA_MAX',
    'GOT_Aspartato_aminotransferasa_max',
    'GPT_INGRESO',
    'Recuento_de_plaquetas_-_PLT___min',
    'UNIDADES_TRANSFUNDIDAS',
];

// Array para almacenar los datos transformados
const trainingData = [];

// --- Lógica de Lectura y Transformación ---

const readStream = fs.createReadStream(path.resolve(__dirname, inputCsvFile), { encoding: 'utf-8' })
    .on('error', (err) => {
        console.error(`Error al leer el archivo CSV de entrada: ${err.message}`);
        process.exit(1); // Salir si no se puede leer el archivo
    });

readStream.pipe(csv())
    .on('data', (row) => {
        try {
            // 1. Crear objeto para text_input con campos relevantes
            const textInputData = {};
            relevantFields.forEach(field => {
                // Verificar que el campo exista en la fila y no sea un valor vacío o placeholder común
                if (row.hasOwnProperty(field)) {
                    const value = row[field];
                    if (value !== null && value !== undefined && value !== '' && value.trim() !== '' && value !== 'NA' && value !== '  -   -') {
                        textInputData[field] = value;
                    }
                    // Opcional: Podrías añadir aquí lógica para convertir '1'/'0' a true/false si tu modelo lo prefiere
                    // O convertir números con comas a puntos: value.replace(',', '.')
                }
            });

            // 2. Crear objeto para output
            const outputData = {};
            const categoriaRiesgo = row['CATEGORIA_RIESGO']; // Obtener la categoría de riesgo
            if (categoriaRiesgo !== null && categoriaRiesgo !== undefined && categoriaRiesgo.trim() !== '') {
                 outputData['CATEGORIA_RIESGO'] = categoriaRiesgo;
            } else {
                // Decide qué hacer si falta la categoría de riesgo (omitir, poner un default?)
                // Por ahora, omitiremos la fila si falta la categoría de riesgo
                console.warn(`Fila con ID ${row.ID || 'desconocido'} omitida por falta de CATEGORIA_RIESGO.`);
                return; // Salta esta fila
            }


            // 3. Convertir a JSON string y añadir al array
            trainingData.push({
                text_input: JSON.stringify(textInputData),
                output: JSON.stringify(outputData)
            });
        } catch (parseError) {
             console.error(`Error procesando fila (ID: ${row.ID || 'desconocido'}): ${parseError.message}`);
             // Puedes decidir si continuar o detener el proceso aquí
        }
    })
    .on('end', async () => {
        console.log('Lectura del CSV de entrada completada.');

        if (trainingData.length === 0) {
            console.log('No se generaron datos de entrenamiento. Verifica el archivo de entrada y los filtros.');
            return;
        }

        // --- Escritura del Nuevo CSV ---
        const csvWriter = createObjectCsvWriter({
            path: path.resolve(__dirname, outputCsvFile),
            header: [
                { id: 'text_input', title: 'text_input' },
                { id: 'output', title: 'output' }
            ]
        });

        try {
            await csvWriter.writeRecords(trainingData);
            console.log(`Archivo CSV "${outputCsvFile}" creado con éxito con ${trainingData.length} registros.`);
        } catch (writeError) {
            console.error(`Error al escribir el archivo CSV de salida: ${writeError.message}`);
        }
    })
    .on('error', (err) => {
         console.error(`Error durante el parseo del CSV: ${err.message}`);
    });