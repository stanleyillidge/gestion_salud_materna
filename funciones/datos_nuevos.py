import pandas as pd
import numpy as np # Importar numpy para manejar NaN de forma más robusta

# --- Configuración ---
input_csv_file = 'datos_nuevos.csv' # Asegúrate que este sea el nombre correcto
output_excel_file = 'datos_nuevos_con_riesgo_ponderado_critico.xlsx' # Nuevo nombre de archivo

# --- PONDERACIÓN DE RIESGOS (¡REQUIERE VALIDACIÓN CLÍNICA!) ---
# Pesos ilustrativos. Mayor puntuación = Mayor Riesgo Agudo.
pesos_riesgo = {
    # === Factores Críticos (Mayor Peso - Amenaza Vital Inminente) ===
    'rotura_uterina': 25,         # Col: WAOS_Rotura_uterina_durante_el_parto == 1
    'shock_hipotension_severa': 20,# Col: PAS_ESTANCIA_MIN < 70 O PAD_ESTANCIA_MIN < 40 (Shock profundo)
    'consciencia_no_alerta': 18,    # Col: CONSCIENCIA_INGRESO != 'Alerta' (o == 0 si es código)
    'ingreso_uci': 15,              # Col: MANEJO_ESPECIFICO_Ingreso_a_UCI == 1
    'transfusion_masiva': 12,       # Col: UNIDADES_TRANSFUNDIDAS >= 4
    'bradicardia_extrema': 12,      # Col: F_CARDIACA_ESTANCIA_MIN < 50 (Asumiendo la columna correcta para MIN)
    'falla_respiratoria_severa': 10,# Col: F_RESPIRATORIA_INGRESO_ALTA > 30 o < 10 (Usando ingreso como proxy)
    # 'hipoxemia_severa': 10,       # COLUMNA SaO2_ESTANCIA_MIN FALTANTE O NO FIABLE EN MUESTRA - Omitido por ahora
    'plaquetopenia_muy_severa': 12, # Col: Recuento_de_plaquetas_-_PLT___min < 50000
    'falla_renal_aguda_severa': 10, # Col: CREATININA_ESTANCIA_MAX > 2.0
    'falla_hepatica_aguda_severa': 10,# Col: GOT_Aspartato_aminotransferasa_max > 500 (o GPT_INGRESO > 500)
    'taquicardia_muy_severa': 10,   # Col: F_CARIDIACA_ESTANCIA_MIN > 130 (Asumiendo la columna correcta para MAX) # Ajustar nombre columna si es diferente

    # === Factores de Alerta Mayor (Peso Moderado-Alto) ===
    'diagnostico_hemorragia': 8,     # Col: DIAG_PRINCIPAL_HEMORRAGIA == 1
    'diagnostico_the_severo': 8,    # Col: DIAG_PRINCIPAL_THE == 1 (Especialmente si hay signos de severidad asociados)
    'hipotension_moderada': 7,      # Col: PAS_ESTANCIA_MIN < 90 (y no < 70) O PAD_ESTANCIA_MIN < 60 (y no < 40)
    'plaquetopenia_severa': 7,      # Col: Recuento_de_plaquetas_-_PLT___min < 100000 (y no < 50k)
    'falla_renal_aguda_mod': 6,     # Col: CREATININA_ESTANCIA_MAX > 1.2 (y no > 2.0)
    'anemia_muy_severa': 6,         # Col: HEMOGLOBINA_ESTANCIA_MIN < 7.0
    'transfusion_simple': 5,        # Col: UNIDADES_TRANSFUNDIDAS entre 1 y 3
    'cirugia_mayor_emergencia': 7,  # Col: MANEJO_QX_LAPAROTOMIA == 1 (o MANEJO_QX_OTRA == 1, si es relevante)
    'ingreso_uado': 5,              # Col: MANEJO_ESPECIFICO_Ingreso_a_UADO == 1 (y no en UCI)

    # === Factores de Alerta Menor (Peso Bajo-Moderado) ===
    'taquicardia_moderada': 4,      # Col: F_CARIDIACA_ESTANCIA_MIN > 120 (y no > 130) # Ajustar nombre columna si es diferente
    'falla_hepatica_aguda_mod': 4,  # Col: GOT_max > 100 (y no > 500) o GPT_ingreso > 100 (y no > 500)
    'taquipnea_moderada': 3,        # Col: F_RESPIRATORIA_INGRESO_ALTA > 24 (y no > 30)
    'cirugia_no_programada_waos': 3,# Col: WAOS_Procedimiento_quirúrgico_no_programado == 1
}

