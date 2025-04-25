// lib/services/vertex_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../models/modelos.dart';
import 'firestore_service.dart';

/* // *** CORREGIDO: Usa propiedades de DatosClinicos directamente ***
// *** REVISA CADA CONDICIÓN Y TEXTO DETENIDAMENTE ***
/* final Map<String, Map<String, dynamic>> alertConditions = {
  'HEMORRAGIA_MAYOR': {
    'condition': (DatosClinicos datos) => datos.diagPrincipalHemorragia == true,
    'text':
        (DatosClinicos datos) =>
            'Evento Máxima Alerta: Hemorragia Obstétrica Mayor (Diagnóstico Principal)',
  },
  'ECLAMPSIA_CONVULSIONES': {
    'condition':
        (DatosClinicos datos) =>
            datos.diagPrincipalThe == true && datos.conscienciaIngreso?.toLowerCase() != 'alerta',
    'text':
        (DatosClinicos datos) =>
            'Evento Máxima Alerta: Sospecha Eclampsia / Convulsiones (THE + No Alerta)',
  },
  'SEPSIS_SHOCK_SEPTICO': {
    'condition':
        (DatosClinicos datos) =>
            ((datos.pasEstanciaMin != null && datos.pasEstanciaMin! < 90) ||
                (datos.padEstanciaMin != null && datos.padEstanciaMin! < 60)) &&
            (datos.fCardiacaEstanciaMax != null && datos.fCardiacaEstanciaMax! > 120),
    'text':
        (DatosClinicos datos) =>
            'Evento Máxima Alerta: Sospecha Sepsis Severa / Shock Séptico (Hipotensión + Taquicardia)',
  },
  'ROTURA_UTERINA': {
    'condition': (DatosClinicos datos) => datos.waosRoturaUterinaDuranteElParto == true,
    'text': (DatosClinicos datos) => 'Evento Máxima Alerta: Rotura Uterina',
  },
  'INGRESO_UCI': {
    'condition': (DatosClinicos datos) => datos.manejoEspecificoIngresoUci == true,
    'text': (DatosClinicos datos) => 'Evento Máxima Alerta: Ingreso a UCI Requerido',
  },
  'CIRUGIA_MAYOR_EMERG': {
    'condition': (DatosClinicos datos) => datos.manejoQxLaparotomia == true,
    'text':
        (DatosClinicos datos) => 'Evento Máxima Alerta: Cirugía Mayor de Emergencia (Laparotomía)',
  },
  'TRANSFUSION_MASIVA': {
    'condition':
        (DatosClinicos datos) =>
            datos.unidadesTransfundidas != null && datos.unidadesTransfundidas! >= 4,
    'text':
        (DatosClinicos datos) =>
            'Evento Máxima Alerta: Transfusión Masiva (${datos.unidadesTransfundidas} UGRE)',
  },
  'CONSCIENCIA_NO_ALERTA': {
    'condition': (DatosClinicos datos) => datos.conscienciaIngreso?.toLowerCase() != 'alerta',
    'text': (DatosClinicos datos) => 'Estado de Conciencia: No Alerta',
  },
  'PAS_MENOR_90': {
    'condition':
        (DatosClinicos datos) => datos.pasEstanciaMin != null && datos.pasEstanciaMin! < 90,
    'text':
        (DatosClinicos datos) =>
            'Presión Arterial Sistólica (PAS): ${datos.pasEstanciaMin?.toStringAsFixed(0) ?? 'N/A'} mmHg (< 90)',
  },
  'PAS_MAYOR_160': {
    'condition':
        (DatosClinicos datos) => datos.pasIngresoAlta != null && datos.pasIngresoAlta! > 160,
    'text':
        (DatosClinicos datos) =>
            'Presión Arterial Sistólica (PAS): ${datos.pasIngresoAlta?.toStringAsFixed(0) ?? 'N/A'} mmHg (> 160) (Valor Ingreso)',
  },
  'PAD_MENOR_60': {
    'condition':
        (DatosClinicos datos) => datos.padEstanciaMin != null && datos.padEstanciaMin! < 60,
    'text':
        (DatosClinicos datos) =>
            'Presión Arterial Diastólica (PAD): ${datos.padEstanciaMin?.toStringAsFixed(0) ?? 'N/A'} mmHg (< 60)',
  },
  'PAD_MAYOR_110': {
    'condition':
        (DatosClinicos datos) => datos.padIngresoBaja != null && datos.padIngresoBaja! > 110,
    'text':
        (DatosClinicos datos) =>
            'Presión Arterial Diastólica (PAD): ${datos.padIngresoBaja?.toStringAsFixed(0) ?? 'N/A'} mmHg (> 110) (Valor Ingreso - Baja)',
  },
  'FC_MAYOR_120': {
    'condition':
        (DatosClinicos datos) =>
            datos.fCardiacaEstanciaMax != null && datos.fCardiacaEstanciaMax! > 120,
    'text':
        (DatosClinicos datos) =>
            'Frecuencia Cardíaca (FC): ${datos.fCardiacaEstanciaMax?.toStringAsFixed(0) ?? 'N/A'} lpm (> 120)',
  },
  'FC_MENOR_50': {
    'condition':
        (DatosClinicos datos) =>
            datos.fCardiacaEstanciaMin != null && datos.fCardiacaEstanciaMin! < 50,
    'text':
        (DatosClinicos datos) =>
            'Frecuencia Cardíaca (FC): ${datos.fCardiacaEstanciaMin?.toStringAsFixed(0) ?? 'N/A'} lpm (< 50)',
  },
  'FR_MAYOR_30': {
    'condition':
        (DatosClinicos datos) =>
            datos.fRespiratoriaIngresoAlta != null && datos.fRespiratoriaIngresoAlta! > 30,
    'text':
        (DatosClinicos datos) =>
            'Frecuencia Respiratoria (FR): ${datos.fRespiratoriaIngresoAlta?.toStringAsFixed(0) ?? 'N/A'} rpm (> 30) (Valor Ingreso)',
  },
  'FR_MENOR_10': {
    'condition':
        (DatosClinicos datos) =>
            datos.fRespiratoriaIngresoAlta != null && datos.fRespiratoriaIngresoAlta! < 10,
    'text':
        (DatosClinicos datos) =>
            'Frecuencia Respiratoria (FR): ${datos.fRespiratoriaIngresoAlta?.toStringAsFixed(0) ?? 'N/A'} rpm (< 10) (Valor Ingreso)',
  },
  'HB_MENOR_7': {
    'condition':
        (DatosClinicos datos) =>
            datos.hemoglobinaIngreso != null && datos.hemoglobinaIngreso! < 7.0,
    'text':
        (DatosClinicos datos) =>
            'Hemoglobina (Hb): ${datos.hemoglobinaIngreso?.toStringAsFixed(1) ?? 'N/A'} g/dL (< 7.0)',
  },
  'PLAQUETAS_MENOR_100K': {
    'condition':
        (DatosClinicos datos) =>
            datos.recuentoPlaquetasPltMin != null &&
            datos.recuentoPlaquetasPltMin! < 100, // Ajustado el límite
    'text':
        (DatosClinicos datos) =>
            'Plaquetas: ${datos.recuentoPlaquetasPltMin?.toStringAsFixed(0) ?? 'N/A'}k /µL (< 100k)', // Asume que el valor ya está en K
  },
  'PLAQUETAS_MENOR_50K': {
    // Más específico y grave
    'condition':
        (DatosClinicos datos) =>
            datos.recuentoPlaquetasPltMin != null &&
            datos.recuentoPlaquetasPltMin! < 50, // Ajustado el límite
    'text':
        (DatosClinicos datos) =>
            'Plaquetas MUY BAJAS: ${datos.recuentoPlaquetasPltMin?.toStringAsFixed(0) ?? 'N/A'}k /µL (< 50k)', // Asume que el valor ya está en K
  },
  'CREATININA_MAYOR_1_2': {
    'condition':
        (DatosClinicos datos) =>
            datos.creatininaEstanciaMax != null && datos.creatininaEstanciaMax! > 1.2,
    'text':
        (DatosClinicos datos) =>
            'Creatinina: ${datos.creatininaEstanciaMax?.toStringAsFixed(2) ?? 'N/A'} mg/dL (> 1.2)',
  },
  'TRANSAMINASAS_ELEVADAS': {
    'condition':
        (DatosClinicos datos) =>
            (datos.gotAspartatoAminotransferasaMax != null &&
                datos.gotAspartatoAminotransferasaMax! > 70) ||
            (datos.gptIngreso != null && datos.gptIngreso! > 70),
    'text':
        (DatosClinicos datos) =>
            'Transaminasas Elevadas (GOT max: ${datos.gotAspartatoAminotransferasaMax?.toStringAsFixed(0) ?? 'N/A'}, GPT ing: ${datos.gptIngreso?.toStringAsFixed(0) ?? 'N/A'}) (> 70 U/L aprox)',
  },
  // Añadir otras condiciones relevantes si tienes los datos...
}; */

