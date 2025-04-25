import pandas as pd
import numpy as np

# Funciones de conversión segura
def safe_float(value):
    if pd.isnull(value):
        return np.nan
    try:
        return float(str(value).replace(',', '.'))
    except Exception:
        return np.nan

def safe_int(value):
    if pd.isnull(value):
        return np.nan
    try:
        return int(float(str(value).replace(',', '.')))
    except Exception:
        return np.nan

# Función para calcular el score y asignar la categoría de riesgo
def calcular_scoring(row):
    score = 0

    # 1. Presión arterial: Evaluamos PAS y PAD y usamos el peor de ambos (para evitar duplicar puntos)
    pas = safe_float(row.get("PAS_INGRESO"))
    pad = safe_float(row.get("PAD_INGRESO"))
    bp_points = 0
    # PAS
    if not np.isnan(pas):
        if pas < 70:
            bp_points = max(bp_points, 5)  # Hipotensión extrema
        elif pas < 90:
            bp_points = max(bp_points, 3)  # Hipotensión severa
        elif pas < 100:
            bp_points = max(bp_points, 1)  # Leve disminución
    # PAD
    if not np.isnan(pad):
        if pad < 40:
            bp_points = max(bp_points, 5)
        elif pad < 60:
            bp_points = max(bp_points, 3)
        elif pad < 70:
            bp_points = max(bp_points, 1)
    score += bp_points

    # 2. Frecuencia Cardíaca (FC)
    fc = safe_float(row.get("FRECUENCIA_CARDIACA_INGRESO"))
    fc_points = 0
    if not np.isnan(fc):
        if fc > 150:
            fc_points = 5  # Taquicardia extrema
        elif fc > 130:
            fc_points = 4  # Taquicardia severa
        elif fc >= 110:
            fc_points = 2  # Taquicardia moderada
        elif fc < 40:
            fc_points = 5  # Bradicardia extrema
        elif fc < 50:
            fc_points = 4  # Bradicardia severa
        elif fc < 60:
            fc_points = 2  # Bradicardia moderada
    score += fc_points

    # 3. Frecuencia Respiratoria (FR)
    fr = safe_float(row.get("F_RESPIRATORIA_INGRESO"))
    fr_points = 0
    if not np.isnan(fr):
        if fr > 35:
            fr_points = 5  # Taquipnea extrema
        elif fr > 30:
            fr_points = 4  # Taquipnea severa
        elif fr > 25:
            fr_points = 2  # Taquipnea moderada
        elif fr < 10:
            fr_points = 5  # Bradipnea extrema
        elif fr < 12:
            fr_points = 4  # Bradipnea severa
        elif fr < 15:
            fr_points = 2  # Bradipnea moderada
    score += fr_points

    # 4. Saturación de Oxígeno (SaO2)
    sao2 = safe_float(row.get("SaO2_ESTANCIA_MAX"))
    sao2_points = 0
    if not np.isnan(sao2):
        if sao2 < 80:
            sao2_points = 5  # Hipoxemia extrema
        elif sao2 < 90:
            sao2_points = 4  # Hipoxemia severa
        elif sao2 < 93:
            sao2_points = 2  # Hipoxemia moderada
    score += sao2_points

    # 5. Hemoglobina: se utiliza el valor más bajo entre ingreso y estancia
    hb_ingreso = safe_float(row.get("HEMOGLOBINA_INGRESO"))
    hb_estancia = safe_float(row.get("HEMOGLOBINA_ESTANCIA_MIN"))
    hb = np.nan
    if not np.isnan(hb_ingreso) and not np.isnan(hb_estancia):
        hb = min(hb_ingreso, hb_estancia)
    elif not np.isnan(hb_ingreso):
        hb = hb_ingreso
    elif not np.isnan(hb_estancia):
        hb = hb_estancia
    hb_points = 0
    if not np.isnan(hb):
        if hb < 5:
            hb_points = 5  # Anemia extrema
        elif hb < 7:
            hb_points = 4  # Anemia severa
        elif hb < 8:
            hb_points = 2  # Anemia moderada
    score += hb_points

    # 6. Recuento de Plaquetas
    plaquetas = safe_float(row.get("Recuento_de_plaquetas_-_PLT___min"))
    plaquetas_points = 0
    if not np.isnan(plaquetas):
        if plaquetas < 20000:
            plaquetas_points = 5  # Trombocitopenia extrema
        elif plaquetas < 50000:
            plaquetas_points = 4  # Trombocitopenia severa
        elif plaquetas < 100000:
            plaquetas_points = 2  # Trombocitopenia moderada
    score += plaquetas_points

    # 7. Creatinina: se utiliza el peor valor entre ingreso y estancia
    creat_ingreso = safe_float(row.get("CREATININA_INGRESO"))
    creat_estancia = safe_float(row.get("CREATININA_ESTANCIA_MAX"))
    creatinina = np.nan
    if not np.isnan(creat_ingreso) and not np.isnan(creat_estancia):
        creatinina = max(creat_ingreso, creat_estancia)
    elif not np.isnan(creat_ingreso):
        creatinina = creat_ingreso
    elif not np.isnan(creat_estancia):
        creatinina = creat_estancia
    creat_points = 0
    if not np.isnan(creatinina):
        if creatinina > 3.0:
            creat_points = 5  # Disfunción renal extrema
        elif creatinina > 2.0:
            creat_points = 4  # Disfunción renal severa
        elif creatinina > 1.2:
            creat_points = 2  # Disfunción renal moderada
    score += creat_points

    # 8. Lesión Hepática: se toma el valor máximo entre GPT y GOT
    gpt = safe_float(row.get("GPT_INGRESO"))
    got = safe_float(row.get("GOT_Aspartato_aminotransferasa_max"))
    liver_value = np.nan
    if not np.isnan(gpt) and not np.isnan(got):
        liver_value = max(gpt, got)
    elif not np.isnan(gpt):
        liver_value = gpt
    elif not np.isnan(got):
        liver_value = got
    liver_points = 0
    if not np.isnan(liver_value):
        if liver_value > 1000:
            liver_points = 5  # Lesión hepática extrema
        elif liver_value > 500:
            liver_points = 4  # Lesión hepática severa
        elif liver_value > 100:
            liver_points = 2  # Lesión hepática moderada
    score += liver_points

    # 9. Evolución Dinámica
    dynamic_points = 0
    # a) Disminución en Hemoglobina
    if not np.isnan(hb_ingreso) and not np.isnan(hb_estancia):
        delta_hb = hb_ingreso - hb_estancia
        if delta_hb >= 3:
            dynamic_points += 2
        elif delta_hb >= 2:
            dynamic_points += 1

    # b) Incremento en Frecuencia Cardíaca (si se dispone de FC máxima en estancia)
    fc_max = safe_float(row.get("FRECUENCIA_CARDIACA_ESTANCIA_MAX"))
    if not np.isnan(fc) and not np.isnan(fc_max):
        if (fc_max - fc) > 20:
            dynamic_points += 1

    # c) Caída en Presión Arterial Sistólica (si se dispone de PAS mínima en estancia)
    pas_min = safe_float(row.get("PAS_ESTANCIA_MIN"))
    if not np.isnan(pas) and not np.isnan(pas_min):
        if (pas - pas_min) > 20:
            dynamic_points += 1

    score += dynamic_points

    # 10. Comorbilidades: Evaluamos la presencia de condiciones de riesgo
    comorb_points = 0
    comorb_str = str(row.get("COMORBIDADES", "")).lower()
    comorb_set = set()
    if "diabetes" in comorb_str:
        comorb_set.add("diabetes")
    if "hipertension" in comorb_str:
        comorb_set.add("hipertension")
    if "cardiopatia" in comorb_str:
        comorb_set.add("cardiopatia")
    if "renal" in comorb_str:
        comorb_set.add("renal")
    if "obesidad" in comorb_str:
        comorb_set.add("obesidad")

    for cond in comorb_set:
        if cond in ["cardiopatia", "renal"]:
            comorb_points += 2
        elif cond in ["diabetes", "hipertension", "obesidad"]:
            comorb_points += 1

    score += comorb_points

    # Clasificación Final (nuevos rangos)
    if score <= 5:
        categoria = "Bajo"
    elif 6 <= score <= 14:
        categoria = "Moderado"
    elif 15 <= score <= 23:
        categoria = "Severo"
    else:
        categoria = "Crítico"

    return pd.Series({
        "TOTAL_SCORE": score,
        "CATEGORIA_RIESGO": categoria,
        "BP_POINTS": bp_points,
        "FC_POINTS": fc_points,
        "FR_POINTS": fr_points,
        "SaO2_POINTS": sao2_points,
        "HB_POINTS": hb_points,
        "PLATELETS_POINTS": plaquetas_points,
        "CREATININE_POINTS": creat_points,
        "LIVER_POINTS": liver_points,
        "DYNAMIC_POINTS": dynamic_points,
        "COMORB_POINTS": comorb_points
    })

# --- Carga de datos y aplicación del scoring ---
input_csv_file = "datos_nuevos.csv"
output_excel_file = "datos_nuevos_con_nuevo_scoring3.xlsx"

try:
    df = pd.read_csv(input_csv_file)
except FileNotFoundError:
    print(f"Error: Archivo '{input_csv_file}' no encontrado.")
    exit()
except Exception as e:
    print(f"Error al leer el archivo CSV: {e}")
    exit()

# Aplicar la función de scoring a cada fila
scoring_df = df.apply(calcular_scoring, axis=1)
df = pd.concat([df, scoring_df], axis=1)

# Imprimir en consola la distribución de la categoría de riesgo
risk_counts = df["CATEGORIA_RIESGO"].value_counts()
print("Distribución de Categorías de Riesgo:")
print(risk_counts)

# Guardar el DataFrame resultante en un archivo Excel
try:
    df.to_excel(output_excel_file, index=False)
    print(f"\nArchivo Excel '{output_excel_file}' generado con éxito.")
except Exception as e:
    print(f"Error al guardar el archivo Excel: {e}")




# import pandas as pd
# import numpy as np

# # --- Archivo de entrada/salida (ajustar rutas) ---
# INPUT_CSV = 'datos_nuevos.csv'
# OUTPUT_XLSX = 'datos_nuevos_scoring_detallado2.xlsx'

# # --- Umbrales globales para la clasificación final ---
# UMBRAL_CRITICO = 30
# UMBRAL_SEVERO = 20
# UMBRAL_MODERADO = 10
# # (Bajo < 10)

# def calcular_puntaje_signos_vitales(row):
#     """
#     Calcula el puntaje de signos vitales con gradaciones:
#       - PAS, FC (max y min), FR, SpO2...
#     Retorna la suma de puntos (int).
#     """
#     puntos = 0

#     def safe_float(val):
#         if pd.isnull(val):
#             return np.nan
#         try:
#             return float(str(val).replace(',', '.'))
#         except:
#             return np.nan

#     # --- Tomar valores de la fila ---
#     pas_min = safe_float(row.get('PAS_ESTANCIA_MIN'))
#     fc_max = safe_float(row.get('F_CARDIACA_ESTANCIA_MAX'))
#     fc_min = safe_float(row.get('F_CARDIACA_ESTANCIA_MIN'))  # si está disponible
#     fr_max = safe_float(row.get('FR_ESTANCIA_MAX'))
#     sao2_min = safe_float(row.get('SaO2_ESTANCIA_MIN'))  # valor más bajo de saturación

#     # --- PAS con gradaciones ---
#     if not np.isnan(pas_min):
#         if pas_min < 70:
#             puntos += 10
#         elif pas_min < 80:
#             puntos += 8
#         elif pas_min < 90:
#             puntos += 6
#         elif pas_min < 100:
#             puntos += 4
#         elif pas_min < 110:
#             puntos += 2
#         # else: 0 puntos si >= 110

#     # --- Frecuencia Cardíaca (taquicardia por fc_max) ---
#     if not np.isnan(fc_max):
#         if fc_max > 150:
#             puntos += 10
#         elif fc_max > 130:
#             puntos += 8
#         elif fc_max > 120:
#             puntos += 5
#         elif fc_max > 110:
#             puntos += 3
#         # else: 0 puntos si <= 110

#     # --- Frecuencia Cardíaca (bradicardia por fc_min) ---
#     if not np.isnan(fc_min):
#         if fc_min < 40:
#             puntos += 10
#         elif fc_min < 50:
#             puntos += 8
#         elif fc_min < 60:
#             puntos += 5
#         elif fc_min < 70:
#             puntos += 3
#         # else: 0 puntos si >= 70

#     # --- Frecuencia Respiratoria (si no hay FR_MAX, usar FR_INGRESO si está) ---
#     if np.isnan(fr_max):
#         fr_max = safe_float(row.get('FR_INGRESO'))

