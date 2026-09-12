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

// Fonction pour générer une recette basée sur les ingrédients
export const generateRecipe = onCall(
  {
    secrets: ["AI_API_KEY"],
  },
  async (request) => {
    try {
      const ingredients = request.data.ingredients as string[];
      const guests = request.data.guests as number || 2;
      const utensils = (request.data.utensils as string[]) || [];
      
      const ai = new GoogleGenAI({ apiKey: process.env.AI_API_KEY });
      
      const utensilsText = utensils.length > 0 ? `Voici les ustensiles que je possède : ${utensils.join(", ")}.` : '';

      const prompt = `Tu es un chef cuisinier de renommée mondiale. 
Voici les ingrédients dont je dispose, avec leur quantité et unité en stock : 
${ingredients.join(", ")}.

${utensilsText}

Propose-moi une seule recette détaillée pour ${guests} personne(s), étape par étape, qui utilise en priorité ces ingrédients et ustensiles. 
Tu peux utiliser quelques ingrédients mineurs que je n'ai pas en stock (ex: sel, poivre, huile, petites épices) si cela permet d'améliorer la recette. Cependant, n'utilise aucun ingrédient principal hors de mon stock.
Règle TRÈS importante : pour "usedIngredients", tu dois renvoyer une valeur "quantityUsed" convertie dans l'unité mathématique exacte du stock. Par exemple, si le stock est en grammes et que tu utilises "2 blancs de poulet", estime le poids et mets "quantityUsed" en grammes (ex: 250).

Ton retour doit être un JSON valide sous ce format :
{
  "title": "Nom de la recette",
  "prepTime": "Temps de préparation",
  "ingredients": [
    { "name": "Nom ingrédient", "quantity": 2, "unit": "pièces", "originalText": "2 blancs de poulet" }
  ],
  "steps": ["Étape 1", "Étape 2"],
  "usedIngredients": [
    { "name": "Nom de l'ingrédient issu de ma liste sans la parenthèse du stock", "quantityUsed": 250 }
  ]
}`;

      const response = await ai.models.generateContent({
        model: "gemini-3.6-flash",
        contents: prompt,
        config: {
          responseMimeType: "application/json",
        }
      });

      return { 
        result: response.text 
      };

    } catch (error) {
      logger.error("Erreur lors de la génération de recette :", error);
      throw new HttpsError("internal", "Impossible de générer la recette.");
    }
  }
);