// *** CORREGIDO: Acepta DatosClinicos y usa las condiciones actualizadas ***
String formatTextInputForModel(DatosClinicos datos) {
  final findings = <String>[];

  alertConditions.forEach((key, config) {
    try {
      // Llama a la función 'condition' pasando el objeto 'datos'
      if ((config['condition'] as bool Function(DatosClinicos))(datos)) {
        // Llama a la función 'text' pasando el objeto 'datos'
        findings.add('*   ${(config['text'] as String Function(DatosClinicos))(datos)}');
      }
    } catch (e) {
      // Manejo de error si una condición falla (ej. por datos null)
      print("Error evaluando condición '$key': $e");
      // Opcional: podrías añadir un mensaje de error a findings
      // findings.add("*   Error evaluando $key");
    }
  });

  if (findings.isEmpty) {
    findings.add('*   Sin hallazgos de alerta significativos registrados.');
  }

  return '''Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos. Responde únicamente con una de las categorías: Bajo, Moderado, Alto, Crítico.\n\nHallazgos Clínicos Relevantes:\n${findings.join('\n')}''';
}

class VertexAiClient {
  final auth.ServiceAccountCredentials _credentials;
  final List<String> _scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  auth.AutoRefreshingAuthClient? _authClient;

  /// Constructor privado. Usa [fromServiceAccountJson] en su lugar.
  VertexAiClient._(this._credentials);