#     if not np.isnan(fr_max):
#         if fr_max > 35:
#             puntos += 10
#         elif fr_max > 30:
#             puntos += 8
#         elif fr_max > 24:
#             puntos += 5
#         elif fr_max < 10:
#             puntos += 10  # hipoventilación grave
#         # else: 0 puntos si 10 <= FR <= 24

#     # --- SaO2 mínima ---
#     if np.isnan(sao2_min):
#         # si no hay minimo, intentar con un valor "SaO2_ESTANCIA_MAX" invertido
#         sao2_min = safe_float(row.get('SaO2_ESTANCIA_MAX'))

#     if not np.isnan(sao2_min):
#         if sao2_min < 85:
#             puntos += 10
#         elif sao2_min < 90:
#             puntos += 8
#         elif sao2_min < 93:
#             puntos += 5
#         # else: 0 puntos si >= 93

#     return puntos

# def calcular_puntaje_laboratorios(row):
#     """
#     Calcula el puntaje de laboratorio con gradaciones:
#       - Creatinina, GOT/GPT, Plaquetas, Hemoglobina...
#     Retorna la suma de puntos (int).
#     """
#     puntos = 0

#     def safe_float(val):
#         if pd.isnull(val):
#             return np.nan
#         try:
#             return float(str(val).replace(',', '.'))
#         except:
#             return np.nan

#     creat_max = safe_float(row.get('CREATININA_ESTANCIA_MAX'))
#     got_max = safe_float(row.get('GOT_max'))
#     gpt_max = safe_float(row.get('GPT_max'))
#     plt_min = safe_float(row.get('PLT_min'))
#     hb_min = safe_float(row.get('HB_min'))

#     # --- Creatinina ---
#     if not np.isnan(creat_max):
#         if creat_max > 4.0:
#             puntos += 10
#         elif creat_max > 2.0:
#             puntos += 8
#         elif creat_max > 1.5:
#             puntos += 5
#         elif creat_max > 1.2:
#             puntos += 3
#         # else: 0 puntos si <= 1.2

#     # --- GOT/GPT => tomar el peor (mayor) ---
#     transaminasa = 0
#     if not np.isnan(got_max) and got_max > transaminasa:
#         transaminasa = got_max
#     if not np.isnan(gpt_max) and gpt_max > transaminasa:
#         transaminasa = gpt_max

#     if transaminasa > 1000:
#         puntos += 10
#     elif transaminasa > 500:
#         puntos += 8
#     elif transaminasa > 100:
#         puntos += 5
#     elif transaminasa > 40:
#         puntos += 2
#     # else: 0

#     # --- Plaquetas (plt_min) ---
#     if not np.isnan(plt_min):
#         if plt_min < 20000:
#             puntos += 10
#         elif plt_min < 50000:
#             puntos += 8
#         elif plt_min < 100000:
#             puntos += 5
#         elif plt_min < 150000:
#             puntos += 3
#         # else: 0

#     # --- Hemoglobina (hb_min) ---
#     if not np.isnan(hb_min):
#         if hb_min < 6:
#             puntos += 10
#         elif hb_min < 8:
#             puntos += 8
#         elif hb_min < 10:
#             puntos += 5
#         elif hb_min < 11:
#             puntos += 3
#         # else: 0

#     return puntos

# def calcular_puntaje_eventos(row):
#     """
#     Calcula el puntaje de eventos agudos o procedimientos:
#       - Unidades transfundidas, ingreso UCI, diagnósticos críticos, etc.
#     """
#     puntos = 0

#     def safe_int(val):
#         if pd.isnull(val):
#             return np.nan
#         try:
#             return int(float(str(val).replace(',', '.')))
#         except:
#             return np.nan

#     # Ejemplo de extracción
#     transf = safe_int(row.get('UNIDADES_TRANSFUNDIDAS'))
#     uci = safe_int(row.get('INGRESO_UCI'))  # 1 = sí, 0 = no
#     uado = safe_int(row.get('INGRESO_UADO'))  # 1 = sí, 0 = no
#     rotura_uterina = safe_int(row.get('ROTURA_UTERINA'))
#     cirugia_urg_mayor = safe_int(row.get('CIRUGIA_URGENTE_MAYOR'))
#     cirugia_urg_menor = safe_int(row.get('CIRUGIA_URGENTE_MENOR'))
#     eclampsia = safe_int(row.get('DIAG_ECLAMPSIA'))
#     shock_septico = safe_int(row.get('DIAG_SHOCK_SEPTICO'))

#     # --- Transfusiones ---
#     if not np.isnan(transf):
#         if transf >= 4:
#             puntos += 10
#         elif transf >= 2:
#             puntos += 5
#         elif transf == 1:
#             puntos += 3

#     # --- Ingreso a UCI / UADO ---
#     if uci == 1:
#         puntos += 10
#     elif uado == 1:
#         puntos += 5

#     # --- Diagnósticos críticos ---
#     if rotura_uterina == 1:
#         puntos += 15
#     if eclampsia == 1:
#         puntos += 10
#     if shock_septico == 1:
#         puntos += 10

#     # --- Cirugías urgentes ---
#     if cirugia_urg_mayor == 1:
#         puntos += 8
#     elif cirugia_urg_menor == 1:
#         puntos += 5

#     return puntos

# def calcular_puntaje_comorbilidades(row):
#     """
#     Calcula el puntaje por comorbilidades crónicas o factores de riesgo basal.
#     """
#     puntos = 0

#     # Ejemplo: 1 = sí, 0 = no
#     cardiopatia = row.get('COMORB_CARDIOPATIA', 0)
#     hta_cronica = row.get('COMORB_HTA_CRONICA', 0)
#     dm_cronica = row.get('COMORB_DIABETES', 0)
#     enf_renal_cronica = row.get('COMORB_RENAL_CRONICA', 0)
#     edad = row.get('EDAD', np.nan)

#     def safe_int(val):
#         if pd.isnull(val):
#             return 0
#         try:
#             return int(float(str(val)))
#         except:
#             return 0

#     cardiopatia = safe_int(cardiopatia)
#     hta_cronica = safe_int(hta_cronica)
#     dm_cronica = safe_int(dm_cronica)
#     enf_renal_cronica = safe_int(enf_renal_cronica)

#     if cardiopatia == 1:
#         puntos += 5
#     if hta_cronica == 1:
#         puntos += 3
#     if dm_cronica == 1:
#         puntos += 3
#     if enf_renal_cronica == 1:
#         puntos += 5

#     # Edad extrema (ejemplo <18 o >40)
#     if not pd.isnull(edad):
#         try:
#             edad_val = float(edad)
#             if edad_val < 18 or edad_val > 40:
#                 puntos += 2
#         except:
#             pass

#     return puntos

# def calcular_puntos_evolucion(row):
#     """
#     Puntos extra por cambios agudos o empeoramiento de parámetros
#     entre el ingreso y la estancia.
#     Por ejemplo, si la creatinina subió >50% o la FC aumentó 40 lpm...
#     """
#     puntos = 0

#     def safe_float(val):
#         if pd.isnull(val):
#             return np.nan
#         try:
#             return float(str(val).replace(',', '.'))
#         except:
#             return np.nan

#     creat_inicial = safe_float(row.get('CREATININA_INGRESO'))
#     creat_max = safe_float(row.get('CREATININA_ESTANCIA_MAX'))
#     fc_ingreso = safe_float(row.get('F_CARDIACA_INGRESO'))
#     fc_max = safe_float(row.get('F_CARDIACA_ESTANCIA_MAX'))

#     # Ejemplo de criterio: creatinina se incrementa >50% 
#     if not np.isnan(creat_inicial) and not np.isnan(creat_max):
#         if creat_max > 1.5 * creat_inicial and creat_inicial > 0:
#             # Suma 3 puntos extra si no está ya en la categoría >2 mg/dL
#             # (Podemos omitir la condición para no complicar, o verificar)
#             if creat_max < 2.0:  
#                 puntos += 3

#     # Ejemplo de FC que sube drásticamente (40 lpm más que al ingreso)
#     if not np.isnan(fc_ingreso) and not np.isnan(fc_max):
#         if (fc_max - fc_ingreso) >= 40:
#             # Suma 3 puntos extra
#             puntos += 3

#     return puntos

# def clasificar_puntaje(total_puntos):
#     """
#     Clasifica en Bajo, Moderado, Severo, Crítico
#     según los umbrales globales.
#     """
#     if total_puntos >= UMBRAL_CRITICO:
#         return "Crítico"
#     elif total_puntos >= UMBRAL_SEVERO:
#         return "Severo"
#     elif total_puntos >= UMBRAL_MODERADO:
#         return "Moderado"
#     else:
#         return "Bajo"

# def calcular_scoring_detallado(row):
#     """
#     Función principal que invoca las sub-funciones y combina los resultados.
#     Retorna una Serie con la puntuación total y la clasificación.
#     """
#     # 1) Signos vitales
#     pts_vitales = calcular_puntaje_signos_vitales(row)

#     # 2) Laboratorios
#     pts_lab = calcular_puntaje_laboratorios(row)

#     # 3) Eventos / Procedimientos agudos
#     pts_eventos = calcular_puntaje_eventos(row)

#     # 4) Comorbilidades
#     pts_comorb = calcular_puntaje_comorbilidades(row)

#     # 5) Evolución dinámica (puntos extra)
#     pts_evolucion = calcular_puntos_evolucion(row)

#     total = pts_vitales + pts_lab + pts_eventos + pts_comorb + pts_evolucion
#     nivel_riesgo = clasificar_puntaje(total)

#     return pd.Series({
#         'PUNTAJE_SIGNOS': pts_vitales,
#         'PUNTAJE_LAB': pts_lab,
#         'PUNTAJE_EVENTOS': pts_eventos,
#         'PUNTAJE_COMORB': pts_comorb,
#         'PUNTAJE_EVOLUCION': pts_evolucion,
#         'PUNTAJE_TOTAL': total,
#         'NIVEL_RIESGO': nivel_riesgo
#     })

# # --- Lectura del CSV y aplicación de la lógica ---
# def main():
#     try:
#         df = pd.read_csv(INPUT_CSV)
#     except FileNotFoundError:
#         print(f"Error: Archivo '{INPUT_CSV}' no encontrado.")
#         return
#     except Exception as e:
#         print(f"Error al leer el archivo CSV: {e}")
#         return

#     # Aplicar la función de scoring detallado por fila
#     scoring_df = df.apply(calcular_scoring_detallado, axis=1)

#     # Unir columnas
#     df_result = pd.concat([df, scoring_df], axis=1)

#     # Guardar en Excel
#     try:
#         df_result.to_excel(OUTPUT_XLSX, index=False)
#         print(f"Archivo '{OUTPUT_XLSX}' generado con éxito.")
#         print("Distribución de Niveles de Riesgo:")
#         print(df_result['NIVEL_RIESGO'].value_counts())
#     except Exception as e:
#         print(f"Error al guardar el archivo Excel: {e}")

# if __name__ == '__main__':
#     main()





# import pandas as pd
# import numpy as np

# # Funciones de conversión seguras para evitar errores con valores nulos o mal formateados
# def safe_float_conversion(value):
#     if pd.isnull(value):
#         return np.nan
#     try:
#         return float(str(value).replace(',', '.'))
#     except (ValueError, TypeError):
#         return np.nan

# # Función para calcular el score de riesgo dinámico y clasificar en 4 niveles:
# # Bajo, Moderado, Severo y Crítico.
# def calcular_riesgo_dinamico(row):
#     score = 0

#     # ---------------------------
#     # 1. Signos Vitales
#     # ---------------------------
#     # Presión Arterial Sistólica (PAS) y Diastólica (PAD)
#     pas_current = safe_float_conversion(row.get('PAS_CURRENT'))
#     pas_previous = safe_float_conversion(row.get('PAS_PREVIOUS'))
#     pad_current = safe_float_conversion(row.get('PAD_CURRENT'))
#     pad_previous = safe_float_conversion(row.get('PAD_PREVIOUS'))
    
#     # Evaluación de hipotensión:
#     # - Si PAS < 70 o PAD < 40 se considera hipotensión severa (shock): 4 puntos.
#     #   Además, si existe un descenso mayor a 10 mmHg respecto al valor previo se añade 1 punto extra por cada medida.
#     # - Si no se cumple el criterio severo, pero PAS < 90 o PAD < 60 se considera moderada: 2 puntos (+ bonus si empeora).
#     hipotension_severe = False
#     if (not np.isnan(pas_current) and pas_current < 70) or (not np.isnan(pad_current) and pad_current < 40):
#         score += 4
#         hipotension_severe = True
#         if not np.isnan(pas_previous) and pas_current < pas_previous - 10:
#             score += 1
#         if not np.isnan(pad_previous) and pad_current < pad_previous - 10:
#             score += 1
#     else:
#         if (not np.isnan(pas_current) and pas_current < 90) or (not np.isnan(pad_current) and pad_current < 60):
#             score += 2
#             if not np.isnan(pas_previous) and pas_current < pas_previous - 10:
#                 score += 1
#             if not np.isnan(pad_previous) and pad_current < pad_previous - 10:
#                 score += 1

