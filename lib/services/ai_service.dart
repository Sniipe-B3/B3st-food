import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';

class AiService {
  // On pointe vers l'instance de Firebase Functions
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Envoie le texte à l'IA et retourne les actions sous forme de Map (JSON)
  Future<Map<String, dynamic>> sendToAssistant(String userText) async {
    try {
      // On appelle la fonction exactement par le nom donné en Node.js ('chatAIAssistant')
      final callable = _functions.httpsCallable('chatAIAssistant');
      
      // On exécute la fonction en lui passant le texte attendu
      final result = await callable.call({
        'text': userText,
      });

      // Le backend renvoie { "result": "{ \"actions\": [...] }" }
      // 1. On récupère la String JSON renvoyée par Gemini
      final String jsonString = result.data['result'] as String;
      
      // 2. On parse cette String en un objet Dart (Map) exploitable
      final Map<String, dynamic> jsonResponse = jsonDecode(jsonString);
      
      return jsonResponse;
      
    } on FirebaseFunctionsException catch (e) {
      print('Erreur Firebase Functions: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('Erreur inconnue: $e');
      rethrow;
    }
  }
}