  /// Crea una instancia cargando el JSON desde [jsonString].
  factory VertexAiClient.fromServiceAccountJson(String jsonString) {
    final creds = auth.ServiceAccountCredentials.fromJson(jsonString);
    return VertexAiClient._(creds);
  }

  /// Asegura que [_authClient] esté inicializado y autenticado.
  Future<void> _ensureAuthClient() async {
    if (_authClient != null) return;
    _authClient = await auth.clientViaServiceAccount(_credentials, _scopes);
  }

  /// Llama al endpoint de Vertex AI usando streamGenerateContent.
  Future<String?> callVertex({
    required DatosClinicos datos,
    required String pacienteId,
    required String doctorId,
    required FirestoreService firestoreService,
  }) async {
    try {
      // 1) Autenticación con cuenta de servicio
      await _ensureAuthClient();
      final client = _authClient!;

      // 2) Formatear prompt
      final input = formatTextInputForModel(datos);
      if (kDebugMode) {
        print('>>> Prompt Vertex (ID: ${datos.id}):\n$input');
      }

      // 3) URI y body
      const projectId = '877846277125';
      const location = 'us-central1';
      const endpointId = '8317116070334824448';
      final uri = Uri.parse(
        'https://us-central1-aiplatform.googleapis.com/v1/'
        'projects/$projectId/locations/$location/'
        'endpoints/$endpointId:streamGenerateContent',
      );
      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': input},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': 100, 'temperature': 0.7, 'topP': 0.9},
      });

      // 4) Envío de la petición en streaming
      final request =
          http.Request('POST', uri)
            ..headers['Content-Type'] = 'application/json; charset=utf-8'
            ..body = body;
      final streamed = await client.send(request);

      if (streamed.statusCode != 200) {
        final err = await streamed.stream.bytesToString();
        throw HttpException('HTTP ${streamed.statusCode}: $err', uri: uri);
      }

      // 5) Leer respuesta
      final buffer = StringBuffer();
      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
      }

      // 6) Parsear JSON y extraer "riesgo"
      final payload = jsonDecode(buffer.toString()) as List<dynamic>;
      // Dependiendo de tu modelo podrías necesitar ajustar el índice.
      final secondObj =
          payload.length > 1
              ? payload[1] as Map<String, dynamic>
              : payload[0] as Map<String, dynamic>;
      final candidates = (secondObj['candidates'] as List).cast<dynamic>();
      final textField = (candidates[0]['content']['parts'][0]['text'] as String);
      final match = RegExp(r'riesgo"\s*:\s*"([^"]+)"').firstMatch(textField);
      final riesgo = match?.group(1) ?? 'Inválido';

      // 7) Guardar log en Firestore
      await firestoreService.saveAIConsultationLog(
        pacienteId: pacienteId,
        doctorId: doctorId,
        inputPrompt: input,
        modelResponse: riesgo,
        modelName: uri.toString(),
        rawApiResponse: buffer.toString(),
      );

      if (kDebugMode) {
        print('>>> Riesgo extraído: $riesgo');
      }
      return riesgo;
    } on auth.ServerRequestFailedException catch (e) {
      return 'Error de autenticación: ${e.message}';
    } on TimeoutException {
      return 'Error: Tiempo de espera agotado al conectar con Vertex AI.';
    } on SocketException {
      return 'Error: Verifica tu conexión a Internet.';
    } on HttpException catch (e) {
      return 'Error servidor: ${e.message}';
    } on FormatException {
      return 'Error: Respuesta malformada de Vertex AI.';
    } catch (e) {
      return 'Error inesperado: $e';
    }
  }
}