#     # Frecuencia Cardiaca (FC)
#     fc_current = safe_float_conversion(row.get('FC_CURRENT'))
#     fc_previous = safe_float_conversion(row.get('FC_PREVIOUS'))
#     if not np.isnan(fc_current):
#         # Taquicardia: 2 puntos si >120, 4 puntos si >140
#         if fc_current > 140:
#             score += 4
#         elif fc_current > 120:
#             score += 2
#         # Bonus dinámico: si FC aumenta más de un 10% respecto al valor previo
#         if not np.isnan(fc_previous) and fc_current > fc_previous * 1.10:
#             score += 1
#         # Bradycardia: 2 puntos si <50, 4 puntos si <40
#         if fc_current < 40:
#             score += 4
#         elif fc_current < 50:
#             score += 2

#     # Frecuencia Respiratoria (FR)
#     fr_current = safe_float_conversion(row.get('FR_CURRENT'))
#     fr_previous = safe_float_conversion(row.get('FR_PREVIOUS'))
#     if not np.isnan(fr_current):
#         # Si FR >30 o <10 se considera grave: 3 puntos;
#         # Si está por encima de 20 se añaden 1 punto.
#         if fr_current > 30 or fr_current < 10:
#             score += 3
#         elif fr_current > 20:
#             score += 1
#         # Bonus dinámico si hay un cambio mayor a 5 rpm respecto al valor previo
#         if not np.isnan(fr_previous) and abs(fr_current - fr_previous) > 5:
#             score += 1

#     # Saturación de Oxígeno (SaO2)
#     sao2_current = safe_float_conversion(row.get('SaO2_CURRENT'))
#     sao2_previous = safe_float_conversion(row.get('SaO2_PREVIOUS'))
#     if not np.isnan(sao2_current):
#         # Si SaO2 < 90: 3 puntos; si <92: 1 punto.
#         if sao2_current < 90:
#             score += 3
#         elif sao2_current < 92:
#             score += 1
#         # Bonus dinámico si hay un descenso mayor a 5% respecto al valor previo
#         if not np.isnan(sao2_previous) and (sao2_previous - sao2_current) > 5:
#             score += 1

#     # ---------------------------
#     # 2. Laboratorio
#     # ---------------------------
#     # Hemoglobina
#     hb_current = safe_float_conversion(row.get('HEMOGLOBINA_CURRENT'))
#     hb_previous = safe_float_conversion(row.get('HEMOGLOBINA_PREVIOUS'))
#     if not np.isnan(hb_current):
#         if hb_current < 7:
#             score += 4
#         elif hb_current < 8:
#             score += 2
#         if not np.isnan(hb_previous) and (hb_previous - hb_current) > 1:
#             score += 1

#     # Recuento de Plaquetas
#     plt_current = safe_float_conversion(row.get('PLT_CURRENT'))
#     plt_previous = safe_float_conversion(row.get('PLT_PREVIOUS'))
#     if not np.isnan(plt_current):
#         if plt_current < 50000:
#             score += 3
#         elif plt_current < 100000:
#             score += 1

#     # Creatinina
#     creat_current = safe_float_conversion(row.get('CREATININA_CURRENT'))
#     creat_previous = safe_float_conversion(row.get('CREATININA_PREVIOUS'))
#     if not np.isnan(creat_current):
#         if creat_current > 2.0:
#             score += 4
#         elif creat_current > 1.4:
#             score += 2
#         elif creat_current > 1.2:
#             score += 1
#         if not np.isnan(creat_previous) and (creat_current - creat_previous) > 0.5:
#             score += 1

#     # Transaminasas (GPT y GOT): se evalúa el máximo de ambos
#     gpt_current = safe_float_conversion(row.get('GPT_CURRENT'))
#     got_current = safe_float_conversion(row.get('GOT_CURRENT'))
#     gpt_previous = safe_float_conversion(row.get('GPT_PREVIOUS'))
#     got_previous = safe_float_conversion(row.get('GOT_PREVIOUS'))
#     liver_current = np.nan
#     liver_previous = np.nan
#     if not np.isnan(gpt_current) or not np.isnan(got_current):
#         liver_current = max(gpt_current if not np.isnan(gpt_current) else 0,
#                             got_current if not np.isnan(got_current) else 0)
#     if not np.isnan(gpt_previous) or not np.isnan(got_previous):
#         liver_previous = max(gpt_previous if not np.isnan(gpt_previous) else 0,
#                              got_previous if not np.isnan(got_previous) else 0)
#     if not np.isnan(liver_current):
#         if liver_current > 150:
#             score += 3
#         elif liver_current > 80:
#             score += 1
#         if not np.isnan(liver_previous) and (liver_current - liver_previous) > 50:
#             score += 1

#     # ---------------------------
#     # 3. Factores Procedimentales y de Ingreso
#     # ---------------------------
#     # Ingreso a UCI (valor esperado: 1 = Sí)
#     uci = str(row.get('UCI', '')).strip().lower()
#     if uci in ['1', 'true', 'si', 'sí']:
#         score += 5

#     # Transfusiones (unidades)
#     transf = safe_float_conversion(row.get('TRANSFUSIONES'))
#     if not np.isnan(transf):
#         if transf >= 4:
#             score += 3
#         elif transf > 0:
#             score += 1

#     # ---------------------------
#     # 4. Comorbilidades (factores de riesgo crónicos)
#     # Se espera que la columna 'COMORBIDADES' contenga una lista separada por comas.
#     # Cada comorbilidad de alto riesgo añade 1 punto.
#     # Ejemplos: diabetes, hipertensión, cardiopatía, enfermedad renal, enfermedad hepática, obesidad.
#     comorb_str = str(row.get('COMORBIDADES', '')).lower()
#     comorb_list = ['diabetes', 'hipertension', 'cardiopatia', 'enfermedad renal', 'enfermedad hepática', 'obesidad']
#     for comorb in comorb_list:
#         if comorb in comorb_str:
#             score += 1

#     # ---------------------------
#     # 5. Evaluación Dinámica Global
#     # Bonus adicional si existe un descenso global importante en los signos vitales (por ejemplo, presión arterial).
#     bp_drop = 0
#     if not np.isnan(pas_previous) and not np.isnan(pas_current):
#         bp_drop += (pas_previous - pas_current)
#     if not np.isnan(pad_previous) and not np.isnan(pad_current):
#         bp_drop += (pad_previous - pad_current)
#     if bp_drop > 20:
#         score += 1

#     # ---------------------------
#     # 6. Clasificación Final del Riesgo
#     # Se definen los siguientes umbrales:
#     #   - Bajo:   score < 5
#     #   - Moderado: score entre 5 y 9
#     #   - Severo: score entre 10 y 14
#     #   - Crítico: score >= 15
#     if score < 5:
#         category = "Bajo"
#     elif score < 10:
#         category = "Moderado"
#     elif score < 15:
#         category = "Severo"
#     else:
#         category = "Crítico"

#     return pd.Series({'SCORE': score, 'RISK_CATEGORY': category})

# # ---------------------------
# # PROCESAMIENTO DEL ARCHIVO DE DATOS
# # ---------------------------
# input_csv = 'datos_nuevos.csv'
# output_excel = 'datos_nuevos_con_riesgo_dinamico.xlsx'

# # Cargar el CSV (se esperan columnas con sufijos _CURRENT y _PREVIOUS para evaluar evolución)
# try:
#     df = pd.read_csv(input_csv)
# except Exception as e:
#     print(f"Error al leer el archivo CSV: {e}")
#     exit()

# # Aplicar la función de scoring dinámico a cada fila
# risk_df = df.apply(calcular_riesgo_dinamico, axis=1)
# df = pd.concat([df, risk_df], axis=1)

# # Exportar el DataFrame a un archivo Excel
# try:
#     df.to_excel(output_excel, index=False)
#     print(f"Archivo Excel '{output_excel}' generado exitosamente con las columnas 'SCORE' y 'RISK_CATEGORY'.")
# except Exception as e:
#     print(f"Error al guardar el archivo Excel: {e}")




# import pandas as pd
# import numpy as np

# # -----------------------------
# # Configuración de archivos
# # -----------------------------
# INPUT_CSV = "datos_nuevos.csv"
# OUTPUT_EXCEL = "datos_nuevos_con_riesgo_avanzado2.xlsx"

# # -----------------------------
# # Funciones auxiliares
# # -----------------------------
# def safe_float(value):
#     """Convierte de forma segura un valor a float, o NaN si no es posible."""
#     try:
#         if pd.isna(value):
#             return np.nan
#         return float(str(value).replace(',', '.'))
#     except:
#         return np.nan

# def safe_int(value):
#     """Convierte de forma segura un valor a int, o NaN si no es posible."""
#     val = safe_float(value)
#     if np.isnan(val):
#         return np.nan
#     return int(val)

# # -----------------------------
# # Función principal de scoring
# # -----------------------------
# def calcular_riesgo_avanzado(row):
#     """
#     Calcula un puntaje de riesgo basado en múltiples factores:
#       - Signos vitales con gradaciones
#       - Laboratorios con niveles extremos
#       - Evolución dinámica
#       - Comorbilidades
#       - Procedimientos críticos
#     Retorna un diccionario o Series con SCORE y NIVEL_RIESGO.
#     """

#     # --- 1. Leer valores relevantes ---
#     # Ejemplo: valores de ingreso y de estancia para ver la evolución.
#     pas_min = safe_float(row.get('PAS_ESTANCIA_MIN'))
#     pad_min = safe_float(row.get('PAD_ESTANCIA_MIN'))

#     # FC máxima y mínima durante la estancia:
#     fc_max = safe_float(row.get('F_CARDIACA_ESTANCIA_MAX'))
#     fc_min = safe_float(row.get('F_CARDIACA_ESTANCIA_MIN'))

#     fr_max = safe_float(row.get('F_RESPIRATORIA_ESTANCIA_MAX'))
#     sao2_min = safe_float(row.get('SaO2_ESTANCIA_MIN'))  # se podría usar el más bajo en estancia

#     # Laboratorios en ingreso y estancia:
#     crea_ingreso = safe_float(row.get('CREATININA_INGRESO'))
#     crea_max = safe_float(row.get('CREATININA_ESTANCIA_MAX'))

#     got_max = safe_float(row.get('GOT_Aspartato_aminotransferasa_max'))
#     gpt_max = safe_float(row.get('GPT_INGRESO'))  # o GPT máx en estancia si está disponible

#     hb_ingreso = safe_float(row.get('HEMOGLOBINA_INGRESO'))
#     hb_min = safe_float(row.get('HEMOGLOBINA_ESTANCIA_MIN'))

#     plt_min = safe_float(row.get('PLT_ESTANCIA_MIN'))  # recuento de plaquetas mínimo

#     # Procedimientos / Eventos
#     rotura_uterina = safe_int(row.get('WAOS_Rotura_uterina'))
#     ingreso_uci = safe_int(row.get('Ingreso_UCI'))
#     cirugia_emergente = safe_int(row.get('Cirugia_no_programada'))
#     unidades_trans = safe_int(row.get('UNIDADES_TRANSFUNDIDAS'))
#     consciencia = str(row.get('CONSCIENCIA', '')).strip().lower()  # "alerta", "no alerta", etc.

#     # Comorbilidades
#     # Supongamos que el dataset tenga columnas booleanas (1/0) para hipertension_cronica, diabetes, etc.
#     hta_cronica = safe_int(row.get('HTA_CRONICA'))
#     dm_pre = safe_int(row.get('DIABETES'))
#     cardiopatia = safe_int(row.get('CARDIOPATIA'))
#     enf_renal_cronica = safe_int(row.get('ENF_RENAL_CRONICA'))
#     edad = safe_float(row.get('EDAD'))

#     # -----------------------------
#     # 2. Comenzar puntuación
#     # -----------------------------
#     score = 0

#     # A) Eventos críticos directos
#     if rotura_uterina == 1:
#         score += 20  # Rotura uterina => directamente muy alto
#     if ingreso_uci == 1:
#         score += 15
#     if cirugia_emergente == 1:
#         score += 6

#     # B) Signos Vitales (evitando duplicaciones)
#     #  - Presión Arterial
#     if not np.isnan(pas_min) and not np.isnan(pad_min):
#         if pas_min < 70 or pad_min < 40:
#             score += 15  # Shock extremo
#         elif pas_min < 90 or pad_min < 60:
#             score += 10  # Shock severo
#         elif pas_min < 100 or pad_min < 70:
#             score += 5   # Hipotensión moderada

