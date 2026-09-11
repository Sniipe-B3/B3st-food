import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { GoogleGenAI } from "@google/genai";

// Déclaration de la fonction appelable depuis Flutter
export const chatAIAssistant = onCall(
  {
    // On indique à Firebase d'injecter la clé secrète dans cette fonction
    secrets: ["AI_API_KEY"],
  },
  async (request) => {
    try {
      // 1. Récupération du texte envoyé par Flutter
      const textFromFrontend = request.data.text;
      
      if (!textFromFrontend) {
        throw new HttpsError("invalid-argument", "Le texte est obligatoire.");
      }

      // 2. Initialisation de l'IA avec la clé sécurisée
      const ai = new GoogleGenAI({ apiKey: process.env.AI_API_KEY });

      // 3. Appel à Gemini avec la consigne de renvoyer du JSON
      const response = await ai.models.generateContent({
        model: "gemini-3.6-flash",
        contents: textFromFrontend,
        config: {
          responseMimeType: "application/json",
          systemInstruction: `Tu es un assistant IA. Tu dois analyser la demande de l'utilisateur et renvoyer une liste d'actions à effectuer sur l'interface.
          Ton retour doit OBLIGATOIREMENT être un objet JSON valide sous ce format :
          {
            "actions": [
              {
                "type": "create_task",
                "payload": { "title": "...", "description": "..." }
              }
            ]
          }`,
        }
      });

      // 4. Renvoi du résultat au frontend
      return { 
        result: response.text 
      };

    } catch (error) {
      logger.error("Erreur lors de l'appel à l'IA :", error);
      throw new HttpsError("internal", "Impossible de contacter l'assistant IA.");
    }
  }
);