# --- UMBRALES DE PUNTUACIÓN (EJEMPLO - ¡AJUSTAR CON EXPERTOS!) ---
# Define los puntos de corte para cada nivel de riesgo
umbral_riesgo_moderado = 25  # Puntuación >= a esto es Moderado (o superior)
umbral_riesgo_alto = 35      # Puntuación >= a esto es Alto (o superior)
umbral_riesgo_critico = 45   # Puntuación >= a esto es Crítico

# --- Función para Calcular Puntuación y Clasificar Riesgo ---
def calcular_clasificar_riesgo_ponderado(row):
    """
    Calcula una puntuación de riesgo ponderada materna y clasifica a la paciente
    en Bajo, Moderado, Alto o Crítico.
    """
    puntuacion = 0
    debug_info = [] # Para rastrear qué criterios se cumplen

    try:
        # --- Conversión y Limpieza Segura (sin cambios) ---
        def safe_float_conversion(value):
            if pd.isna(value): return np.nan
            try: return float(str(value).replace(',', '.'))
            except (ValueError, TypeError): return np.nan

        def safe_int_conversion(value):
             if pd.isna(value): return np.nan
             try:
                if not pd.isna(value): return int(value)
             except (ValueError, TypeError):
                 try:
                     float_val = safe_float_conversion(value)
                     return int(float_val) if not np.isnan(float_val) else np.nan
                 except (ValueError, TypeError):
                     return np.nan
             return np.nan

        # --- Obtener valores usando los nombres exactos de columna (sin cambios) ---
        rotura_uterina = safe_int_conversion(row.get('WAOS_Rotura_uterina_durante_el_parto'))
        pas_min_estancia = safe_float_conversion(row.get('PAS_ESTANCIA_MIN'))
        pad_min_estancia = safe_float_conversion(row.get('PAD_ESTANCIA_MIN'))
        consciencia_str = str(row.get('CONSCIENCIA_INGRESO', '')).strip().lower()
        ingreso_uci = safe_int_conversion(row.get('MANEJO_ESPECIFICO_Ingreso_a_UCI'))
        unidades_transfundidas = safe_int_conversion(row.get('UNIDADES_TRANSFUNDIDAS'))
        fc_max_estancia = safe_float_conversion(row.get('F_CARIDIACA_ESTANCIA_MIN')) # ASUME MAX
        fc_min_estancia = safe_float_conversion(row.get('F_CARDIACA_ESTANCIA_MIN')) # ASUME MIN
        fr_ingreso_alta = safe_int_conversion(row.get('F_RESPIRATORIA_INGRESO_ALTA'))
        plaquetas_min = safe_float_conversion(row.get('Recuento_de_plaquetas_-_PLT___min'))
        creatinina_max_estancia = safe_float_conversion(row.get('CREATININA_ESTANCIA_MAX'))
        got_max_estancia = safe_float_conversion(row.get('GOT_Aspartato_aminotransferasa_max'))
        gpt_ingreso = safe_float_conversion(row.get('GPT_INGRESO'))
        diag_hemorragia = safe_int_conversion(row.get('DIAG_PRINCIPAL_HEMORRAGIA'))
        diag_the = safe_int_conversion(row.get('DIAG_PRINCIPAL_THE'))
        hb_min_estancia = safe_float_conversion(row.get('HEMOGLOBINA_ESTANCIA_MIN'))
        laparotomia = safe_int_conversion(row.get('MANEJO_QX_LAPAROTOMIA'))
        otra_qx_manejo = safe_int_conversion(row.get('MANEJO_QX_OTRA'))
        ingreso_uado = safe_int_conversion(row.get('MANEJO_ESPECIFICO_Ingreso_a_UADO'))
        cirugia_no_prog_waos = safe_int_conversion(row.get('WAOS_Procedimiento_quirúrgico_no_programado'))

        # --- Evaluar Criterios y Sumar Puntuación (sin cambios en la lógica de suma) ---
        # ... (toda la lógica de if/elif para sumar puntos permanece igual) ...
        # Factores Críticos
        critico_shock_severo = False
        if (not np.isnan(pas_min_estancia) and pas_min_estancia < 70) or \
           (not np.isnan(pad_min_estancia) and pad_min_estancia < 40):
            puntuacion += pesos_riesgo['shock_hipotension_severa']
            critico_shock_severo = True
            debug_info.append('shock_severo')
        critico_fc_min_severa = False
        if not np.isnan(fc_min_estancia) and fc_min_estancia < 50:
            puntuacion += pesos_riesgo['bradicardia_extrema']
            critico_fc_min_severa = True
            debug_info.append('bradicardia_extrema')
        critico_fr_severa = False
        if not np.isnan(fr_ingreso_alta) and (fr_ingreso_alta > 30 or fr_ingreso_alta < 10):
            puntuacion += pesos_riesgo['falla_respiratoria_severa']
            critico_fr_severa = True
            debug_info.append('falla_resp_severa')
        critico_plaquetas_muy_severa = False
        if not np.isnan(plaquetas_min) and plaquetas_min < 50000:
            puntuacion += pesos_riesgo['plaquetopenia_muy_severa']
            critico_plaquetas_muy_severa = True
            debug_info.append('plaq_muy_severa')
        critico_renal_severa = False
        if not np.isnan(creatinina_max_estancia) and creatinina_max_estancia > 2.0:
            puntuacion += pesos_riesgo['falla_renal_aguda_severa']
            critico_renal_severa = True
            debug_info.append('renal_severa')
        critico_hepatica_severa = False
        if (not np.isnan(got_max_estancia) and got_max_estancia > 500) or \
           (not np.isnan(gpt_ingreso) and gpt_ingreso > 500):
             puntuacion += pesos_riesgo['falla_hepatica_aguda_severa']
             critico_hepatica_severa = True
             debug_info.append('hepatica_severa')
        critico_fc_max_severa = False
        if not np.isnan(fc_max_estancia) and fc_max_estancia > 130:
            puntuacion += pesos_riesgo['taquicardia_muy_severa']
            critico_fc_max_severa = True
            debug_info.append('taqui_muy_severa')
        if rotura_uterina == 1:
            puntuacion += pesos_riesgo['rotura_uterina']
            debug_info.append('rotura_uterina')
        if consciencia_str != 'alerta' and consciencia_str != '':
             puntuacion += pesos_riesgo['consciencia_no_alerta']
             debug_info.append('consciencia_no_alerta')
        if ingreso_uci == 1:
             puntuacion += pesos_riesgo['ingreso_uci']
             debug_info.append('ingreso_uci')
        if not np.isnan(unidades_transfundidas) and unidades_transfundidas >= 4:
             puntuacion += pesos_riesgo['transfusion_masiva']
             debug_info.append('transf_masiva')

        # Factores de Alerta Mayor
        if diag_hemorragia == 1:
            puntuacion += pesos_riesgo['diagnostico_hemorragia']
            debug_info.append('diag_hemorragia')
        if diag_the == 1:
            puntuacion += pesos_riesgo['diagnostico_the_severo']
            debug_info.append('diag_the')
        if not critico_shock_severo:
            if (not np.isnan(pas_min_estancia) and pas_min_estancia < 90) or \
               (not np.isnan(pad_min_estancia) and pad_min_estancia < 60):
                puntuacion += pesos_riesgo['hipotension_moderada']
                debug_info.append('hipotension_mod')
        if not critico_plaquetas_muy_severa:
             if not np.isnan(plaquetas_min) and plaquetas_min < 100000:
                 puntuacion += pesos_riesgo['plaquetopenia_severa']
                 debug_info.append('plaq_severa')
        if not critico_renal_severa:
            if not np.isnan(creatinina_max_estancia) and creatinina_max_estancia > 1.2:
                puntuacion += pesos_riesgo['falla_renal_aguda_mod']
                debug_info.append('renal_mod')
        if not np.isnan(hb_min_estancia) and hb_min_estancia < 7.0:
             puntuacion += pesos_riesgo['anemia_muy_severa']
             debug_info.append('anemia_muy_severa')
        if not np.isnan(unidades_transfundidas) and 1 <= unidades_transfundidas < 4:
             puntuacion += pesos_riesgo['transfusion_simple']
             debug_info.append('transf_simple')
        if laparotomia == 1:
             puntuacion += pesos_riesgo['cirugia_mayor_emergencia']
             debug_info.append('laparotomia')
        elif otra_qx_manejo == 1:
             puntuacion += pesos_riesgo.get('cirugia_mayor_emergencia', 0)
             debug_info.append('otra_qx_mayor')
        if ingreso_uado == 1 and ingreso_uci != 1:
             puntuacion += pesos_riesgo['ingreso_uado']
             debug_info.append('ingreso_uado')

        # Factores de Alerta Menor
        if not critico_fc_max_severa:
            if not np.isnan(fc_max_estancia) and fc_max_estancia > 120:
                 puntuacion += pesos_riesgo['taquicardia_moderada']
                 debug_info.append('taqui_mod')
        if not critico_hepatica_severa:
            if (not np.isnan(got_max_estancia) and got_max_estancia > 100) or \
               (not np.isnan(gpt_ingreso) and gpt_ingreso > 100):
                puntuacion += pesos_riesgo['falla_hepatica_aguda_mod']
                debug_info.append('hepatica_mod')
        if not critico_fr_severa:
             if not np.isnan(fr_ingreso_alta) and fr_ingreso_alta > 24:
                 puntuacion += pesos_riesgo['taquipnea_moderada']
                 debug_info.append('taquipnea_mod')
        if cirugia_no_prog_waos == 1 and laparotomia != 1 and otra_qx_manejo != 1:
             puntuacion += pesos_riesgo['cirugia_no_programada_waos']
             debug_info.append('cirugia_no_prog_waos')

        # --- Clasificación Final basada en Puntuación ---
        # <<< CAMBIO EN LA LÓGICA DE CLASIFICACIÓN >>>
        if puntuacion >= umbral_riesgo_critico:
            clasificacion = "Crítico"
        elif puntuacion >= umbral_riesgo_alto:
            clasificacion = "Alto"
        elif puntuacion >= umbral_riesgo_moderado:
            clasificacion = "Moderado"
        else: # Si la puntuación es menor que el umbral moderado
            clasificacion = "Bajo"

        # Devolver puntuación y clasificación
        return pd.Series({'PUNTUACION_RIESGO': puntuacion, 'NIVEL_RIESGO_PONDERADO': clasificacion})
        # Alternativa con debug:
        # return pd.Series({'PUNTUACION_RIESGO': puntuacion, 'NIVEL_RIESGO_PONDERADO': clasificacion, 'CRITERIOS_ACTIVADOS': ', '.join(debug_info)})

    except Exception as e:
        row_id = row.get('ID', row.get('IDENTIFICACION', 'Desconocido'))
        print(f"Error procesando fila ID {row_id}: {e}")
        return pd.Series({'PUNTUACION_RIESGO': np.nan, 'NIVEL_RIESGO_PONDERADO': "Error"})