#     #  - Frecuencia Cardíaca (consideramos fc_max y fc_min)
#     #    Podríamos priorizar la peor anormalidad (taquicardia extrema vs bradicardia severa).
#     if not np.isnan(fc_max):
#         if fc_max > 140:
#             score += 12
#         elif fc_max > 130:
#             score += 8
#         elif fc_max > 120:
#             score += 3

#     if not np.isnan(fc_min):
#         if fc_min < 40:
#             score += 10
#         elif fc_min < 50:
#             score += 5

#     #  - Frecuencia Respiratoria
#     if not np.isnan(fr_max):
#         if fr_max > 35:
#             score += 10
#         elif fr_max > 25:
#             score += 6
#         # Podríamos chequear FR muy baja en otra variable (p. ej. FR mínima)

#     #  - SaO2 mínima
#     if not np.isnan(sao2_min):
#         if sao2_min < 85:
#             score += 12
#         elif sao2_min < 90:
#             score += 8
#         elif sao2_min < 93:
#             score += 4

#     #  - Estado de consciencia
#     if consciencia == "no alerta":
#         score += 15

#     # C) Laboratorios con gradaciones
#     #    1) Creatinina
#     if not np.isnan(crea_max):
#         if crea_max > 4.0:
#             score += 12
#         elif crea_max > 2.0:
#             score += 8
#         elif crea_max > 1.4:
#             score += 4

#     #    Comparación dinámica creatinina (vs. ingreso)
#     if not np.isnan(crea_ingreso) and not np.isnan(crea_max):
#         if (crea_max - crea_ingreso) > 1.0:
#             score += 3  # Empeoramiento notable

#     #    2) Transaminasas (tomar el mayor de GOT o GPT)
#     trans_max = 0
#     if not np.isnan(got_max):
#         trans_max = max(trans_max, got_max)
#     if not np.isnan(gpt_max):
#         trans_max = max(trans_max, gpt_max)

#     if trans_max > 1000:
#         score += 10
#     elif trans_max > 500:
#         score += 7
#     elif trans_max > 100:
#         score += 4

#     #    3) Hemoglobina
#     final_hb = hb_min if not np.isnan(hb_min) else hb_ingreso
#     if not np.isnan(final_hb):
#         if final_hb < 6:
#             score += 10
#         elif final_hb < 7:
#             score += 8
#         elif final_hb < 8:
#             score += 4

#     # Comparación dinámica de Hemoglobina
#     if not np.isnan(hb_ingreso) and not np.isnan(hb_min):
#         if (hb_ingreso - hb_min) > 3.0:
#             score += 2  # caída significativa

#     #    4) Plaquetas
#     if not np.isnan(plt_min):
#         if plt_min < 20000:
#             score += 10
#         elif plt_min < 50000:
#             score += 7
#         elif plt_min < 100000:
#             score += 4

#     # D) Transfusiones
#     if not np.isnan(unidades_trans):
#         if unidades_trans >= 4:
#             score += 10
#         elif unidades_trans >= 2:
#             score += 5

#     # E) Comorbilidades
#     comorb_count = 0
#     if hta_cronica == 1:
#         score += 2
#         comorb_count += 1
#     if dm_pre == 1:
#         score += 2
#         comorb_count += 1
#     if cardiopatia == 1:
#         score += 4
#         comorb_count += 1
#     if enf_renal_cronica == 1:
#         score += 4
#         comorb_count += 1

#     # Ejemplo de bonus por >= 2 comorbilidades
#     if comorb_count >= 2:
#         score += 2

#     # Edad
#     if not np.isnan(edad) and (edad < 20 or edad > 40):
#         score += 1

#     # -----------------------------
#     # 3. Clasificación Final
#     # -----------------------------
#     if score >= 30:
#         nivel = "Crítico"
#     elif score >= 20:
#         nivel = "Severo"
#     elif score >= 10:
#         nivel = "Moderado"
#     else:
#         nivel = "Bajo"

#     return pd.Series({"SCORE_AVANZADO": score, "NIVEL_RIESGO_AVANZADO": nivel})


# # -----------------------------
# # Lógica principal de ejecución
# # -----------------------------
# if __name__ == "__main__":
#     try:
#         df = pd.read_csv(INPUT_CSV)
#     except FileNotFoundError:
#         print(f"No se encontró el archivo {INPUT_CSV}")
#         exit()
#     except Exception as e:
#         print(f"Error al leer CSV: {e}")
#         exit()

#     # Aplicar la función de scoring a cada fila
#     riesgo_df = df.apply(calcular_riesgo_avanzado, axis=1)
#     df = pd.concat([df, riesgo_df], axis=1)

#     # Guardar resultado en Excel
#     try:
#         df.to_excel(OUTPUT_EXCEL, index=False)
#         print(f"Archivo '{OUTPUT_EXCEL}' generado con las columnas 'SCORE_AVANZADO' y 'NIVEL_RIESGO_AVANZADO'.")
#         print("\nDistribución de niveles de riesgo:")
#         print(df["NIVEL_RIESGO_AVANZADO"].value_counts())
#     except Exception as e:
#         print(f"Error al guardar Excel: {e}")




# import pandas as pd
# import numpy as np

# # --- Configuración ---
# input_csv_file = 'datos_nuevos.csv'
# output_excel_file = 'datos_nuevos_con_scoring_avanzado.xlsx'

# # --- Definir rangos y puntajes en un diccionario estructurado ---

# # Ejemplo: {"parametro": [(rango1, puntaje1, "label"), (rango2, puntaje2, "label"), ...]}
# # Se ordenan los rangos de mayor a menor severidad para, si se cumple uno alto, no duplicar.
# SIGNOS_VITALES_PUNTOS = {
#     "PAS": [
#         ((None, 70), 10, "hipotension_severa"),         # <70
#         ((70, 90), 5, "hipotension_moderada")           # 70 <= PAS < 90
#     ],
#     "PAD": [
#         ((None, 40), 10, "pad_severa"),                # <40
#         ((40, 60), 5, "pad_moderada")                  # 40 <= PAD < 60
#     ],
#     "FC": [
#         ((None, 40), 10, "bradicardia_severa"),        # <40
#         ((40, 50), 5, "bradicardia_moderada"),         # 40 <= FC < 50
#         ((150, None), 10, "taquicardia_extrema"),      # >150
#         ((130, 150), 8, "taquicardia_severa"),         # 130 < FC <= 150
#         ((120, 130), 5, "taquicardia_moderada"),       # 120 < FC <= 130
#         ((100, 120), 3, "taquicardia_leve"),           # 100 < FC <= 120
#     ],
#     "FR": [
#         ((None, 10), 10, "hipoventilacion_severa"),    # <10
#         ((30, None), 8, "taquipnea_severa"),           # >30
#         ((25, 30), 4, "taquipnea_moderada"),           # 25 <= FR <= 30
#         ((20, 25), 2, "taquipnea_leve"),               # 20 <= FR < 25
#     ],
#     "SaO2": [
#         ((None, 85), 8, "hipoxemia_severa"),           # <85
#         ((85, 90), 5, "hipoxemia_moderada"),           # 85 <= SaO2 < 90
#         ((90, 93), 3, "hipoxemia_leve"),               # 90 <= SaO2 < 93
#     ]
# }

# LABS_PUNTOS = {
#     "HEMOGLOBINA": [
#         ((None, 7), 6, "hb_severa"),                   # <7
#         ((7, 8), 3, "hb_moderada")                     # 7 <= HB < 8
#     ],
#     "PLAQUETAS": [
#         ((None, 50000), 8, "plaquetopenia_severa"),    # <50k
#         ((50000, 100000), 4, "plaquetopenia_moderada") # 50k <= plt < 100k
#     ],
#     "CREATININA": [
#         ((3.0, None), 10, "renal_extrema"),            # >3
#         ((2.0, 3.0), 8, "renal_severa"),               # 2 - 3
#         ((1.3, 2.0), 4, "renal_moderada"),             # 1.3 - 2
#     ],
#     "TRANSAMINASAS": [ # Se puede aplicar a GPT o GOT, se usará el valor mayor
#         ((2000, None), 12, "hep_extrema"),             # >2000
#         ((500, 2000), 8, "hep_severa"),                # 501 - 2000
#         ((100, 500), 4, "hep_moderada"),               # 101 - 500
#     ]
# }

# # Comorbilidades y factores crónicos
# COMORBIDIDADES_PUNTOS = {
#     "INSUF_CARDIACA_NYHA4": 6,
#     "INSUF_CARDIACA_NYHA3": 4,
#     "ERC_Estadio4_5": 4,
#     "DIABETES_NO_CONTROLADA": 3,
#     "EDAD_EXTREMA": 2,
#     # etc...
# }

# # Procedimientos / factores críticos
# FACTORES_CRITICOS = {
#     "ROTURA_UTERINA": 20,
#     "INGRESO_UCI": 15,
#     "TRANSFUSION_MASIVA": 10,  # >=4 uds
#     "CIRUGIA_EMERGENCIA": 8,
#     "ECLAMPSIA": 10
# }

# # Evolución dinámica: asignamos puntos adicionales si hay incrementos marcados
# def calcular_puntos_evolucion(ultima_medicion, medicion_actual, delta_posible):
#     """
#     Por ejemplo: si la creatinina sube >0.5 mg/dL en 24 h => +2 puntos
#     Este ejemplo se puede expandir a más parámetros o más condiciones.
#     """
#     puntos = 0
#     if not np.isnan(ultima_medicion) and not np.isnan(medicion_actual):
#         delta = medicion_actual - ultima_medicion
#         if delta >= 0.5:
#             puntos += 2  # Ejemplo
#         elif delta >= 0.3:
#             puntos += 1
#     return puntos

# # --- Funciones auxiliares ---

# def safe_float(value):
#     try:
#         if pd.isna(value):
#             return np.nan
#         return float(str(value).replace(",", "."))
#     except:
#         return np.nan

# def obtener_puntaje_rango(valor, rango_list):
#     """
#     Dada una lista de tuplas: [((low, high), puntos, label), ...]
#     donde (None, x) significa < x, (x, None) significa > x,
#     retorna el puntaje correspondiente al primer rango que cumpla.
#     Si no cumple ningún rango, retorna 0.
#     """
#     if np.isnan(valor):
#         return 0, None  # sin puntaje

#     for (limits, pts, label) in rango_list:
#         low, high = limits
#         # low = None => no hay límite inferior
#         # high = None => no hay límite superior
#         if low is None and valor < high:
#             return pts, label
#         elif high is None and valor > low:
#             return pts, label
#         elif low is not None and high is not None and (low < valor <= high):
#             return pts, label
#     return 0, None

# def calcular_scoring_fila(row):
#     """
#     Calcula la puntuación de riesgo para una fila/paciente, integrando:
#       - Signos vitales (rango escalonado).
#       - Laboratorios (rango escalonado).
#       - Comorbilidades (puntos fijos).
#       - Procedimientos / desenlaces críticos.
#       - Evolución dinámica (comparar con columnas de valores previos).
#     Evita duplicar puntajes si se cumple un criterio más severo.
#     """
#     score_total = 0

#     # --- 1. Signos vitales ---
#     pas_min = safe_float(row.get("PAS_ESTANCIA_MIN"))
#     pad_min = safe_float(row.get("PAD_ESTANCIA_MIN"))
#     fc_max = safe_float(row.get("FRECUENCIA_CARDIACA_ESTANCIA_MAX"))
#     fr_max = safe_float(row.get("F_RESPIRATORIA_ESTANCIA_MAX"))
#     sao2_min = safe_float(row.get("SaO2_ESTANCIA_MIN"))  # O el que corresponda

#     # PAS
#     puntos_pas, label_pas = obtener_puntaje_rango(pas_min, SIGNOS_VITALES_PUNTOS["PAS"])
#     score_total += puntos_pas
#     # PAD
#     puntos_pad, label_pad = obtener_puntaje_rango(pad_min, SIGNOS_VITALES_PUNTOS["PAD"])
#     # Regla: si ya hubo "hipotensión severa" por PAS, no sumamos PAD severa
#     # (para no duplicar la misma causa de choque). Ajustable.
#     if not (label_pas == "hipotension_severa" and label_pad == "pad_severa"):
#         score_total += puntos_pad

#     # FC
#     puntos_fc, label_fc = obtener_puntaje_rango(fc_max, SIGNOS_VITALES_PUNTOS["FC"])
#     score_total += puntos_fc

#     # FR
#     puntos_fr, label_fr = obtener_puntaje_rango(fr_max, SIGNOS_VITALES_PUNTOS["FR"])
#     score_total += puntos_fr

#     # SaO2
#     puntos_sao2, label_sao2 = obtener_puntaje_rango(sao2_min, SIGNOS_VITALES_PUNTOS["SaO2"])
#     score_total += puntos_sao2

