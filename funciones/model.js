const { GoogleGenAI } = require('@google/genai');

// Initialize Vertex with your Cloud project and location
const ai = new GoogleGenAI({
  vertexai: true,
  project: '877846277125',
  location: 'us-central1'
});
const model = 'projects/877846277125/locations/us-central1/endpoints/798356492439781376';


// Set up generation config
const generationConfig = {
  maxOutputTokens: 8192,
  temperature: 1,
  topP: 0.95,
  responseModalities: ["TEXT"],
  speechConfig: {
    voiceConfig: {
      prebuiltVoiceConfig: {
        voiceName: "zephyr",
      },
    },
  },
  safetySettings: [
    {
      category: 'HARM_CATEGORY_HATE_SPEECH',
      threshold: 'OFF',
    },
    {
      category: 'HARM_CATEGORY_DANGEROUS_CONTENT',
      threshold: 'OFF',
    },
    {
      category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
      threshold: 'OFF',
    },
    {
      category: 'HARM_CATEGORY_HARASSMENT',
      threshold: 'OFF',
    }
  ],
};

const text1 = {text: `Instrucción: Evalúa el riesgo de morbilidad/mortalidad materna para una paciente con los siguientes hallazgos clínicos. Responde únicamente con una de las categorías: Bajo, Moderado, Alto, Crítico.\\n\\nHallazgos Clínicos Relevantes:\\n*   Hemoglobina (Hb): 5.4 g/dL (< 7.0)\\n*   Plaquetas: 0k /µL (< 100k)\\n*   Plaquetas MUY BAJAS: 0k /µL (< 50k)\\n*   Transaminasas Elevadas (GOT max: 12, GPT ing: 611) (> 70 U/L aprox)`};

async function generateContent() {
  const req = {
    model: model,
    contents: [
      {role: 'user', parts: [text1]}
    ],
    config: generationConfig,
  };

  const streamingResp = await ai.models.generateContentStream(req);

  for await (const chunk of streamingResp) {
    if (chunk.text) {
      process.stdout.write(chunk.text);
    } else {
      process.stdout.write(JSON.stringify(chunk) + '\n');
    }
  }
}

generateContent();