import pandas as pd
import json
from imblearn.over_sampling import SMOTE
import numpy as np
import csv  # Import the standard csv module

input_json_file = 'datos.json' # Nombre del archivo JSON de entrada
output_json_file = 'datosSMOTE.json' # Nombre del archivo JSON de salida balanceado
output_csv_file = 'datosEntrenamiento2.csv' # Nombre del archivo CSV de salida entrenamiento

try:
    with open(input_json_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
except FileNotFoundError:
    print(f"Error: Archivo '{input_json_file}' no encontrado.")
    exit()
except json.JSONDecodeError:
    print(f"Error: El archivo '{input_json_file}' no es un JSON válido.")
    exit()

df = pd.DataFrame(data)

# Separar características y variable objetivo
relevant_fields = [
    "edad_", "num_gestac", "num_aborto", "num_muerto", "endoc_meta", "card_cereb",
    "renales", "otras_enfe", "preclampsi", "hemorragia_obst_severa", "hem_mas_sever_MM",
    "area_", "tip_ss_", "no_con_pre", "sem_c_pren", "cod_mun_r", "cod_pre", "estrato_",
    "eclampsia", "dias_hospi", "term_gesta", "moc_rel_tg", "tip_cas_", "num_cesare",
    "caus_princ", "rupt_uteri", "peso_rnacx"
]

features = df[relevant_fields].copy() # Copy para evitar warnings de pandas

# Imputar valores faltantes con 0 y convertir a numérico, manejando errores
for col in features.columns:
    features[col] = pd.to_numeric(features[col], errors='coerce').fillna(0)


target = df['con_fin_muerte']

# Aplicar SMOTE para sobremuestrear la clase minoritaria (con_fin_muerte: 1)
smote = SMOTE(random_state=42, sampling_strategy='minority') # Balancear solo la minoritaria
features_resampled, target_resampled = smote.fit_resample(features, target)

# Crear DataFrame balanceado
df_resampled = pd.DataFrame(features_resampled, columns=relevant_fields)
df_resampled['con_fin_muerte'] = target_resampled

# Convertir el DataFrame balanceado a formato JSON (lista de diccionarios)
data_resampled_json = df_resampled.to_dict(orient='records')

# Guardar los datos balanceados en un archivo JSON
with open(output_json_file, 'w', encoding='utf-8') as f:
    json.dump(data_resampled_json, f, indent=4)

# Imprimir mensaje de éxito y distribución de clases balanceada
print(f"Archivo JSON balanceado con SMOTE '{output_json_file}' creado con éxito.")
print("\nDistribución de clases ANTES de SMOTE:")
print(target.value_counts())
print("\nDistribución de clases DESPUÉS de SMOTE:")
print(target_resampled.value_counts())
print(f"\nTotal de registros en el archivo balanceado JSON: {len(df_resampled)}")

# --- Crear y guardar datosEntrenamiento2.csv ---

def create_training_example(row):
    text_input = {}
    for field in relevant_fields:
        if field in row and pd.notna(row[field]) and row[field] != '  -   -' and row[field] != 'SIN INFORMACION' and row[field] != 'NA' and row[field] != '':
            text_input[field] = row[field]
    output = {"con_fin_muerte": row['con_fin_muerte']}
    return {'text_input': json.dumps(text_input), 'output': json.dumps(output)} # Return dictionary directly

training_data_csv_list = df_resampled.apply(create_training_example, axis=1).tolist() # Apply and convert to list of dicts

# Escribir a CSV usando la librería 'csv' estándar
with open(output_csv_file, 'w', newline='', encoding='utf-8') as csvfile:
    fieldnames = ['text_input', 'output'] # Define header
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames) # Use DictWriter
    writer.writeheader() # Write header row
    writer.writerows(training_data_csv_list) # Write data rows

print(f"\nArchivo CSV de entrenamiento '{output_csv_file}' creado con éxito.")
print(f"Total de registros en el archivo CSV de entrenamiento: {len(training_data_csv_list)}")

# import pandas as pd
# import json
# from imblearn.over_sampling import SMOTE
# import numpy as np

# input_json_file = 'datos.json' # Nombre del archivo JSON de entrada
# output_json_file = 'datosSMOTE.json' # Nombre del archivo JSON de salida balanceado

# try:
#     with open(input_json_file, 'r', encoding='utf-8') as f:
#         data = json.load(f)
# except FileNotFoundError:
#     print(f"Error: Archivo '{input_json_file}' no encontrado.")
#     exit()
# except json.JSONDecodeError:
#     print(f"Error: El archivo '{input_json_file}' no es un JSON válido.")
#     exit()

# df = pd.DataFrame(data)

# # Separar características y variable objetivo
# relevant_fields = [
#     "edad_", "num_gestac", "num_aborto", "num_muerto", "endoc_meta", "card_cereb",
#     "renales", "otras_enfe", "preclampsi", "hemorragia_obst_severa", "hem_mas_sever_MM",
#     "area_", "tip_ss_", "no_con_pre", "sem_c_pren", "cod_mun_r", "cod_pre", "estrato_",
#     "eclampsia", "dias_hospi", "term_gesta", "moc_rel_tg", "tip_cas_", "num_cesare",
#     "caus_princ", "rupt_uteri", "peso_rnacx"
# ]

# features = df[relevant_fields].copy() # Copy para evitar warnings de pandas

# # Imputar valores faltantes con 0 y convertir a numérico, manejando errores
# for col in features.columns:
#     features[col] = pd.to_numeric(features[col], errors='coerce').fillna(0)


# target = df['con_fin_muerte']

# # Aplicar SMOTE para sobremuestrear la clase minoritaria (con_fin_muerte: 1)
# smote = SMOTE(random_state=42, sampling_strategy='minority') # Balancear solo la minoritaria
# features_resampled, target_resampled = smote.fit_resample(features, target)

# # Crear DataFrame balanceado
# df_resampled = pd.DataFrame(features_resampled, columns=relevant_fields)
# df_resampled['con_fin_muerte'] = target_resampled

# # Convertir el DataFrame balanceado a formato JSON (lista de diccionarios)
# data_resampled_json = df_resampled.to_dict(orient='records')

# # Guardar los datos balanceados en un archivo JSON
# with open(output_json_file, 'w', encoding='utf-8') as f:
#     json.dump(data_resampled_json, f, indent=4)

# # Imprimir mensaje de éxito y distribución de clases balanceada
# print(f"Archivo JSON balanceado con SMOTE '{output_json_file}' creado con éxito.")
# print("\nDistribución de clases ANTES de SMOTE:")
# print(target.value_counts())
# print("\nDistribución de clases DESPUÉS de SMOTE:")
# print(target_resampled.value_counts())
# print(f"\nTotal de registros en el archivo balanceado: {len(df_resampled)}")