#     # --- 2. Laboratorios ---
#     hb_min = safe_float(row.get("HEMOGLOBINA_ESTANCIA_MIN"))
#     plt_min = safe_float(row.get("PLAQUETAS_ESTANCIA_MIN"))
#     crea_max = safe_float(row.get("CREATININA_ESTANCIA_MAX"))
#     got_max = safe_float(row.get("GOT_MAX"))
#     gpt_max = safe_float(row.get("GPT_MAX"))

#     puntos_hb, label_hb = obtener_puntaje_rango(hb_min, LABS_PUNTOS["HEMOGLOBINA"])
#     score_total += puntos_hb

#     puntos_plt, label_plt = obtener_puntaje_rango(plt_min, LABS_PUNTOS["PLAQUETAS"])
#     score_total += puntos_plt

#     puntos_crea, label_crea = obtener_puntaje_rango(crea_max, LABS_PUNTOS["CREATININA"])
#     score_total += puntos_crea

#     # Tomar la transaminasa mayor para clasificar severidad
#     trans_mayor = np.nanmax([got_max, gpt_max])
#     puntos_hep, label_hep = obtener_puntaje_rango(trans_mayor, LABS_PUNTOS["TRANSAMINASAS"])
#     score_total += puntos_hep

#     # --- 3. Comorbilidades ---
#     # Suponiendo que se tenga una columna booleana o algo similar
#     # Por ejemplo: 'COMORB_CARDIOPATIA' == 1 => NYHA III
#     if row.get("INSUF_CARDIACA_NYHA4", 0) == 1:
#         score_total += COMORBIDIDADES_PUNTOS["INSUF_CARDIACA_NYHA4"]
#     if row.get("INSUF_CARDIACA_NYHA3", 0) == 1:
#         score_total += COMORBIDIDADES_PUNTOS["INSUF_CARDIACA_NYHA3"]
#     # etc. (adaptar a la disponibilidad real)

#     # --- 4. Procedimientos / desenlaces críticos ---
#     if row.get("ROTURA_UTERINA", 0) == 1:
#         score_total += FACTORES_CRITICOS["ROTURA_UTERINA"]
#     if row.get("INGRESO_UCI", 0) == 1:
#         score_total += FACTORES_CRITICOS["INGRESO_UCI"]
#     # Ejemplo transfusión
#     transfundidas = safe_float(row.get("UNIDADES_TRANSFUNDIDAS"))
#     if not np.isnan(transfundidas):
#         if transfundidas >= 4:
#             score_total += FACTORES_CRITICOS["TRANSFUSION_MASIVA"]
#     # etc...

#     # --- 5. Evolución dinámica (ejemplo con creatinina) ---
#     crea_previa = safe_float(row.get("CREATININA_PREVIA"))  # Basal o hace 24h
#     score_total += calcular_puntos_evolucion(crea_previa, crea_max, delta_posible=0.5)

#     # Aquí podrían agregarse más comparaciones para FC, plaquetas, etc.

#     # --- 6. Clasificación final (umbrales de ejemplo) ---
#     if score_total >= 25:
#         nivel = "Alto"
#     elif score_total >= 10:
#         nivel = "Moderado"
#     else:
#         nivel = "Bajo"

#     return pd.Series({"PUNTAJE_AVANZADO": score_total, "NIVEL_RIESGO": nivel})


# def main():
#     try:
#         df = pd.read_csv(input_csv_file)
#     except FileNotFoundError:
#         print(f"Error: Archivo '{input_csv_file}' no encontrado.")
#         return
#     except Exception as e:
#         print(f"Error al leer el archivo CSV: {e}")
#         return

#     # Aplicar función
#     resultado_df = df.apply(calcular_scoring_fila, axis=1)
#     df = pd.concat([df, resultado_df], axis=1)

#     # Guardar
#     try:
#         df.to_excel(output_excel_file, index=False)
#         print(f"Archivo '{output_excel_file}' guardado con éxito.")
#         print("Distribución de Niveles de Riesgo:")
#         print(df['NIVEL_RIESGO'].value_counts())
#     except Exception as e:
#         print(f"Error al guardar el archivo Excel: {e}")


# if __name__ == "__main__":
#     main()




# import pandas as pd
# import numpy as np

# # Función para evaluar el nivel de riesgo según los parámetros definidos
# def calcular_nivel_riesgo(row):
#     score = 0

#     # --- Signos Vitales ---
#     # Presión Arterial Sistólica al ingreso/alta
#     try:
#         if pd.notna(row['PAS_INGRESO_ALTA']) and row['PAS_INGRESO_ALTA'] < 90:
#             score += 1
#     except Exception:
#         pass

#     # Presión Arterial Diastólica
#     try:
#         if pd.notna(row['PAD_INGRESO_BAJA']) and row['PAD_INGRESO_BAJA'] < 60:
#             score += 1
#     except Exception:
#         pass

#     # Frecuencia cardiaca
#     try:
#         if pd.notna(row['FRECUENCIA_CARDIACA_INGRESO_ALTA']) and row['FRECUENCIA_CARDIACA_INGRESO_ALTA'] > 120:
#             score += 1
#     except Exception:
#         pass

#     # Frecuencia respiratoria
#     try:
#         if pd.notna(row['F_RESPIRATORIA_INGRESO_ALTA']) and row['F_RESPIRATORIA_INGRESO_ALTA'] > 20:
#             score += 1
#     except Exception:
#         pass

#     # Saturación de oxígeno
#     try:
#         if pd.notna(row['SaO2_ESTANCIA_MAX']) and row['SaO2_ESTANCIA_MAX'] < 92:
#             score += 1
#     except Exception:
#         pass

#     # --- Parámetros de Laboratorio ---
#     # Hemoglobina
#     try:
#         if pd.notna(row['HEMOGLOBINA_INGRESO']) and row['HEMOGLOBINA_INGRESO'] < 7:
#             score += 1
#     except Exception:
#         pass

#     # Recuento de plaquetas
#     try:
#         if pd.notna(row['Recuento_de_plaquetas_-_PLT___min']):
#             if row['Recuento_de_plaquetas_-_PLT___min'] < 50000:
#                 score += 2  # Muy bajo: mayor riesgo
#             elif row['Recuento_de_plaquetas_-_PLT___min'] < 100000:
#                 score += 1
#     except Exception:
#         pass

#     # Creatinina
#     try:
#         if pd.notna(row['CREATININA_INGRESO']) and row['CREATININA_INGRESO'] > 1.4:
#             score += 1
#     except Exception:
#         pass

#     # GPT (ALT)
#     try:
#         if pd.notna(row['GPT_INGRESO']) and row['GPT_INGRESO'] > 70:
#             score += 1
#     except Exception:
#         pass

#     # GOT (AST)
#     try:
#         if pd.notna(row['GOT_Aspartato_aminotransferasa_max']) and row['GOT_Aspartato_aminotransferasa_max'] > 70:
#             score += 1
#     except Exception:
#         pass

#     # --- Diagnósticos e Intervenciones ---
#     def check_categ(val):
#         if pd.isna(val):
#             return False
#         val_str = str(val).strip().lower()
#         return val_str in ['si', 'sí', '1', 'true']

#     try:
#         if check_categ(row['DIAG_PRINCIPAL_HEMORRAGIA']):
#             score += 1
#     except Exception:
#         pass

#     try:
#         if check_categ(row['DIAG_PRINCIPAL_THE']):
#             score += 1
#     except Exception:
#         pass

#     try:
#         if check_categ(row['WAOS_Rotura_uterina_durante_el_parto']):
#             score += 1
#     except Exception:
#         pass

#     try:
#         if check_categ(row['WAOS_laceracion_perineal_de_3er_o_4to_grado']):
#             score += 1
#     except Exception:
#         pass

#     try:
#         if check_categ(row['MANEJO_ESPECIFICO_Ingreso_a_UCI']):
#             score += 1
#     except Exception:
#         pass

#     try:
#         if pd.notna(row['UNIDADES_TRANSFUNDIDAS']) and row['UNIDADES_TRANSFUNDIDAS'] > 2:
#             score += 1
#     except Exception:
#         pass

#     # --- Determinar el nivel de riesgo basado en la puntuación acumulada ---
#     if score >= 4:
#         return "alto"
#     elif score >= 2:
#         return "moderado"
#     else:
#         return "bajo"

# # Leer el archivo CSV con los datos nuevos
# df = pd.read_csv("datos_nuevos.csv", encoding="utf-8", sep=",")

# # Aplicar la función para calcular el nivel de riesgo y crear la nueva columna
# df['nivel_riesgo'] = df.apply(calcular_nivel_riesgo, axis=1)

# # Guardar el DataFrame modificado en un archivo XLSX
# archivo_salida = "datos_nuevos_con_riesgo2.xlsx"
# df.to_excel(archivo_salida, index=False)

# print(f"El archivo '{archivo_salida}' ha sido generado con la columna 'nivel_riesgo'.")




# import pandas as pd
# import numpy as np

# # Leer el archivo CSV con los datos nuevos
# df = pd.read_csv("datos_nuevos.csv")

# def calcular_riesgo(row):
#     """
#     Función para calcular el puntaje de riesgo y asignar un nivel de riesgo:
#     - Si el puntaje es >= 6, se clasifica como "Alto"
#     - Si el puntaje es entre 3 y 5, se clasifica como "Moderado"
#     - Si el puntaje es < 3, se clasifica como "Bajo"
    
#     Se evalúan los siguientes parámetros:
#       * Signos vitales:
#           - PAS_INGRESO_ALTA: < 90 mmHg añade 2 puntos.
#           - PAD_INGRESO_BAJA: < 60 mmHg añade 2 puntos.
#           - FRECUENCIA_CARDIACA_INGRESO_ALTA: > 120 lpm añade 2 puntos; entre 110 y 120 lpm añade 1 punto.
#           - F_RESPIRATORIA_INGRESO_ALTA: > 20 rpm añade 1 punto.
#           - SaO2_ESTANCIA_MAX: < 90% añade 2 puntos; entre 90 y 92% añade 1 punto.
#       * Laboratorios:
#           - HEMOGLOBINA (usando HEMOGLOBINA_INGRESO o HEMOGLOBINA_ESTANCIA_MIN): 
#               < 7 g/dL añade 2 puntos; entre 7 y 8 g/dL añade 1 punto.
#           - Recuento_de_plaquetas_-_PLT___min: < 50000 añade 2 puntos; entre 50000 y 100000 añade 1 punto.
#           - CREATININA (usando CREATININA_INGRESO o CREATININA_ESTANCIA_MAX): 
#               > 1.4 mg/dL añade 2 puntos; entre 1.2 y 1.4 mg/dL añade 1 punto.
#           - GPT_INGRESO y GOT_Aspartato_aminotransferasa_max: si alguno es > 80, añade 1 punto.
#     """
#     score = 0
    
#     # Evaluación de signos vitales
#     if not pd.isnull(row.get("PAS_INGRESO_ALTA")):
#         try:
#             pas = float(row["PAS_INGRESO_ALTA"])
#             if pas < 90:
#                 score += 2
#         except:
#             pass

#     if not pd.isnull(row.get("PAD_INGRESO_BAJA")):
#         try:
#             pad = float(row["PAD_INGRESO_BAJA"])
#             if pad < 60:
#                 score += 2
#         except:
#             pass

#     if not pd.isnull(row.get("FRECUENCIA_CARDIACA_INGRESO_ALTA")):
#         try:
#             fc = float(row["FRECUENCIA_CARDIACA_INGRESO_ALTA"])
#             if fc > 120:
#                 score += 2
#             elif fc > 110:
#                 score += 1
#         except:
#             pass

#     if not pd.isnull(row.get("F_RESPIRATORIA_INGRESO_ALTA")):
#         try:
#             fr = float(row["F_RESPIRATORIA_INGRESO_ALTA"])
#             if fr > 20:
#                 score += 1
#         except:
#             pass

#     if not pd.isnull(row.get("SaO2_ESTANCIA_MAX")):
#         try:
#             sao2 = float(row["SaO2_ESTANCIA_MAX"])
#             if sao2 < 90:
#                 score += 2
#             elif sao2 < 92:
#                 score += 1
#         except:
#             pass

#     # Evaluación de parámetros de laboratorio
    
#     # Hemoglobina (se utiliza HEMOGLOBINA_INGRESO; si no existe, se usa HEMOGLOBINA_ESTANCIA_MIN)
#     hemoglobina = None
#     if not pd.isnull(row.get("HEMOGLOBINA_INGRESO")):
#         try:
#             hemoglobina = float(row["HEMOGLOBINA_INGRESO"])
#         except:
#             pass
#     elif not pd.isnull(row.get("HEMOGLOBINA_ESTANCIA_MIN")):
#         try:
#             hemoglobina = float(row["HEMOGLOBINA_ESTANCIA_MIN"])
#         except:
#             pass