# --- Carga y Procesamiento del CSV ---
try:
    df = pd.read_csv(input_csv_file, low_memory=False)
    print(f"Columnas leídas: {df.columns.tolist()}")
except FileNotFoundError:
    print(f"Error: Archivo '{input_csv_file}' no encontrado.")
    exit()
except Exception as e:
    print(f"Error al leer el archivo CSV: {e}")
    exit()

# --- Aplicar la función ---
riesgo_df = df.apply(calcular_clasificar_riesgo_ponderado, axis=1)
df = pd.concat([df, riesgo_df], axis=1)

# --- Guardar el resultado en Excel ---
# NIVEL_RIESGO_PONDERADO
try:
    df.to_excel(output_excel_file, index=False, engine='openpyxl')
    print(f"Archivo Excel '{output_excel_file}' generado con éxito.")
    print("\nDistribución de Nuevos Niveles de Riesgo Calculados (Ponderado):")
    # Mostrar distribución incluyendo errores y los 4 niveles
    print(df['NIVEL_RIESGO_PONDERADO'].value_counts(dropna=False))
except ImportError:
     print("Error: Necesitas instalar la librería 'openpyxl' para escribir archivos Excel.")
     print("Ejecuta: pip install openpyxl")
except Exception as e:
    print(f"Error al guardar el archivo Excel: {e}")