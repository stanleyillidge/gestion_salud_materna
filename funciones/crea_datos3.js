const fs = require('node:fs');
const XLSX = require('xlsx');
const path = require('node:path');

// --- Configuración ---
const inputExcelFile = 'datos_nuevos_con_riesgo_ponderado_critico.xlsx'; // Archivo generado por Python
const outputTrainingFile = 'training_data_riesgo_materno_gemini_v2.jsonl'; // Nuevo nombre para JSONL entrenamiento
const outputValidationFile = 'validation_data_riesgo_materno_gemini_v2.jsonl'; // Nuevo nombre para JSONL validación

const VALIDATION_SPLIT_RATIO = 0.2; // 20% para validación, 80% para entrenamiento
const OUTPUT_COLUMN_NAME = 'NIVEL_RIESGO_PONDERADO'; // Columna con la etiqueta final

// --- Mapeo del Checklist a Columnas y Condiciones ---
// ¡¡CRUCIAL!! Verificar que los 'column' coincidan EXACTAMENTE con el Excel y los umbrales sean correctos.
// Añade TODOS los ítems relevantes de tu checklist/propuesta aquí.
/* const alertConditions = {
    // --- Eventos/Diagnósticos Máxima Alerta ---
    'HEMORRAGIA_MAYOR': { // Necesita una definición más precisa o usar DIAG_PRINCIPAL
        column: 'DIAG_PRINCIPAL_HEMORRAGIA', // Usar diagnóstico como proxy inicial
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Hemorragia Obstétrica Mayor (Diagnóstico Principal)` // Aclarar que es basado en diagnóstico
    },
    'ECLAMPSIA_CONVULSIONES': { // Asumir que THE == 1 y consciencia alterada son proxies
        column: ['DIAG_PRINCIPAL_THE', 'CONSCIENCIA_INGRESO'],
        condition: (the, cons) => the == 1 && String(cons).toLowerCase() !== 'alerta',
        text: () => `Evento Máxima Alerta: Sospecha Eclampsia / Convulsiones (THE + No Alerta)`
    },
    'SEPSIS_SHOCK_SEPTICO': { // Difícil de determinar solo con estos datos, usar proxies
        column: ['PAS_ESTANCIA_MIN', 'PAD_ESTANCIA_MIN', 'F_CARIDIACA_ESTANCIA_MIN'], // (Usando FC Max aquí)
        condition: (pas, pad, fc) => (pas < 90 || pad < 60) && fc > 120, // Hipotensión + Taquicardia como proxy muy básico
        text: () => `Evento Máxima Alerta: Sospecha Sepsis Severa / Shock Séptico (Hipotensión + Taquicardia)`
    },
    'ROTURA_UTERINA': {
        column: 'WAOS_Rotura_uterina_durante_el_parto',
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Rotura Uterina`
    },
    'INGRESO_UCI': {
        column: 'MANEJO_ESPECIFICO_Ingreso_a_UCI',
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Ingreso a UCI Requerido`
    },
    'CIRUGIA_MAYOR_EMERG': { // Laparotomía o Histerectomía (asumiendo Laparo es la principal)
        column: 'MANEJO_QX_LAPAROTOMIA',
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Cirugía Mayor de Emergencia (Laparotomía)`
    },
    'TRANSFUSION_MASIVA': {
        column: 'UNIDADES_TRANSFUNDIDAS',
        condition: v => v >= 4,
        text: (v) => `Evento Máxima Alerta: Transfusión Masiva (${v} UGRE)`
    },
    // --- Signos Vitales de Alerta ---
    'CONSCIENCIA_NO_ALERTA': {
        column: 'CONSCIENCIA_INGRESO',
        condition: v => String(v).toLowerCase() !== 'alerta', // Chequea si NO es 'alerta'
        text: () => `Estado de Conciencia: No Alerta`
    },
    'PAS_MENOR_90': {
        column: 'PAS_ESTANCIA_MIN',
        condition: v => v < 90,
        text: v => `Presión Arterial Sistólica (PAS): ${v?.toFixed(0)} mmHg (< 90)`
    },
    'PAS_MAYOR_160': {
        // Necesitamos el valor MAX de PAS durante estancia, no está en las 54 columnas provistas.
        // Usaremos PAS_INGRESO_ALTA como proxy, ¡advertir sobre esto!
        column: 'PAS_INGRESO_ALTA', // ADVERTENCIA: Usando valor de ingreso como proxy
        condition: v => v > 160,
        text: v => `Presión Arterial Sistólica (PAS): ${v?.toFixed(0)} mmHg (> 160) (Valor Ingreso)`
    },
    'PAD_MENOR_60': {
        column: 'PAD_ESTANCIA_MIN',
        condition: v => v < 60,
        text: v => `Presión Arterial Diastólica (PAD): ${v?.toFixed(0)} mmHg (< 60)`
    },
    'PAD_MAYOR_110': {
        // Necesitamos el valor MAX de PAD, no está. Usaremos PAD_INGRESO_BAJA como proxy muy imperfecto
        // (Idealmente se necesitaría PAD_INGRESO_ALTA o PAD_ESTANCIA_MAX)
        column: 'PAD_INGRESO_BAJA', // ADVERTENCIA: Proxy muy imperfecto
        condition: v => v > 110, // Es poco probable que PAD baja sea > 110, pero mantenemos la lógica
        text: v => `Presión Arterial Diastólica (PAD): ${v?.toFixed(0)} mmHg (> 110) (Valor Ingreso - Baja)` // Ajustar si tienes PAD max
    },
    'FC_MAYOR_120': {
        // Usando la columna que asumimos es MAX de la estancia
        column: 'F_CARIDIACA_ESTANCIA_MIN', // ¡VERIFICAR SI ESTA ES MAX! (1ra en muestra)
        condition: v => v > 120,
        text: v => `Frecuencia Cardíaca (FC): ${v?.toFixed(0)} lpm (> 120)`
    },
    'FC_MENOR_50': {
        // Usando la columna que asumimos es MIN de la estancia
        column: 'F_CARDIACA_ESTANCIA_MIN', // ¡VERIFICAR SI ESTA ES MIN! (2da en muestra)
        condition: v => v < 50,
        text: v => `Frecuencia Cardíaca (FC): ${v?.toFixed(0)} lpm (< 50)`
    },
    'FR_MAYOR_30': {
        column: 'F_RESPIRATORIA_INGRESO_ALTA', // Usando valor de ingreso
        condition: v => v > 30,
        text: v => `Frecuencia Respiratoria (FR): ${v?.toFixed(0)} rpm (> 30) (Valor Ingreso)`
    },
    'FR_MENOR_10': {
        column: 'F_RESPIRATORIA_INGRESO_ALTA', // Usando valor de ingreso (necesitaría FR min estancia)
        condition: v => v < 10,
        text: v => `Frecuencia Respiratoria (FR): ${v?.toFixed(0)} rpm (< 10) (Valor Ingreso)`
    },
    'SAO2_MENOR_92': {
        // No tenemos SaO2_ESTANCIA_MIN. SaO2_ESTANCIA_MAX no sirve. Omitimos.
        // Si tuvieras la columna:
        // column: 'SaO2_ESTANCIA_MIN',
        // condition: v => v < 92,
        // text: v => `Saturación de Oxígeno (SaO2): ${v?.toFixed(0)}% (< 92)`
    },
    // --- Parámetros de Laboratorio Críticos ---
    'HB_MENOR_7': {
        column: 'HEMOGLOBINA_ESTANCIA_MIN',
        condition: v => v < 7.0,
        text: v => `Hemoglobina (Hb): ${v?.toFixed(1)} g/dL (< 7.0)`
    },
    'PLAQUETAS_MENOR_100K': {
        column: 'Recuento_de_plaquetas_-_PLT___min',
        condition: v => v < 100000,
        text: v => `Plaquetas: ${v ? (v / 1000)?.toFixed(0) + 'k' : 'N/A'} /µL (< 100k)` // Mostrar en miles
    },
    'PLAQUETAS_MENOR_50K': { // Más específico y grave
        column: 'Recuento_de_plaquetas_-_PLT___min',
        condition: v => v < 50000,
        text: v => `Plaquetas MUY BAJAS: ${v ? (v / 1000)?.toFixed(0) + 'k' : 'N/A'} /µL (< 50k)`
    },
    'CREATININA_MAYOR_1_2': {
        column: 'CREATININA_ESTANCIA_MAX',
        condition: v => v > 1.2,
        text: v => `Creatinina: ${v?.toFixed(2)} mg/dL (> 1.2)`
    },
    'TRANSAMINASAS_ELEVADAS': { // Usar GOT max estancia y GPT ingreso
        column: ['GOT_Aspartato_aminotransferasa_max', 'GPT_INGRESO'],
        condition: (got, gpt) => (got > 70 || gpt > 70), // Umbral ejemplo, ajustar según LSN
        text: (got, gpt) => `Transaminasas Elevadas (GOT max: ${got?.toFixed(0) ?? 'N/A'}, GPT ing: ${gpt?.toFixed(0) ?? 'N/A'}) (> 70 U/L aprox)`
    },
    'LDH_MAYOR_600': {
        // No tenemos LDH en la lista de 54 columnas. Omitimos.
        // Si tuvieras:
        // column: 'LDH_ESTANCIA_MAX', // O el nombre correcto
        // condition: v => v > 600,
        // text: v => `LDH: ${v?.toFixed(0)} U/L (> 600)`
    },
    'LACTATO_MAYOR_2': {
        // No tenemos Lactato. Omitimos.
    },
    'BILIRRUBINA_MAYOR_1_2': {
        // No tenemos Bilirrubina. Omitimos.
    },
    // --- Otros Signos Clínicos ---
    'OLIGURIA_ANURIA': {
        // No hay un campo directo para esto en las 54 columnas. Omitimos.
        // Se podría inferir si hubiera datos de diuresis horaria.
    },
    'EDEMA_PULMONAR': {
        // No hay un campo directo. Omitimos.
    }
}; */
const alertConditions = {
    // --- Eventos/Diagnósticos Máxima Alerta ---
    'HEMORRAGIA_MAYOR': { // Necesita una definición más precisa o usar DIAG_PRINCIPAL
        column: 'DIAG_PRINCIPAL_HEMORRAGIA', // Usar diagnóstico como proxy inicial
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Hemorragia Obstétrica Mayor (Diagnóstico Principal)` // Aclarar que es basado en diagnóstico
    },
    'ECLAMPSIA_CONVULSIONES': { // Asumir que THE == 1 y consciencia alterada son proxies
        column: ['DIAG_PRINCIPAL_THE', 'CONSCIENCIA_INGRESO'],
        condition: (the, cons) => the == 1 && String(cons).toLowerCase() !== 'alerta',
        text: () => `Evento Máxima Alerta: Sospecha Eclampsia / Convulsiones (THE + No Alerta)`
    },
    'SEPSIS_SHOCK_SEPTICO': { // Difícil de determinar solo con estos datos, usar proxies
        column: ['PAS_ESTANCIA_MIN', 'PAD_ESTANCIA_MIN', 'F_CARIDIACA_ESTANCIA_MIN'], // (Usando FC Max aquí)
        condition: (pas, pad, fc) => (pas < 90 || pad < 60) && fc > 120, // Hipotensión + Taquicardia como proxy muy básico
        text: () => `Evento Máxima Alerta: Sospecha Sepsis Severa / Shock Séptico (Hipotensión + Taquicardia)`
    },
    'ROTURA_UTERINA': {
        column: 'WAOS_Rotura_uterina_durante_el_parto',
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Rotura Uterina`
    },
    'INGRESO_UCI': {
        column: 'MANEJO_ESPECIFICO_Ingreso_a_UCI',
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Ingreso a UCI Requerido`
    },
    'CIRUGIA_MAYOR_EMERG': { // Laparotomía o Histerectomía (asumiendo Laparo es la principal)
        column: 'MANEJO_QX_LAPAROTOMIA',
        condition: v => v == 1,
        text: () => `Evento Máxima Alerta: Cirugía Mayor de Emergencia (Laparotomía)`
    },
    'TRANSFUSION_MASIVA': {
        column: 'UNIDADES_TRANSFUNDIDAS',
        condition: v => v >= 4,
        text: (v) => `Evento Máxima Alerta: Transfusión Masiva (${v} UGRE)`
    },
    // --- Signos Vitales de Alerta ---
    'CONSCIENCIA_NO_ALERTA': {
        column: 'CONSCIENCIA_INGRESO',
        condition: v => String(v).toLowerCase() !== 'alerta', // Chequea si NO es 'alerta'
        text: () => `Estado de Conciencia: No Alerta`
    },
    'PAS_MENOR_90': {
        column: 'PAS_ESTANCIA_MIN',
        condition: v => v < 90,
        // text: v => `Presión Arterial Sistólica (PAS): ${v?.toFixed(0)} mmHg (< 90)`
        text: v => `Presión Arterial Sistólica (PAS): ${v ? v?.toFixed(0) : 'N/A'} mmHg (< 90)`
    },
    'PAS_MAYOR_160': {
        // Necesitamos el valor MAX de PAS durante estancia, no está en las 54 columnas provistas.
        // Usaremos PAS_INGRESO_ALTA como proxy, ¡advertir sobre esto!
        column: 'PAS_INGRESO_ALTA', // ADVERTENCIA: Usando valor de ingreso como proxy
        condition: v => v > 160,
        text: v => `Presión Arterial Sistólica (PAS): ${v ? v?.toFixed(0) : 'N/A'} mmHg (> 160) (Valor Ingreso)`
    },
    'PAD_MENOR_60': {
        column: 'PAD_ESTANCIA_MIN',
        condition: v => v < 60,
        text: v => `Presión Arterial Diastólica (PAD): ${v ? v?.toFixed(0) : 'N/A'} mmHg (< 60)`
    },
    'PAD_MAYOR_110': {
        // Necesitamos el valor MAX de PAD, no está. Usaremos PAD_INGRESO_BAJA como proxy muy imperfecto
        // (Idealmente se necesitaría PAD_INGRESO_ALTA o PAD_ESTANCIA_MAX)
        column: 'PAD_INGRESO_BAJA', // ADVERTENCIA: Proxy muy imperfecto
        condition: v => v > 110, // Es poco probable que PAD baja sea > 110, pero mantenemos la lógica
        text: v => `Presión Arterial Diastólica (PAD): ${v ? v?.toFixed(0) : 'N/A'} mmHg (> 110) (Valor Ingreso - Baja)` // Ajustar si tienes PAD max
    },
    'FC_MAYOR_120': {
        // Usando la columna que asumimos es MAX de la estancia
        column: 'F_CARIDIACA_ESTANCIA_MIN', // ¡VERIFICAR SI ESTA ES MAX! (1ra en muestra)
        condition: v => v > 120,
        text: v => `Frecuencia Cardíaca (FC): ${v ? v?.toFixed(0) : 'N/A'} lpm (> 120)`
    },
    'FC_MENOR_50': {
        // Usando la columna que asumimos es MIN de la estancia
        column: 'F_CARDIACA_ESTANCIA_MIN', // ¡VERIFICAR SI ESTA ES MIN! (2da en muestra)
        condition: v => v < 50,
        text: v => `Frecuencia Cardíaca (FC): ${v ? v?.toFixed(0) : 'N/A'} lpm (< 50)`
    },
    'FR_MAYOR_30': {
        column: 'F_RESPIRATORIA_INGRESO_ALTA', // Usando valor de ingreso
        condition: v => v > 30,
        text: v => `Frecuencia Respiratoria (FR): ${v ? v?.toFixed(0) : 'N/A'} rpm (> 30) (Valor Ingreso)`
    },
    'FR_MENOR_10': {
        column: 'F_RESPIRATORIA_INGRESO_ALTA', // Usando valor de ingreso (necesitaría FR min estancia)
        condition: v => v < 10,
        text: v => `Frecuencia Respiratoria (FR): ${v ? v?.toFixed(0) : 'N/A'} rpm (< 10) (Valor Ingreso)`
    },
    'SAO2_MENOR_92': {
        // No tenemos SaO2_ESTANCIA_MIN. SaO2_ESTANCIA_MAX no sirve. Omitimos.
        // Si tuvieras la columna:
        // column: 'SaO2_ESTANCIA_MIN',
        // condition: v => v < 92,
        // text: v => `Saturación de Oxígeno (SaO2): ${v ? v?.toFixed(0) : 'N/A'}% (< 92)`
    },
    // --- Parámetros de Laboratorio Críticos ---
    'HB_MENOR_7': {
        column: 'HEMOGLOBINA_ESTANCIA_MIN',
        condition: v => v < 7.0,
        text: v => `Hemoglobina (Hb): ${v ? v?.toFixed(1) : 'N/A'} g/dL (< 7.0)`
    },
    'PLAQUETAS_MENOR_100K': {
        column: 'Recuento_de_plaquetas_-_PLT___min',
        condition: v => v < 100,
        text: v => `Plaquetas: ${v ? (v * 1)?.toFixed(0) + 'k' : 'N/A'} /µL (< 100k)` // Mostrar en miles
    },
    'PLAQUETAS_MENOR_50K': { // Más específico y grave
        column: 'Recuento_de_plaquetas_-_PLT___min',
        condition: v => v < 50,
        text: v => `Plaquetas MUY BAJAS: ${v ? (v * 1)?.toFixed(0) + 'k' : 'N/A'} /µL (< 50k)`
    },
    'CREATININA_MAYOR_1_2': {
        column: 'CREATININA_ESTANCIA_MAX',
        condition: v => v > 1.2,
        text: v => `Creatinina: ${v?.toFixed(2)} mg/dL (> 1.2)`
    },
    'TRANSAMINASAS_ELEVADAS': { // Usar GOT max estancia y GPT ingreso
        column: ['GOT_Aspartato_aminotransferasa_max', 'GPT_INGRESO'],
        condition: (got, gpt) => (got > 70 || gpt > 70), // Umbral ejemplo, ajustar según LSN
        text: (got, gpt) => `Transaminasas Elevadas (GOT max: ${got?.toFixed(0) ?? 'N/A'}, GPT ing: ${gpt?.toFixed(0) ?? 'N/A'}) (> 70 U/L aprox)`
    },
    'LDH_MAYOR_600': {
        // No tenemos LDH en la lista de 54 columnas. Omitimos.
        // Si tuvieras:
        // column: 'LDH_ESTANCIA_MAX', // O el nombre correcto
        // condition: v => v > 600,
        // text: v => `LDH: ${v ? v?.toFixed(0) : 'N/A'} U/L (> 600)`
    },
    'LACTATO_MAYOR_2': {
        // No tenemos Lactato. Omitimos.
    },
    'BILIRRUBINA_MAYOR_1_2': {
        // No tenemos Bilirrubina. Omitimos.
    },
    // --- Otros Signos Clínicos ---
    'OLIGURIA_ANURIA': {
        // No hay un campo directo para esto en las 54 columnas. Omitimos.
        // Se podría inferir si hubiera datos de diuresis horaria.
    },
    'EDEMA_PULMONAR': {
        // No hay un campo directo. Omitimos.
    }
};

// --- Función auxiliar para parseo numérico seguro ---
function safeParseFloat(value) {
    if (value === null || value === undefined) return NaN;
    const strValue = String(value).replace(',', '.').trim(); // Reemplaza coma, quita espacios
    if (strValue === '') return NaN;
    const num = parseFloat(strValue);
    return isNaN(num) ? NaN : num; // Devuelve NaN si no es número válido
}

// --- Función para formatear JSONL Record ---
function createJsonlRecord(row, alertConditionsMap, availableColumns, outputColumn) {
    const outputLabel = row[outputColumn];
    if (outputLabel === null || outputLabel === undefined || ['Error', 'Indeterminado', ''].includes(String(outputLabel).trim())) {
        return null;
    }
    const outputText = String(outputLabel).trim();

    const findings = [];
    const processedValues = {}; // Cache para evitar parseo repetido

    // Función para obtener y parsear valor de forma segura
    const getValue = (colName) => {
        if (!availableColumns.includes(colName)) return undefined; // Columna no existe
        if (!(colName in processedValues)) {
            processedValues[colName] = safeParseFloat(row[colName]);
            // Si no es número, guardar el string original (para 'CONSCIENCIA_INGRESO')
            if (isNaN(processedValues[colName])) {
                processedValues[colName] = row[colName];
            }
        }
        return processedValues[colName];
    };


    for (const key in alertConditionsMap) {
        const config = alertConditionsMap[key];
        let valuesToCheck = [];
        let conditionMet = false;
        let areAllColsAvailable = true; // Flag para chequear si todas las columnas necesarias están

        if (Array.isArray(config.column)) {
            // Condición que depende de múltiples columnas
            valuesToCheck = config.column.map(col => {
                if (!availableColumns.includes(col)) areAllColsAvailable = false;
                return getValue(col);
            });
            // Si alguna columna falta, no se puede evaluar
            if (areAllColsAvailable && valuesToCheck.every(v => v !== undefined)) {
                // Asegurarse que todos los valores requeridos no sean NaN si la condición espera números
                // (Adaptar si la condición puede manejar NaNs)
                if (valuesToCheck.every(v => typeof v === 'number' ? !isNaN(v) : v !== undefined)) {
                    conditionMet = config.condition(...valuesToCheck);
                }
            }
        } else {
            // Condición que depende de una columna
            const colName = config.column;
            if (availableColumns.includes(colName)) {
                const value = getValue(colName);
                if (value !== undefined) { // Incluye números parseados y strings originales
                    valuesToCheck = [value];
                    // Asegurarse que el valor no sea NaN si la condición espera un número
                    if (typeof value === 'number' ? !isNaN(value) : value !== undefined) {
                        conditionMet = config.condition(value);
                    }
                }
            } else {
                areAllColsAvailable = false; // La única columna necesaria no está
            }
        }

        // Si la condición se cumple y todas las columnas estaban disponibles
        if (conditionMet && areAllColsAvailable) {
            try {
                const findingText = typeof config.text === 'function' ? config.text(...valuesToCheck) : config.text;
                findings.push(`*   ${findingText}`);
            } catch (textError) {
                console.error(`Error generando texto para ${key} con valores ${valuesToCheck}: ${textError.message}`);
                findings.push(`*   ${key}: Dato presente pero error al formatear texto`); // Añadir indicación de error
            }
        }
    }

    if (findings.length === 0) {
        findings.push("*   Sin hallazgos de alerta significativos registrados.");
    }

    const textInput = `Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos. Responde únicamente con una de las categorías: Bajo, Moderado, Alto, Crítico.\n\nHallazgos Clínicos Relevantes:\n${findings.join('\n')}\n\nClasificación de Riesgo:`;
    
    const outputTextX=JSON.stringify({'riesgo': outputText });
    const record = {
        "system_instruction": { // Incluir instrucción del sistema
            "parts": [
                { "text": "Eres un asistente experto en evaluación de riesgo obstétrico. Analiza el siguiente resumen de hallazgos clínicos de una paciente y clasifica su riesgo de morbilidad/mortalidad materna EXACTAMENTE como: Bajo, Moderado, Alto o Crítico." }
            ]
        },
        "contents": [
            { "role": "user", "parts": [{ "text": textInput }] },
            { "role": "model", "parts": [{ "text": outputTextX }] }
        ]
    };
    return JSON.stringify(record);
}

// --- Lógica Principal ---
// ... (Lectura del Excel igual, obtener 'rows' y 'availableColumnsInSheet') ...
let workbook;
try {
    workbook = XLSX.readFile(path.resolve(__dirname, inputExcelFile));
} catch (err) {
    console.error(`Error al leer el archivo Excel de entrada: ${err.message}`);
    process.exit(1);
}

const sheetName = workbook.SheetNames[0];
const worksheet = workbook.Sheets[sheetName];

if (!worksheet) {
    console.error(`No se encontró la hoja de cálculo '${sheetName}' en el archivo Excel.`);
    process.exit(1);
}

const rows = XLSX.utils.sheet_to_json(worksheet);
console.log(`Se encontraron ${rows.length} filas en la hoja '${sheetName}'. Procesando...`);

let availableColumnsInSheet = [];
if (rows.length > 0) {
    availableColumnsInSheet = Object.keys(rows[0]);
} else {
    console.warn("El archivo Excel parece estar vacío.");
    process.exit(0);
}

const allJsonlStrings = [];

// 1. Formatear todos los datos válidos a JSONL strings
rows.forEach((row, index) => {
    try {
        const jsonlString = createJsonlRecord(row, alertConditions, availableColumnsInSheet, OUTPUT_COLUMN_NAME);
        if (jsonlString) {
            allJsonlStrings.push(jsonlString);
        } else {
            // Opcional: Loguear por qué se omitió (ya se hace dentro de createJsonlRecord si es por salida inválida)
            // console.warn(`Fila ${index + 1} (ID: ${row.ID || 'desconocido'}) omitida.`);
        }
    } catch (parseError) {
        console.error(`Error procesando fila ${index + 1} (ID: ${row.ID || 'desconocido'}): ${parseError.message}`);
    }
});

console.log(`Se formatearon ${allJsonlStrings.length} ejemplos válidos en formato JSONL.`);

if (allJsonlStrings.length < 2) {
    console.error("No hay suficientes datos válidos para crear conjuntos de entrenamiento y validación.");
    process.exit(1);
}

// 2. Mezclar los datos (Shuffle) - Misma función shuffleArray
shuffleArray(allJsonlStrings);
console.log("Datos mezclados aleatoriamente.");

// 3. Dividir en entrenamiento y validación - Misma lógica
const validationSize = Math.max(1, Math.floor(allJsonlStrings.length * VALIDATION_SPLIT_RATIO));
const trainingSize = allJsonlStrings.length - validationSize;

const trainingSetStrings = allJsonlStrings.slice(0, trainingSize);
const validationSetStrings = allJsonlStrings.slice(trainingSize);

console.log(`División: ${trainingSetStrings.length} para entrenamiento, ${validationSetStrings.length} para validación.`);

// 4. Escribir archivos JSONL - Misma función writeJsonlFileFromStrings
function writeJsonlFileFromStrings(filename, stringArray) {
    try {
        const fileContent = stringArray.join('\n');
        fs.writeFileSync(path.resolve(__dirname, filename), fileContent, 'utf-8');
        console.log(`Archivo JSONL "${filename}" creado con éxito con ${stringArray.length} registros.`);
    } catch (writeError) {
        console.error(`Error al escribir el archivo JSONL "${filename}": ${writeError.message}`);
    }
}

writeJsonlFileFromStrings(outputTrainingFile, trainingSetStrings);
writeJsonlFileFromStrings(outputValidationFile, validationSetStrings);

console.log("Proceso completado.");

// Función Shuffle
function shuffleArray(array) {
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
}