/// Función para inicializar tu cliente usando el asset JSON.
/// Llama a esto antes de usar [VertexAiClient.callVertex].
Future<VertexAiClient> initVertexClient() async {
  // Carga el JSON de la cuenta de servicio desde assets
  final jsonString = await rootBundle.loadString('assets/salud-materna-ServiceAccount.json');
  return VertexAiClient.fromServiceAccountJson(jsonString);
} */

// *** ALERT CONDITIONS ACTUALIZADO ***
// Usa los nombres de propiedad de la clase DatosClinicos
final alertConditions = {
  // --- Eventos/Diagnósticos Máxima Alerta ---
  'HEMORRAGIA_MAYOR': {
    'condition': (DatosClinicos d) => d.diagPrincipalHemorragia == true,
    'text':
        (DatosClinicos d) =>
            'Evento Máxima Alerta: Hemorragia Obstétrica Mayor (Diagnóstico Principal)',
  },
  'ECLAMPSIA_CONVULSIONES': {
    'condition':
        (DatosClinicos d) =>
            d.diagPrincipalThe == true && d.conscienciaIngreso?.toLowerCase() != 'alerta',
    'text':
        (DatosClinicos d) =>
            'Evento Máxima Alerta: Sospecha Eclampsia / Convulsiones (THE + No Alerta)',
  },
  'SEPSIS_SHOCK_SEPTICO': {
    // Proxy: Hipotensión + Taquicardia (usando MIN de PAD y MAX de FC durante estancia)
    'condition':
        (DatosClinicos d) =>
            (d.pasEstanciaMin != null && d.pasEstanciaMin! < 90) ||
            (d.padEstanciaMin != null && d.padEstanciaMin! < 60) &&
                (d.fCardiacaEstanciaMax != null && d.fCardiacaEstanciaMax! > 120),
    'text':
        (DatosClinicos d) =>
            'Evento Máxima Alerta: Sospecha Sepsis Severa / Shock Séptico (Hipotensión + Taquicardia)',
  },
  'ROTURA_UTERINA': {
    'condition': (DatosClinicos d) => d.waosRoturaUterinaDuranteElParto == true,
    'text': (DatosClinicos d) => 'Evento Máxima Alerta: Rotura Uterina',
  },
  'INGRESO_UCI': {
    'condition': (DatosClinicos d) => d.manejoEspecificoIngresoUci == true,
    'text': (DatosClinicos d) => 'Evento Máxima Alerta: Ingreso a UCI Requerido',
  },
  'CIRUGIA_MAYOR_EMERG': {
    'condition': (DatosClinicos d) => d.manejoQxLaparotomia == true,
    'text': (DatosClinicos d) => 'Evento Máxima Alerta: Cirugía Mayor de Emergencia (Laparotomía)',
  },
  'TRANSFUSION_MASIVA': {
    'condition':
        (DatosClinicos d) => d.unidadesTransfundidas != null && d.unidadesTransfundidas! >= 4,
    'text':
        (DatosClinicos d) =>
            'Evento Máxima Alerta: Transfusión Masiva (${d.unidadesTransfundidas} UGRE)',
  },
  // --- Signos Vitales de Alerta ---
  'CONSCIENCIA_NO_ALERTA': {
    'condition': (DatosClinicos d) => d.conscienciaIngreso?.toLowerCase() != 'alerta',
    'text': (DatosClinicos d) => 'Estado de Conciencia: No Alerta',
  },
  'PAS_MENOR_90': {
    'condition': (DatosClinicos d) => d.pasEstanciaMin != null && d.pasEstanciaMin! < 90,
    'text':
        (DatosClinicos d) =>
            'Presión Arterial Sistólica (PAS): ${d.pasEstanciaMin?.toStringAsFixed(0) ?? 'N/A'} mmHg (< 90)',
  },
  'PAS_MAYOR_160': {
    'condition': (DatosClinicos d) => d.pasIngresoAlta != null && d.pasIngresoAlta! > 160,
    'text':
        (DatosClinicos d) =>
            'Presión Arterial Sistólica (PAS): ${d.pasIngresoAlta?.toStringAsFixed(0) ?? 'N/A'} mmHg (> 160) (Valor Ingreso)',
  },
  'PAD_MENOR_60': {
    'condition': (DatosClinicos d) => d.padEstanciaMin != null && d.padEstanciaMin! < 60,
    'text':
        (DatosClinicos d) =>
            'Presión Arterial Diastólica (PAD): ${d.padEstanciaMin?.toStringAsFixed(0) ?? 'N/A'} mmHg (< 60)',
  },
  'PAD_MAYOR_110': {
    // Usando PAD Ingreso BAJA como proxy (¡Revisar si es correcto!)
    'condition': (DatosClinicos d) => d.padIngresoBaja != null && d.padIngresoBaja! > 110,
    'text':
        (DatosClinicos d) =>
            'Presión Arterial Diastólica (PAD): ${d.padIngresoBaja?.toStringAsFixed(0) ?? 'N/A'} mmHg (> 110) (Valor Ingreso - Baja)',
  },
  'FC_MAYOR_120': {
    'condition':
        (DatosClinicos d) => d.fCardiacaEstanciaMax != null && d.fCardiacaEstanciaMax! > 120,
    'text':
        (DatosClinicos d) =>
            'Frecuencia Cardíaca (FC): ${d.fCardiacaEstanciaMax?.toStringAsFixed(0) ?? 'N/A'} lpm (> 120)',
  },
  'FC_MENOR_50': {
    'condition':
        (DatosClinicos d) => d.fCardiacaEstanciaMin != null && d.fCardiacaEstanciaMin! < 50,
    'text':
        (DatosClinicos d) =>
            'Frecuencia Cardíaca (FC): ${d.fCardiacaEstanciaMin?.toStringAsFixed(0) ?? 'N/A'} lpm (< 50)',
  },
  'FR_MAYOR_30': {
    'condition':
        (DatosClinicos d) => d.fRespiratoriaIngresoAlta != null && d.fRespiratoriaIngresoAlta! > 30,
    'text':
        (DatosClinicos d) =>
            'Frecuencia Respiratoria (FR): ${d.fRespiratoriaIngresoAlta?.toStringAsFixed(0) ?? 'N/A'} rpm (> 30) (Valor Ingreso)',
  },
  'FR_MENOR_10': {
    'condition':
        (DatosClinicos d) => d.fRespiratoriaIngresoAlta != null && d.fRespiratoriaIngresoAlta! < 10,
    'text':
        (DatosClinicos d) =>
            'Frecuencia Respiratoria (FR): ${d.fRespiratoriaIngresoAlta?.toStringAsFixed(0) ?? 'N/A'} rpm (< 10) (Valor Ingreso)',
  },
  // --- Parámetros de Laboratorio Críticos ---
  'HB_MENOR_7': {
    // Usa el MIN de estancia si existe, sino el de ingreso
    'condition':
        (DatosClinicos d) =>
            (d.hemoglobinaEstanciaMin != null && d.hemoglobinaEstanciaMin! < 7.0) ||
            (d.hemoglobinaIngreso != null && d.hemoglobinaIngreso! < 7.0),
    'text': (DatosClinicos d) {
      final val = d.hemoglobinaEstanciaMin ?? d.hemoglobinaIngreso;
      final suffix = d.hemoglobinaEstanciaMin != null ? '' : ' (Ingreso)';
      return 'Hemoglobina (Hb): ${val?.toStringAsFixed(1) ?? 'N/A'} g/dL (< 7.0)$suffix';
    },
  },
  'PLAQUETAS_MENOR_100K': {
    'condition':
        (DatosClinicos d) =>
            d.recuentoPlaquetasPltMin != null &&
            d.recuentoPlaquetasPltMin! < 100, // El valor ya está en miles (k) en el JSON original
    'text':
        (DatosClinicos d) =>
            'Plaquetas: ${d.recuentoPlaquetasPltMin?.toStringAsFixed(0) ?? 'N/A'}k /µL (< 100k)',
  },
  'PLAQUETAS_MENOR_50K': {
    'condition':
        (DatosClinicos d) => d.recuentoPlaquetasPltMin != null && d.recuentoPlaquetasPltMin! < 50,
    'text':
        (DatosClinicos d) =>
            'Plaquetas MUY BAJAS: ${d.recuentoPlaquetasPltMin?.toStringAsFixed(0) ?? 'N/A'}k /µL (< 50k)',
  },
  'CREATININA_MAYOR_1_2': {
    'condition':
        (DatosClinicos d) => d.creatininaEstanciaMax != null && d.creatininaEstanciaMax! > 1.2,
    'text':
        (DatosClinicos d) =>
            'Creatinina: ${d.creatininaEstanciaMax?.toStringAsFixed(2) ?? 'N/A'} mg/dL (> 1.2)',
  },
  'TRANSAMINASAS_ELEVADAS': {
    'condition':
        (DatosClinicos d) =>
            (d.gotAspartatoAminotransferasaMax != null &&
                d.gotAspartatoAminotransferasaMax! > 70) ||
            (d.gptIngreso != null && d.gptIngreso! > 70),
    'text':
        (DatosClinicos d) =>
            'Transaminasas Elevadas (GOT max: ${d.gotAspartatoAminotransferasaMax?.toStringAsFixed(0) ?? 'N/A'}, GPT ing: ${d.gptIngreso?.toStringAsFixed(0) ?? 'N/A'}) (> 70 U/L aprox)',
  },
  // --- Condiciones ELIMINADAS por falta de datos en JSON ---
  // 'SAO2_MENOR_92'
  // 'LDH_MAYOR_600'
  // 'LACTATO_MAYOR_2'
  // 'BILIRRUBINA_MAYOR_1_2'
  // 'OLIGURIA_ANURIA'
  // 'EDEMA_PULMONAR'
};

