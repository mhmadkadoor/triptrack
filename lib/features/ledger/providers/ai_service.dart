import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import this
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_service.g.dart';

@riverpod
AiService aiService(Ref ref) {
  return AiService();
}

class AiService {
  late final GenerativeModel _model;

  AiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    // Used gemini-3-flash-preview per user request
    _model = GenerativeModel(model: 'gemini-3-flash-preview', apiKey: apiKey);
  }

  Future<List<String>> getSuggestions(List<String> currentExpenses) async {
    if (currentExpenses.isEmpty) {
      return [
        'Snacks',
        'Drinks',
        'Sim Card',
      ]; // Default suggestions if list is empty
    }

    final prompt =
        '''
Act as a travel planner. Here is a list of current expenses for a group trip:
${currentExpenses.join(', ')}

Based on this list, suggest exactly 3 to 5 complementary items the group might have forgotten to buy.
Return the response ONLY as a raw JSON array of strings. 
Example format: ["Item 1", "Item 2", "Item 3"]
Do not include any markdown formatting like ```json or ```.
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      final text = response.text;
      if (text == null) return [];

      // Clean up potential markdown code blocks if the model ignores the instruction
      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> jsonList = jsonDecode(cleanText);
      return jsonList.map((e) => e.toString()).toList();
    } catch (e) {
      // Fallback or error handling
      print('AI Service Error: $e');
      return [];
    }
  }
}
