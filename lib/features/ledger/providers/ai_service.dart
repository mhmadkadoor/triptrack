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

  Future<List<String>> getSuggestions(
    List<String> currentExpenses,
    List<String> currentShoppingItems,
  ) async {
    if (currentExpenses.isEmpty && currentShoppingItems.isEmpty) {
      return [
        'Snacks',
        'Drinks',
        'Sim Card',
      ]; // Default suggestions if list is empty
    }

    final prompt =
        '''
You are a travel planner. The group has already bought: $currentExpenses. They are currently planning to buy: $currentShoppingItems. Suggest 3 to 5 complementary items they are missing. Do not suggest anything already on these lists. Return EXACTLY a raw JSON array of strings (e.g., ["Item 1", "Item 2"]).
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