String formatTextInputForModel(DatosClinicos datos) {
  final findings = <String>[];

  // Iterar sobre las condiciones actualizadas
  alertConditions.forEach((key, config) {
    try {
      // Pasamos el objeto 'datos' completo a la condición y al texto
      if ((config['condition'] as bool Function(DatosClinicos))(datos)) {
        findings.add('*   ${(config['text'] as String Function(DatosClinicos))(datos)}');
      }
    } catch (e) {
      // Captura errores si una propiedad es null y no se maneja en condition/text
      print("Error evaluando condición '$key': $e");
    }
  });

  if (findings.isEmpty) {
    findings.add('*   Sin hallazgos de alerta significativos registrados.');
  }

  return '''Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos. Responde únicamente con una de las categorías: Bajo, Moderado, Alto, Crítico.\n\nHallazgos Clínicos Relevantes:\n${findings.join('\n')}''';
}

class VertexAiClient {
  final auth.ServiceAccountCredentials _credentials;
  final List<String> _scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  auth.AutoRefreshingAuthClient? _authClient;

  VertexAiClient._(this._credentials);

  factory VertexAiClient.fromServiceAccountJson(String jsonString) {
    final creds = auth.ServiceAccountCredentials.fromJson(jsonString);
    return VertexAiClient._(creds);
  }