#     if hemoglobina is not None:
#         if hemoglobina < 7:
#             score += 2
#         elif hemoglobina < 8:
#             score += 1

#     # Recuento de plaquetas
#     if not pd.isnull(row.get("Recuento_de_plaquetas_-_PLT___min")):
#         try:
#             plaquetas = float(row["Recuento_de_plaquetas_-_PLT___min"])
#             if plaquetas < 50000:
#                 score += 2
#             elif plaquetas < 100000:
#                 score += 1
#         except:
#             pass

#     # Creatinina (se utiliza CREATININA_INGRESO; si no existe, se usa CREATININA_ESTANCIA_MAX)
#     creatinina = None
#     if not pd.isnull(row.get("CREATININA_INGRESO")):
#         try:
#             creatinina = float(row["CREATININA_INGRESO"])
#         except:
#             pass
#     elif not pd.isnull(row.get("CREATININA_ESTANCIA_MAX")):
#         try:
#             creatinina = float(row["CREATININA_ESTANCIA_MAX"])
#         except:
#             pass

#     if creatinina is not None:
#         if creatinina > 1.4:
#             score += 2
#         elif creatinina > 1.2:
#             score += 1

#     # Transaminasas: GPT_INGRESO
#     if not pd.isnull(row.get("GPT_INGRESO")):
#         try:
#             gpt = float(row["GPT_INGRESO"])
#             if gpt > 80:
#                 score += 1
#         except:
#             pass

#     # Transaminasas: GOT_Aspartato_aminotransferasa_max
#     if not pd.isnull(row.get("GOT_Aspartato_aminotransferasa_max")):
#         try:
#             got = float(row["GOT_Aspartato_aminotransferasa_max"])
#             if got > 80:
#                 score += 1
#         except:
#             pass

#     # Clasificar el riesgo en función del puntaje total
#     if score >= 6:
#         return "Alto"
#     elif score >= 3:
#         return "Moderado"
#     else:
#         return "Bajo"

# # Aplicar la función a cada fila y crear la nueva columna "Nivel_de_Riesgo"
# df["Nivel_de_Riesgo"] = df.apply(calcular_riesgo, axis=1)

# # Exportar el DataFrame a un archivo XLSX
# df.to_excel("datos_nuevos_con_riesgo.xlsx", index=False)

# print("Archivo XLSX generado exitosamente con la columna 'Nivel_de_Riesgo'.")



# import pandas as pd
# import numpy as np # Importar numpy para manejar NaN de forma más robusta

# # --- Configuración ---
# input_csv_file = 'datos_nuevos.csv'
# output_excel_file = 'datos_nuevos_con_riesgo_ponderado.xlsx'

# # --- PONDERACIÓN DE RIESGOS (EJEMPLO - ¡AJUSTAR CON EXPERTOS!) ---
# # Estos pesos son ilustrativos y deben ser validados clínicamente.
# # Asigna más puntos a los factores más críticos.
# pesos_riesgo = {
#     # Factores Críticos (Alto Peso)
#     'ingreso_uci': 15,
#     'rotura_uterina': 20,
#     'shock_severo': 15, # Combinación de PAS < 70 o PAD < 40
#     'taquicardia_extrema': 10, # FC > 130
#     'bradicardia_severa': 10, # FC < 50
#     'falla_respiratoria_severa': 10, # FR > 30 o < 10
#     'hipoxemia_severa': 10, # SaO2 < 90
#     'consciencia_no_alerta': 15,
#     'falla_renal_severa': 10, # Creatinina > 2.0
#     'falla_hepatica_severa': 10, # GOT/GPT > 500
#     'plaquetopenia_severa': 10, # Plaquetas < 50k
#     'transfusion_masiva': 10, # >= 4 unidades

#     # Factores de Alerta (Peso Moderado)
#     'ingreso_uado': 5,
#     'diagnostico_the': 5,
#     'diagnostico_hemorragia': 5,
#     'hipotension_moderada': 5, # PAS < 90 o PAD < 60
#     'taquicardia_moderada': 3, # FC > 120
#     'bradicardia_moderada': 3, # FC < 60
#     'taquipnea_moderada': 3, # FR > 24
#     'falla_renal_moderada': 4, # Creatinina > 1.2
#     'falla_hepatica_moderada': 4, # GOT/GPT > 100
#     'plaquetopenia_moderada': 4, # Plaquetas < 100k
#     'transfusion_simple': 3, # 1-3 unidades
#     'laceracion_grave': 3,
#     'cirugia_no_programada': 4,

#     # Factores de Riesgo Base (Peso Bajo - Opcional, pueden añadir ruido)
#     # 'edad_riesgo': 1, # <20 o >35
#     # 'multiparidad': 1, # >4 gestaciones por ejemplo
#     # 'sin_controles': 2,
# }

# # --- UMBRALES DE PUNTUACIÓN (EJEMPLO - ¡AJUSTAR!) ---
# umbral_riesgo_alto = 20 # Puntuación >= a esto es Alto Riesgo
# umbral_riesgo_moderado = 8 # Puntuación >= a esto (y < Alto) es Moderado Riesgo

# # --- Función para Calcular Puntuación y Clasificar Riesgo ---
# def calcular_clasificar_riesgo_ponderado(row):
#     """
#     Calcula una puntuación de riesgo ponderada y clasifica a la paciente.
#     """
#     puntuacion = 0
#     try:
#         # --- Conversión y Limpieza Segura ---
#         def safe_float_conversion(value):
#             if pd.isna(value): return np.nan # Usar np.nan para cálculos numéricos
#             try: return float(str(value).replace(',', '.'))
#             except (ValueError, TypeError): return np.nan

#         def safe_int_conversion(value):
#              if pd.isna(value): return np.nan
#              try:
#                 float_val = safe_float_conversion(value)
#                 # Usar int() solo si no es nan, o mantener nan
#                 return int(float_val) if not np.isnan(float_val) else np.nan
#              except (ValueError, TypeError): return np.nan

#         # --- Obtener valores ---
#         ingreso_uci = safe_int_conversion(row.get('MANEJO_ESPECIFICO_Ingreso_a_UCI'))
#         rotura_uterina = safe_int_conversion(row.get('WAOS_Rotura_uterina_durante_el_parto'))
#         unidades_transfundidas = safe_int_conversion(row.get('UNIDADES_TRANSFUNDIDAS'))
#         pas_min_estancia = safe_float_conversion(row.get('PAS_ESTANCIA_MIN'))
#         pad_min_estancia = safe_float_conversion(row.get('PAD_ESTANCIA_MIN'))
#         fc_max_estancia = safe_float_conversion(row.get('F_CARDIACA_ESTANCIA_MIN', np.nan)) # Usando segundo como MAX
#         fc_min_estancia = safe_float_conversion(row.get('F_CARIDIACA_ESTANCIA_MIN', np.nan)) # Usando primero
#         fr_ingreso_alta = safe_int_conversion(row.get('F_RESPIRATORIA_INGRESO_ALTA'))
#         sao2_max_estancia = safe_float_conversion(row.get('SaO2_ESTANCIA_MAX'))
#         consciencia = str(row.get('CONSCIENCIA_INGRESO', '')).strip().lower()
#         creatinina_max_estancia = safe_float_conversion(row.get('CREATININA_ESTANCIA_MAX'))
#         got_max_estancia = safe_float_conversion(row.get('GOT_Aspartato_aminotransferasa_max'))
#         gpt_ingreso = safe_float_conversion(row.get('GPT_INGRESO'))
#         plaquetas_min = safe_float_conversion(row.get('Recuento_de_plaquetas_-_PLT___min'))
#         ingreso_uado = safe_int_conversion(row.get('MANEJO_ESPECIFICO_Ingreso_a_UADO'))
#         diag_the = safe_int_conversion(row.get('DIAG_PRINCIPAL_THE'))
#         diag_hemorragia = safe_int_conversion(row.get('DIAG_PRINCIPAL_HEMORRAGIA'))
#         laceracion_grave = safe_int_conversion(row.get('WAOS_laceracion_perineal_de_3er_o_4to_grado'))
#         cirugia_no_prog = safe_int_conversion(row.get('WAOS_Procedimiento_quirúrgico_no_programado'))
#         # edad = safe_int_conversion(row.get('EDAD')) # Ejemplo si se incluye edad
#         # num_gestac = safe_int_conversion(row.get('NUM_CONTROLES')) # Ejemplo
#         # num_controles = safe_int_conversion(row.get('NUM_CONTROLES')) # Ejemplo

#         # --- Calcular Puntuación Ponderada ---

#         # Factores Críticos
#         if ingreso_uci == 1: puntuacion += pesos_riesgo['ingreso_uci']
#         if rotura_uterina == 1: puntuacion += pesos_riesgo['rotura_uterina']
#         if (not np.isnan(pas_min_estancia) and pas_min_estancia < 70) or \
#            (not np.isnan(pad_min_estancia) and pad_min_estancia < 40):
#             puntuacion += pesos_riesgo['shock_severo']
#         if not np.isnan(fc_max_estancia) and fc_max_estancia > 130: puntuacion += pesos_riesgo['taquicardia_extrema']
#         if not np.isnan(fc_min_estancia) and fc_min_estancia < 50: puntuacion += pesos_riesgo['bradicardia_severa']
#         if not np.isnan(fr_ingreso_alta) and (fr_ingreso_alta > 30 or fr_ingreso_alta < 10): puntuacion += pesos_riesgo['falla_respiratoria_severa']
#         if not np.isnan(sao2_max_estancia) and sao2_max_estancia < 90: puntuacion += pesos_riesgo['hipoxemia_severa']
#         if consciencia == 'no alerta': puntuacion += pesos_riesgo['consciencia_no_alerta']
#         if not np.isnan(creatinina_max_estancia) and creatinina_max_estancia > 2.0: puntuacion += pesos_riesgo['falla_renal_severa']
#         if (not np.isnan(got_max_estancia) and got_max_estancia > 500) or \
#            (not np.isnan(gpt_ingreso) and gpt_ingreso > 500):
#              puntuacion += pesos_riesgo['falla_hepatica_severa']
#         if not np.isnan(plaquetas_min) and plaquetas_min < 50000: puntuacion += pesos_riesgo['plaquetopenia_severa']
#         if not np.isnan(unidades_transfundidas) and unidades_transfundidas >= 4: puntuacion += pesos_riesgo['transfusion_masiva']

#         # Factores de Alerta (se suman si no se cumplió un criterio crítico similar)
#         if ingreso_uado == 1 and ingreso_uci != 1 : puntuacion += pesos_riesgo['ingreso_uado'] # Solo si no está ya en UCI
#         if diag_the == 1: puntuacion += pesos_riesgo['diagnostico_the']
#         if diag_hemorragia == 1: puntuacion += pesos_riesgo['diagnostico_hemorragia']
#         # Verificar hipotensión moderada solo si no hay shock severo
#         if not ((not np.isnan(pas_min_estancia) and pas_min_estancia < 70) or \
#                 (not np.isnan(pad_min_estancia) and pad_min_estancia < 40)):
#             if (not np.isnan(pas_min_estancia) and pas_min_estancia < 90) or \
#                (not np.isnan(pad_min_estancia) and pad_min_estancia < 60):
#                 puntuacion += pesos_riesgo['hipotension_moderada']
#         if not np.isnan(fc_max_estancia) and 120 < fc_max_estancia <= 130 : puntuacion += pesos_riesgo['taquicardia_moderada'] # Rango intermedio
#         if not np.isnan(fc_min_estancia) and 50 <= fc_min_estancia < 60 : puntuacion += pesos_riesgo['bradicardia_moderada'] # Rango intermedio
#         if not np.isnan(fr_ingreso_alta) and 24 < fr_ingreso_alta <= 30 : puntuacion += pesos_riesgo['taquipnea_moderada'] # Rango intermedio
#         if not np.isnan(creatinina_max_estancia) and 1.2 < creatinina_max_estancia <= 2.0: puntuacion += pesos_riesgo['falla_renal_moderada']
#         # Verificar daño hepático moderado solo si no es severo
#         if not ((not np.isnan(got_max_estancia) and got_max_estancia > 500) or \
#                 (not np.isnan(gpt_ingreso) and gpt_ingreso > 500)):
#             if (not np.isnan(got_max_estancia) and got_max_estancia > 100) or \
#                (not np.isnan(gpt_ingreso) and gpt_ingreso > 100):
#                 puntuacion += pesos_riesgo['falla_hepatica_moderada']
#         if not np.isnan(plaquetas_min) and 50000 <= plaquetas_min < 100000: puntuacion += pesos_riesgo['plaquetopenia_moderada']
#         if not np.isnan(unidades_transfundidas) and 1 <= unidades_transfundidas < 4: puntuacion += pesos_riesgo['transfusion_simple']
#         if laceracion_grave == 1: puntuacion += pesos_riesgo['laceracion_grave']
#         if cirugia_no_prog == 1: puntuacion += pesos_riesgo['cirugia_no_programada']

