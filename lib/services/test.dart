import 'package:firebase_vertexai/firebase_vertexai.dart';

Future<String?> generateContentX() async {
  final generationConfig = GenerationConfig(
    maxOutputTokens: 8192,
    temperature: 1,
    topP: 0.95,
    responseMimeType: 'application/json',
  );
  final safetySettings = [
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none, null),
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none, null),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none, null),
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none, null),
  ];

  // Modelo de completions
  final model = FirebaseVertexAI.instanceFor(location: 'us-central1').generativeModel(
    model: 'projects/877846277125/locations/us-central1/endpoints/8317116070334824448',
    // model: 'projects/877846277125/locations/us-central1/endpoints/798356492439781376',
    // model: 'gemini-2.0-flash',
    generationConfig: generationConfig,
    safetySettings: safetySettings,
  );

  final msg1Text1 =
      // 'Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos. Responde únicamente con una de las categorías: Bajo, Moderado, Alto, Crítico.\\n\\nHallazgos Clínicos Relevantes:\\n*   Hemoglobina (Hb): 5.4 g/dL (< 7.0)\\n*   Plaquetas: 0k /µL (< 100k)\\n*   Plaquetas MUY BAJAS: 0k /µL (< 50k)\\n*   Transaminasas Elevadas (GOT max: 12, GPT ing: 611) (> 70 U/L aprox)';
      'Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos. Responde únicamente con una de las categorías: Bajo, Moderado, Alto, Crítico.\n\nHallazgos Clínicos Relevantes:\n*   Presión Arterial Diastólica (PAD): 49 mmHg (< 60)\n*   Plaquetas: 0k /µL (< 100k)\n*   Plaquetas MUY BAJAS: 0k /µL (< 50k)\n\nClasificación de Riesgo:';
  // For multi-turn responses, start a chat session.
  // final chat = model.startChat();
  // Prompt de solo texto (no se usa en este flujo, pero si lo necesitas, usa Content y TextPart)
  final prompt = Content('user', [
    TextPart('''
    Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos.
    Responde únicamente con una de las categorías: Crítico, Alto, Moderado, Bajo.
    Hallazgos Clínicos Relevantes:
    * Hemoglobina (Hb): 5.4 g/dL (< 7.0)
    * Plaquetas: 0k /µL (< 100k)
    * Plaquetas MUY BAJAS: 40k /µL (< 50k)
    * Transaminasas Elevadas (GOT max: 12, GPT ing: 611) (> 70 U/L aprox)
    '''),
  ]);

  String? respuesta;
  try {
    final respuesta = await model.generateContent([Content.text(msg1Text1)]);
    // final respuesta = await model.generateContent([prompt]);
    // respuesta = await sendMessage(chat, content);
    // respuesta = await sendMessage(chat, prompt);
    print(['respuesta', respuesta.text]);
  } catch (e) {
    print('Error llamando a sendMessage: $e');
    respuesta = 'Error en sendMessage';
  }
  return respuesta;
}

Future<String?> generateContentX2() async {
  final generationConfig = GenerationConfig(maxOutputTokens: 8192, temperature: 1, topP: 0.95);
  final safetySettings = [
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none, null),
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none, null),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none, null),
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none, null),
  ];

  // Modelo de completions
  final model = FirebaseVertexAI.instance.generativeModel(model: 'gemini-2.0-flash');

  // Provide a prompt that contains text
  final prompt = [
    Content.text('''
    Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos.
    Responde únicamente con una de las categorías: Bajo, Moderado, Alto, Crítico.
    Hallazgos Clínicos Relevantes:
    * Hemoglobina (Hb): 5.4 g/dL (< 7.0)
    * Plaquetas: 0k /µL (< 100k)
    * Plaquetas MUY BAJAS: 0k /µL (< 50k)
    * Transaminasas Elevadas (GOT max: 12, GPT ing: 611) (> 70 U/L aprox)
    '''),
  ];

  // To generate text output, call generateContent with the text input
  // final response = await model.generateContent(prompt);
  // print(response.text);
  // String? respuesta;
  try {
    // respuesta = await sendMessage(chat, Content('user', [TextPart(msg1Text1)]));
    final respuesta = await model.generateContent(prompt);
    print(['respuesta', respuesta.text]);
  } catch (e) {
    print('Error llamando a sendMessage: $e');
  }
  return 'respuesta';

  // return response.text;
}

Future<String?> sendMessage(ChatSession chat, Content content) async {
  GenerateContentResponse response;
  try {
    response = await chat.sendMessage(content);
    print(response.text);
  } catch (e) {
    print('Error llamando al modelo: $e');
    return 'Error en la consulta al modelo';
  }
  return response.text;
}