  Future<void> _ensureAuthClient() async {
    if (_authClient != null) return;
    _authClient = await auth.clientViaServiceAccount(_credentials, _scopes);
  }

  Future<String?> callVertex({
    required DatosClinicos datos,
    required String pacienteId,
    required String doctorId,
    required FirestoreService firestoreService,
  }) async {
    try {
      await _ensureAuthClient();
      final client = _authClient!;
      final input = formatTextInputForModel(datos); // Usa la función corregida
      if (kDebugMode) print('>>> Prompt Vertex (ID: ${datos.id}):\n$input');

      const projectId = 'salud-materna-eda0e'; // Reemplazar con tu Project ID real
      const location = 'us-central1';
      const endpointId = '8317116070334824448'; // ID de tu endpoint desplegado

      final uri = Uri.parse(
        'https://us-central1-aiplatform.googleapis.com/v1/'
        'projects/$projectId/locations/$location/'
        'endpoints/$endpointId:streamGenerateContent',
      );

      final body = jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': input},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': 100, 'temperature': 0.7, 'topP': 0.9},
      });

      final request =
          http.Request('POST', uri)
            ..headers['Content-Type'] = 'application/json; charset=utf-8'
            ..body = body;

      final streamedResponse = await client
          .send(request)
          .timeout(const Duration(seconds: 90)); // Aumentar timeout

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        print("Error Vertex AI (${streamedResponse.statusCode}): $errorBody");

        // Intentar parsear el error JSON si es posible
        String detailedError = errorBody;
        try {
          final errorJson = jsonDecode(errorBody);
          if (errorJson is Map && errorJson.containsKey('error') && errorJson['error'] is Map) {
            detailedError = errorJson['error']['message'] ?? errorBody;
          }
        } catch (_) {
          /* Ignorar error de parseo JSON */
        }

        // Guardar log de error
        await firestoreService.saveAIConsultationLog(
          pacienteId: pacienteId,
          doctorId: doctorId,
          inputPrompt: input,
          modelResponse: 'Error ${streamedResponse.statusCode} body: $errorBody', // Indicar error
          modelName: endpointId, // O el nombre que prefieras
          proyectId: projectId,
          location: location,
        );
        throw HttpException('HTTP ${streamedResponse.statusCode}: $detailedError', uri: uri);
      }

      final responseStringBuffer = StringBuffer();
      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // print("Chunk recibido: $chunk"); // Debug para ver los chunks
        responseStringBuffer.write(chunk);
      }
      final rawResponse = responseStringBuffer.toString();
      print("Respuesta completa Vertex: $rawResponse");

      // Parseo MÁS ROBUSTO de la respuesta en streaming JSON (puede venir en múltiples partes)
      String extractedText = 'Inválido'; // Valor por defecto
      try {
        // print("rawResponse: $rawResponse");

        // 6) Parsear JSON y extraer "riesgo"
        final result = jsonDecode(rawResponse) as List<dynamic>;
        // print('Respuesta Vertex: $result');
        // 3) Navega hasta el campo `text`
        final firstObj = result[1] as Map<String, dynamic>;
        // print('Riesgo extraído: $firstObj');
        final candidates = firstObj['candidates'] as List<dynamic>;
        // print('candidates: $candidates');
        final firstCand = candidates[0] as Map<String, dynamic>;
        // print('firstCand: $firstCand');
        final content = firstCand['content'] as Map<String, dynamic>;
        // print('content: $content');
        final parts = content['parts'] as List<dynamic>;
        // print('parts: $parts');
        final textField = parts[0]['text'] as String;
        // print('textField: $textField');
        // 1) Expresión regular para capturar el valor tras "riesgo":
        final regex = RegExp(r'riesgo"\s*:\s*"([^"]+)"');
        // 2) Intentar encontrar la primera coincidencia
        final match = regex.firstMatch(textField);
        // print('match: $match');
        // 3) Obtener el grupo capturado (el texto dentro de las comillas)
        extractedText = match?.group(1)?.toLowerCase() ?? 'Inválido (No Riesgo)';
        // print('riesgo: $extractedText');
      } catch (e) {
        print("Error parseando respuesta Vertex JSON: $e");
        extractedText = 'Inválido (Parseo Err)';
      }

      final riesgo = extractedText.isEmpty ? 'Inválido (Vacío)' : extractedText.capitalizeFirst();

      // Guardar log en Firestore
      await firestoreService.saveAIConsultationLog(
        pacienteId: pacienteId,
        doctorId: doctorId,
        inputPrompt: input,
        modelResponse: riesgo,
        modelName: endpointId, // Puedes usar el ID del endpoint o un nombre personalizado
        proyectId: projectId,
        location: location,
      );

      if (kDebugMode) print('>>> Riesgo extraído final: $riesgo');
      return riesgo;
    } on auth.ServerRequestFailedException catch (e) {
      print("Error Auth Vertex: ${e.message}");
      return 'Error de autenticación: ${e.message}';
    } on TimeoutException {
      print("Error Vertex: Timeout");
      return 'Error: Tiempo de espera agotado al conectar con Vertex AI.';
    } on SocketException catch (e) {
      print("Error Socket Vertex: ${e.message}");
      return 'Error: Verifica tu conexión a Internet.';
    } on HttpException catch (e) {
      print("Error HTTP Vertex: ${e.message}");
      return 'Error servidor: ${e.message}';
    } on FormatException catch (e) {
      print("Error Formato Vertex: ${e.message}");
      return 'Error: Respuesta malformada de Vertex AI.';
    } catch (e, s) {
      print("Error Inesperado Vertex: $e\n$s");
      return 'Error inesperado: $e';
    }
  }
}

Future<VertexAiClient> initVertexClient() async {
  final jsonString = await rootBundle.loadString('assets/salud-materna-ServiceAccount.json');
  return VertexAiClient.fromServiceAccountJson(jsonString);
}

// Helper (si no lo tienes ya en otro sitio)
extension StringExtensionVertex on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