#         # Opcional: Añadir puntos por factores de riesgo base (descomentar si se usan)
#         # if not np.isnan(edad) and (edad < 20 or edad > 35): puntuacion += pesos_riesgo['edad_riesgo']
#         # if not np.isnan(num_gestac) and num_gestac > 4: puntuacion += pesos_riesgo['multiparidad'] # Ejemplo, ajustar umbral
#         # if not np.isnan(num_controles) and num_controles < 4: puntuacion += pesos_riesgo['sin_controles'] # Ejemplo

#         # --- Clasificación Final basada en Puntuación ---
#         if puntuacion >= umbral_riesgo_alto:
#             clasificacion = "Alto"
#         elif puntuacion >= umbral_riesgo_moderado:
#             clasificacion = "Moderado"
#         else:
#             clasificacion = "Bajo"

#         # Devolver tanto la puntuación como la clasificación
#         return pd.Series({'PUNTUACION_RIESGO': puntuacion, 'NIVEL_RIESGO_PONDERADO': clasificacion})

#     except Exception as e:
#         print(f"Error procesando fila ID {row.get('ID', 'Desconocido')}: {e}")
#         return pd.Series({'PUNTUACION_RIESGO': np.nan, 'NIVEL_RIESGO_PONDERADO': "Indeterminado"})

# # --- Carga y Procesamiento del CSV ---
# try:
#     df = pd.read_csv(input_csv_file)
# except FileNotFoundError:
#     print(f"Error: Archivo '{input_csv_file}' no encontrado.")
#     exit()
# except Exception as e:
#     print(f"Error al leer el archivo CSV: {e}")
#     exit()

# # --- Aplicar la función para obtener puntuación y clasificación ---
# # Se aplica la función y se unen las nuevas columnas al DataFrame original
# riesgo_df = df.apply(calcular_clasificar_riesgo_ponderado, axis=1)
# df = pd.concat([df, riesgo_df], axis=1)

# # --- Guardar el resultado en Excel ---
# try:
#     df.to_excel(output_excel_file, index=False)
#     print(f"Archivo Excel '{output_excel_file}' generado con éxito con 'PUNTUACION_RIESGO' y 'NIVEL_RIESGO_PONDERADO'.")
#     print("\nDistribución de Niveles de Riesgo Calculados (Ponderado):")
#     print(df['NIVEL_RIESGO_PONDERADO'].value_counts())
# except Exception as e:
#     print(f"Error al guardar el archivo Excel: {e}")


# import pandas as pd
# import numpy as np

# # Leer el archivo CSV con los datos nuevos
# df = pd.read_csv("datos_nuevos.csv")

# def calcular_riesgo(row):
#     """
#     Función para calcular el puntaje de riesgo y asignar un nivel de riesgo:
#     - Si el puntaje es >= 6, se clasifica como "Alto"
#     - Si el puntaje es entre 3 y 5, se clasifica como "Moderado"
#     - Si el puntaje es < 3, se clasifica como "Bajo"
    
#     Se evalúan los siguientes parámetros:
#       * Signos vitales:
#           - PAS_INGRESO_ALTA: < 90 mmHg añade 2 puntos.
#           - PAD_INGRESO_BAJA: < 60 mmHg añade 2 puntos.
#           - FRECUENCIA_CARDIACA_INGRESO_ALTA: > 120 lpm añade 2 puntos; entre 110 y 120 lpm añade 1 punto.
#           - F_RESPIRATORIA_INGRESO_ALTA: > 20 rpm añade 1 punto.
#           - SaO2_ESTANCIA_MAX: < 90% añade 2 puntos; entre 90 y 92% añade 1 punto.
#       * Laboratorios:
#           - HEMOGLOBINA (usando HEMOGLOBINA_INGRESO o HEMOGLOBINA_ESTANCIA_MIN): 
#               < 7 g/dL añade 2 puntos; entre 7 y 8 g/dL añade 1 punto.
#           - Recuento_de_plaquetas_-_PLT___min: < 50000 añade 2 puntos; entre 50000 y 100000 añade 1 punto.
#           - CREATININA (usando CREATININA_INGRESO o CREATININA_ESTANCIA_MAX): 
#               > 1.4 mg/dL añade 2 puntos; entre 1.2 y 1.4 mg/dL añade 1 punto.
#           - GPT_INGRESO y GOT_Aspartato_aminotransferasa_max: si alguno es > 80, añade 1 punto.
#     """
#     score = 0
    
#     # Evaluación de signos vitales
#     if not pd.isnull(row.get("PAS_INGRESO_ALTA")):
#         try:
#             pas = float(row["PAS_INGRESO_ALTA"])
#             if pas < 90:
#                 score += 2
#         except:
#             pass

#     if not pd.isnull(row.get("PAD_INGRESO_BAJA")):
#         try:
#             pad = float(row["PAD_INGRESO_BAJA"])
#             if pad < 60:
#                 score += 2
#         except:
#             pass

#     if not pd.isnull(row.get("FRECUENCIA_CARDIACA_INGRESO_ALTA")):
#         try:
#             fc = float(row["FRECUENCIA_CARDIACA_INGRESO_ALTA"])
#             if fc > 120:
#                 score += 2
#             elif fc > 110:
#                 score += 1
#         except:
#             pass

#     if not pd.isnull(row.get("F_RESPIRATORIA_INGRESO_ALTA")):
#         try:
#             fr = float(row["F_RESPIRATORIA_INGRESO_ALTA"])
#             if fr > 20:
#                 score += 1
#         except:
#             pass

#     if not pd.isnull(row.get("SaO2_ESTANCIA_MAX")):
#         try:
#             sao2 = float(row["SaO2_ESTANCIA_MAX"])
#             if sao2 < 90:
#                 score += 2
#             elif sao2 < 92:
#                 score += 1
#         except:
#             pass

#     # Evaluación de parámetros de laboratorio
    
#     # Hemoglobina (se utiliza HEMOGLOBINA_INGRESO; si no existe, se usa HEMOGLOBINA_ESTANCIA_MIN)
#     hemoglobina = None
#     if not pd.isnull(row.get("HEMOGLOBINA_INGRESO")):
#         try:
#             hemoglobina = float(row["HEMOGLOBINA_INGRESO"])
#         except:
#             pass
#     elif not pd.isnull(row.get("HEMOGLOBINA_ESTANCIA_MIN")):
#         try:
#             hemoglobina = float(row["HEMOGLOBINA_ESTANCIA_MIN"])
#         except:
#             pass

#     if hemoglobina is not None:
#         if hemoglobina < 7:
#             score += 2
#         elif hemoglobina < 8:
#             score += 1

#     # Recuento de plaquetas
#     if not pd.isnull(row.get("Recuento_de_plaquetas_-_PLT___min")):
#         try:
#             plaquetas = float(row["Recuento_de_plaquetas_-_PLT___min"])
#             if plaquetas < 50000:
#                 score += 2
#             elif plaquetas < 100000:
#                 score += 1
#         except:
#             pass

#     # Creatinina (se utiliza CREATININA_INGRESO; si no existe, se usa CREATININA_ESTANCIA_MAX)
#     creatinina = None
#     if not pd.isnull(row.get("CREATININA_INGRESO")):
#         try:
#             creatinina = float(row["CREATININA_INGRESO"])
#         except:
#             pass
#     elif not pd.isnull(row.get("CREATININA_ESTANCIA_MAX")):
#         try:
#             creatinina = float(row["CREATININA_ESTANCIA_MAX"])
#         except:
#             pass

#     if creatinina is not None:
#         if creatinina > 1.4:
#             score += 2
#         elif creatinina > 1.2:
#             score += 1

#     # Transaminasas: GPT_INGRESO
#     if not pd.isnull(row.get("GPT_INGRESO")):
#         try:
#             gpt = float(row["GPT_INGRESO"])
#             if gpt > 80:
#                 score += 1
#         except:
#             pass

#     # Transaminasas: GOT_Aspartato_aminotransferasa_max
#     if not pd.isnull(row.get("GOT_Aspartato_aminotransferasa_max")):
#         try:
#             got = float(row["GOT_Aspartato_aminotransferasa_max"])
#             if got > 80:
#                 score += 1
#         except:
#             pass

#     # Clasificar el riesgo en función del puntaje total
#     if score >= 6:
#         return "Alto"
#     elif score >= 3:
#         return "Moderado"
#     else:
#         return "Bajo"

# # Aplicar la función a cada fila y crear la nueva columna "Nivel_de_Riesgo"
# df["Nivel_de_Riesgo"] = df.apply(calcular_riesgo, axis=1)

# # Exportar el DataFrame a un archivo XLSX
# df.to_excel("datos_nuevos_con_riesgo.xlsx", index=False)

# print("Archivo XLSX generado exitosamente con la columna 'Nivel_de_Riesgo'.")



# import pandas as pd

# # --- Configuración ---
# input_csv_file = 'datos_nuevos.csv'
# output_excel_file = 'datos_nuevos_con_riesgo2.xlsx'

# # --- Función para Clasificar el Riesgo ---
# def clasificar_riesgo(row):
#     """
#     Clasifica el nivel de riesgo de una paciente basado en un conjunto
#     prioritario de variables y umbrales predefinidos.

#     Args:
#         row (pd.Series): Una fila del DataFrame con los datos de la paciente.

#     Returns:
#         str: El nivel de riesgo ('Alto', 'Moderado', 'Bajo').
#     """
#     try:
#         # --- Conversión y Limpieza de Datos Clave para la fila ---
#         # (Convertir comas a puntos y luego a numérico, manejar errores)
#         def safe_float_conversion(value):
#             if pd.isna(value):
#                 return None
#             try:
#                 # Reemplazar coma por punto y convertir a float
#                 return float(str(value).replace(',', '.'))
#             except (ValueError, TypeError):
#                 return None # Retorna None si la conversión falla

#         def safe_int_conversion(value):
#              if pd.isna(value):
#                 return None
#              try:
#                 # Intentar convertir directamente a int (para códigos, etc.)
#                 # o primero a float si tiene decimales (y luego a int si se requiere)
#                 float_val = safe_float_conversion(value)
#                 return int(float_val) if float_val is not None else None
#              except (ValueError, TypeError):
#                 return None

#         ingreso_uci = safe_int_conversion(row.get('MANEJO_ESPECIFICO_Ingreso_a_UCI'))
#         ingreso_uado = safe_int_conversion(row.get('MANEJO_ESPECIFICO_Ingreso_a_UADO'))
#         rotura_uterina = safe_int_conversion(row.get('WAOS_Rotura_uterina_durante_el_parto'))
#         unidades_transfundidas = safe_int_conversion(row.get('UNIDADES_TRANSFUNDIDAS'))
#         pas_min_estancia = safe_float_conversion(row.get('PAS_ESTANCIA_MIN'))
#         pad_min_estancia = safe_float_conversion(row.get('PAD_ESTANCIA_MIN'))
#         # Asumiendo que la segunda columna F_CARIDIACA_ESTANCIA_MIN es el MAX
#         fc_max_estancia = safe_float_conversion(row.get('F_CARIDIACA_ESTANCIA_MIN', None)) # Usamos .get con default None
#         fc_min_estancia = safe_float_conversion(row.get('F_CARIDIACA_ESTANCIA_MIN', None)) # Mantenemos el nombre como en el CSV
#         fr_ingreso_alta = safe_int_conversion(row.get('F_RESPIRATORIA_INGRESO_ALTA'))
#         sao2_max_estancia = safe_float_conversion(row.get('SaO2_ESTANCIA_MAX')) # Máximo, pero buscamos valores bajos
#         consciencia = str(row.get('CONSCIENCIA_INGRESO', '')).strip().lower() # Convertir a minúsculas y quitar espacios
#         creatinina_max_estancia = safe_float_conversion(row.get('CREATININA_ESTANCIA_MAX'))
#         got_max_estancia = safe_float_conversion(row.get('GOT_Aspartato_aminotransferasa_max'))
#         gpt_ingreso = safe_float_conversion(row.get('GPT_INGRESO'))
#         plaquetas_min = safe_float_conversion(row.get('Recuento_de_plaquetas_-_PLT___min'))
#         diag_hemorragia = safe_int_conversion(row.get('DIAG_PRINCIPAL_HEMORRAGIA'))
#         diag_the = safe_int_conversion(row.get('DIAG_PRINCIPAL_THE'))
#         laceracion_grave = safe_int_conversion(row.get('WAOS_laceracion_perineal_de_3er_o_4to_grado'))
#         cirugia_no_prog = safe_int_conversion(row.get('WAOS_Procedimiento_quirúrgico_no_programado'))

#         # --- Lógica de Clasificación de Riesgo ---

#         # **Nivel Alto (Indicadores Críticos)**
#         if (ingreso_uci == 1 or
#             rotura_uterina == 1 or
#             (unidades_transfundidas is not None and unidades_transfundidas >= 4) or
#             (pas_min_estancia is not None and pas_min_estancia < 70) or
#             (pad_min_estancia is not None and pad_min_estancia < 40) or
#             (fc_max_estancia is not None and fc_max_estancia > 130) or # Usando la segunda columna
#             (fc_min_estancia is not None and fc_min_estancia < 50) or
#             (fr_ingreso_alta is not None and (fr_ingreso_alta > 30 or fr_ingreso_alta < 10)) or
#             (sao2_max_estancia is not None and sao2_max_estancia < 90) or # SaO2 baja es alto riesgo
#             consciencia == 'no alerta' or
#             (creatinina_max_estancia is not None and creatinina_max_estancia > 2.0) or
#             (got_max_estancia is not None and got_max_estancia > 500) or # Umbral ejemplo
#             (gpt_ingreso is not None and gpt_ingreso > 500) or # Umbral ejemplo
#             (plaquetas_min is not None and plaquetas_min < 50000)):
#             return "Alto"

#         # **Nivel Moderado (Indicadores de Alerta)**
#         elif (ingreso_uado == 1 or
#               diag_the == 1 or # Diagnóstico de THE per se ya es riesgo moderado
#               diag_hemorragia == 1 or # Diagnóstico de Hemorragia per se ya es riesgo moderado
#               (unidades_transfundidas is not None and unidades_transfundidas >= 1) or # 1 o más ya es relevante
#               (pas_min_estancia is not None and pas_min_estancia < 90) or
#               (pad_min_estancia is not None and pad_min_estancia < 60) or
#               (fc_max_estancia is not None and fc_max_estancia > 120) or # Usando la segunda columna
#               (fc_min_estancia is not None and fc_min_estancia < 60) or
#               (fr_ingreso_alta is not None and fr_ingreso_alta > 24) or
#               (creatinina_max_estancia is not None and creatinina_max_estancia > 1.2) or
#               (got_max_estancia is not None and got_max_estancia > 100) or # Umbral ejemplo
#               (gpt_ingreso is not None and gpt_ingreso > 100) or # Umbral ejemplo
#               (plaquetas_min is not None and plaquetas_min < 100000) or
#               laceracion_grave == 1 or
#               cirugia_no_prog == 1):
#              return "Moderado"

#         # **Nivel Bajo (Ausencia de indicadores de Alto o Moderado riesgo)**
#         else:
#             return "Bajo"

#     except Exception as e:
#         # En caso de un error inesperado al procesar la fila, devolver Bajo por precaución
#         print(f"Error procesando fila ID {row.get('ID', 'Desconocido')}: {e}")
#         return "Bajo" # O podrías devolver "Indeterminado"

# # --- Carga y Procesamiento del CSV ---
# try:
#     df = pd.read_csv(input_csv_file)
# except FileNotFoundError:
#     print(f"Error: Archivo '{input_csv_file}' no encontrado.")
#     exit()
# except Exception as e:
#     print(f"Error al leer el archivo CSV: {e}")
#     exit()

# # --- Aplicar la clasificación de riesgo ---
# # Se aplica la función 'clasificar_riesgo' a cada fila (axis=1)
# df['NIVEL_RIESGO'] = df.apply(clasificar_riesgo, axis=1)

# # --- Guardar el resultado en Excel ---
# try:
#     df.to_excel(output_excel_file, index=False)
#     print(f"Archivo Excel '{output_excel_file}' generado con éxito con la columna 'NIVEL_RIESGO'.")
# except Exception as e:
#     print(f"Error al guardar el archivo Excel: {e}")

# import pandas as pd
# import numpy as np
# import warnings

# import sys
# print(sys.executable)

# # Ignorar advertencias futuras de Pandas (opcional, para limpieza de consola)
# warnings.simplefilter(action='ignore', category=FutureWarning)

# # --- Parámetros ---
# input_csv_file = 'datos_nuevos.csv'
# output_excel_file = 'datos_con_riesgo.xlsx'

# # --- Columnas numéricas relevantes para convertir y usar en lógica ---
# # (Incluye las columnas clave para la lógica de riesgo)
# numeric_cols_to_convert = [
#     'UNIDADES_TRANSFUNDIDAS', 'PAS_ESTANCIA_MIN', 'PAD_ESTANCIA_MIN',
#     'FRECUENCIA_CARDIACA_INGRESO_ALTA', # Usaremos este como proxy de F_CARDIACA_ESTANCIA_MAX si falta
#     'F_RESPIRATORIA_INGRESO_ALTA', 'SaO2_ESTANCIA_MAX',
#     'CREATININA_INGRESO', 'CREATININA_ESTANCIA_MAX',
#     'GPT_INGRESO', 'GOT_Aspartato_aminotransferasa_max',
#     'Recuento_de_plaquetas_-_PLT___min', 'NUM_CONTROLES'
#     # Añadir otras columnas numéricas si son necesarias para reglas futuras
# ]

# # --- Función para asignar nivel de riesgo ---
# def asignar_nivel_riesgo(row):
#     """Asigna un nivel de riesgo ('Alto', 'Moderado', 'Bajo') basado en reglas heurísticas."""
#     try:
#         # --- Criterios de ALTO RIESGO (Presencia de CUALQUIERA de estos) ---
#         if row['MANEJO_ESPECIFICO_Ingreso_a_UCI'] == 1:
#             return 'Alto'
#         if row['WAOS_Rotura_uterina_durante_el_parto'] == 1:
#             return 'Alto'
#         if pd.notna(row['UNIDADES_TRANSFUNDIDAS']) and row['UNIDADES_TRANSFUNDIDAS'] >= 4:
#              return 'Alto'
#         # Shock (usando valores de estancia si están, si no, ingreso como proxy)
#         pas_min = row['PAS_ESTANCIA_MIN'] if pd.notna(row['PAS_ESTANCIA_MIN']) else row['PAS_INGRESO_ALTA'] # Usar PAS de ingreso si el min de estancia falta
#         pad_min = row['PAD_ESTANCIA_MIN'] if pd.notna(row['PAD_ESTANCIA_MIN']) else row['PAD_INGRESO_BAJA'] # Usar PAD de ingreso si el min de estancia falta
#         if (pd.notna(pas_min) and pas_min < 70) or \
#            (pd.notna(pad_min) and pad_min < 40):
#              return 'Alto'
#         if pd.notna(row['SaO2_ESTANCIA_MAX']) and row['SaO2_ESTANCIA_MAX'] < 90:
#              return 'Alto'
#         if pd.notna(row['CONSCIENCIA_INGRESO']) and row['CONSCIENCIA_INGRESO'].lower() != 'alerta':
#              return 'Alto'
#         # Usar creatinina max de estancia si está, si no, la de ingreso
#         creat_max = row['CREATININA_ESTANCIA_MAX'] if pd.notna(row['CREATININA_ESTANCIA_MAX']) else row['CREATININA_INGRESO']
#         if pd.notna(creat_max) and creat_max > 2.0:
#              return 'Alto'
#         if pd.notna(row['GOT_Aspartato_aminotransferasa_max']) and row['GOT_Aspartato_aminotransferasa_max'] > 200: # Umbral heurístico alto para GOT/AST
#              return 'Alto'
#         if pd.notna(row['Recuento_de_plaquetas_-_PLT___min']) and row['Recuento_de_plaquetas_-_PLT___min'] < 50000:
#             return 'Alto'

#         # --- Criterios de MODERADO RIESGO (Presencia de CUALQUIERA de estos, si no es Alto) ---
#         if row['MANEJO_ESPECIFICO_Ingreso_a_UADO'] == 1:
#             return 'Moderado'
#         if pd.notna(row['UNIDADES_TRANSFUNDIDAS']) and row['UNIDADES_TRANSFUNDIDAS'] >= 1: # 1 a 3 unidades
#              return 'Moderado'
#         # Usar FC de ingreso si max de estancia falta
#         fc_max = row['FRECUENCIA_CARDIACA_INGRESO_ALTA'] # Asumimos que 'INGRESO_ALTA' es el max relevante aquí
#         if (pd.notna(pas_min) and pas_min < 90) or \
#            (pd.notna(pad_min) and pad_min < 50) or \
#            (pd.notna(fc_max) and fc_max > 110):
#              return 'Moderado'
#         if pd.notna(row['F_RESPIRATORIA_INGRESO_ALTA']) and row['F_RESPIRATORIA_INGRESO_ALTA'] > 24:
#              return 'Moderado'
#         if pd.notna(creat_max) and creat_max > 1.2: # Entre 1.2 y 2.0
#              return 'Moderado'
#         if pd.notna(row['GOT_Aspartato_aminotransferasa_max']) and row['GOT_Aspartato_aminotransferasa_max'] > 100: # Entre 100 y 200
#              return 'Moderado'
#         if pd.notna(row['Recuento_de_plaquetas_-_PLT___min']) and row['Recuento_de_plaquetas_-_PLT___min'] < 100000: # Entre 50k y 100k
#              return 'Moderado'
#         # Diagnósticos principales con otros signos moderados o como riesgo intrínseco
#         if row['DIAG_PRINCIPAL_THE'] == 1 or row['DIAG_PRINCIPAL_HEMORRAGIA'] == 1:
#              return 'Moderado' # Considerar THE o Hemorragia como riesgo moderado base
#         if pd.notna(row['NUM_CONTROLES']) and row['NUM_CONTROLES'] <= 1: # Pocos o ningún control prenatal
#              return 'Moderado'
#         # Puedes añadir criterios de edad aquí si lo deseas, ej:
#         # if pd.notna(row['EDAD']) and (row['EDAD'] < 18 or row['EDAD'] > 40):
#         #     return 'Moderado'

#         # --- Si no cumple criterios Alto ni Moderado ---
#         return 'Bajo'

#     except Exception as e:
#         print(f"Error procesando fila (ID: {row.get('ID', 'N/A')}): {e}")
#         return 'Error_Procesando' # O devuelve 'Bajo' o 'Desconocido' si prefieres

# # --- Carga y Procesamiento ---
# try:
#     # Cargar CSV indicando el separador decimal
#     df = pd.read_csv(input_csv_file, decimal=',')
#     print(f"Archivo CSV '{input_csv_file}' cargado correctamente.")
#     print(f"Número inicial de filas: {len(df)}")

#     # Limpiar nombres de columnas (quitar espacios extra, caracteres especiales si los hubiera)
#     df.columns = df.columns.str.strip()

#     # Convertir columnas relevantes a numérico, forzando errores a NaN
#     for col in numeric_cols_to_convert:
#         if col in df.columns:
#             # Primero, intentar reemplazar comas si no se manejó bien con 'decimal'
#             if df[col].dtype == 'object':
#                  df[col] = df[col].str.replace(',', '.', regex=False)
#             df[col] = pd.to_numeric(df[col], errors='coerce')
#         else:
#             print(f"Advertencia: La columna '{col}' no se encontró en el archivo CSV.")

#     # Asegurarse que las columnas binarias/indicadoras existan y sean numéricas (rellenar NaN con 0)
#     binary_indicator_cols = [
#         'MANEJO_ESPECIFICO_Ingreso_a_UCI', 'WAOS_Rotura_uterina_durante_el_parto',
#         'MANEJO_ESPECIFICO_Ingreso_a_UADO', 'DIAG_PRINCIPAL_THE', 'DIAG_PRINCIPAL_HEMORRAGIA',
#         'TRATAMIENTOS_UADO_Monitoreo_hemodinámico' # Añadir otras si se usan en reglas
#     ]
#     for col in binary_indicator_cols:
#         if col in df.columns:
#              df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0).astype(int)
#         else:
#              print(f"Advertencia: La columna indicadora '{col}' no se encontró. Se asumirá 0.")
#              df[col] = 0 # Crear la columna con 0 si no existe

#     # Aplicar la función para asignar nivel de riesgo
#     print("Asignando niveles de riesgo...")
#     df['Nivel_Riesgo'] = df.apply(asignar_nivel_riesgo, axis=1)
#     print("Niveles de riesgo asignados.")

#     # Contar la distribución de los niveles de riesgo asignados
#     print("\nDistribución de Niveles de Riesgo Asignados:")
#     print(df['Nivel_Riesgo'].value_counts())

#     # Guardar a Excel
#     df.to_excel(output_excel_file, index=False)
#     print(f"\nArchivo Excel '{output_excel_file}' creado con éxito.")

# except FileNotFoundError:
#     print(f"Error: Archivo CSV '{input_csv_file}' no encontrado.")
# except Exception as e:
#     print(f"Ocurrió un error general durante el procesamiento: {e}")