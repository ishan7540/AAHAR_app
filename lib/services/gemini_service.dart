import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for communicating with the Gemini API.
/// Uses gemini-2.5-flash for chat generation and gemini-embedding-2 for embeddings.
class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String _chatModel = 'gemini-2.5-flash';
  static const String _embeddingModel = 'gemini-embedding-2';

  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Generate a chat response using RAG context.
  ///
  /// [query] is the user's question.
  /// [contextChunks] are the relevant document chunks retrieved from the vector store.
  /// [conversationHistory] is the list of previous messages for multi-turn context.
  static Future<String> generateChatResponse({
    required String query,
    required List<Map<String, dynamic>> contextChunks,
    List<Map<String, String>>? conversationHistory,
  }) async {
    final systemPrompt = _buildSystemPrompt(contextChunks);

    // Build contents array with conversation history
    final List<Map<String, dynamic>> contents = [];

    // Add conversation history if available (last 6 turns max)
    if (conversationHistory != null) {
      final recentHistory = conversationHistory.length > 6
          ? conversationHistory.sublist(conversationHistory.length - 6)
          : conversationHistory;
      for (final msg in recentHistory) {
        contents.add({
          'role': msg['role'],
          'parts': [
            {'text': msg['text']}
          ],
        });
      }
    }

    // Add current user query
    contents.add({
      'role': 'user',
      'parts': [
        {'text': query}
      ],
    });

    final url = Uri.parse(
        '$_baseUrl/models/$_chatModel:generateContent?key=$_apiKey');

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.95,
        'topK': 40,
        'maxOutputTokens': 2048,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_ONLY_HIGH',
        },
      ],
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'] as Map<String, dynamic>?;
        if (content != null) {
          final parts = content['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String? ?? 'No response generated.';
          }
        }
      }
      return 'No response generated. Please try again.';
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
      throw Exception('Gemini API error (${response.statusCode}): $errorMsg');
    }
  }

  /// Generate embeddings for a list of text chunks.
  /// Uses batch embedding for efficiency.
  static Future<List<List<double>>> generateEmbeddings(
      List<String> texts) async {
    final List<List<double>> allEmbeddings = [];

    // Process in batches of 100 (API limit)
    for (int i = 0; i < texts.length; i += 100) {
      final batch = texts.sublist(
        i,
        i + 100 > texts.length ? texts.length : i + 100,
      );

      final url = Uri.parse(
          '$_baseUrl/models/$_embeddingModel:batchEmbedContents?key=$_apiKey');

      final requests = batch.map((text) {
        return {
          'model': 'models/$_embeddingModel',
          'content': {
            'parts': [
              {'text': text}
            ]
          },
          'taskType': 'RETRIEVAL_DOCUMENT',
        };
      }).toList();

      final body = jsonEncode({'requests': requests});

      final response = await http
          .post(url, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final embeddings = data['embeddings'] as List<dynamic>;
        for (final embedding in embeddings) {
          final values = (embedding['values'] as List<dynamic>)
              .map((v) => (v as num).toDouble())
              .toList();
          allEmbeddings.add(values);
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
        throw Exception(
            'Embedding API error (${response.statusCode}): $errorMsg');
      }
    }

    return allEmbeddings;
  }

  /// Generate an embedding for a single query text.
  static Future<List<double>> generateQueryEmbedding(String query) async {
    final url = Uri.parse(
        '$_baseUrl/models/$_embeddingModel:embedContent?key=$_apiKey');

    final body = jsonEncode({
      'model': 'models/$_embeddingModel',
      'content': {
        'parts': [
          {'text': query}
        ]
      },
      'taskType': 'RETRIEVAL_QUERY',
    });

    final response = await http
        .post(url, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final embedding = data['embedding'] as Map<String, dynamic>;
      return (embedding['values'] as List<dynamic>)
          .map((v) => (v as num).toDouble())
          .toList();
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMsg = errorBody['error']?['message'] ?? 'Unknown error';
      throw Exception(
          'Query embedding error (${response.statusCode}): $errorMsg');
    }
  }

  /// Build the system prompt with RAG context injected.
  static String _buildSystemPrompt(List<Map<String, dynamic>> contextChunks) {
    final buffer = StringBuffer();
    buffer.writeln('''You are **Krishi AI (कृषि AI)**, an intelligent agricultural assistant for Indian farmers built into the Aahar precision agriculture app.

Your knowledge comes from official government scheme documents and crop rotation guides. You MUST follow these rules:

1. **Answer ONLY based on the provided reference documents below.** If the answer is not found in the documents, say clearly: "This information is not available in my current knowledge base. Please consult your local Krishi Vigyan Kendra."
2. **Be bilingual** — respond in both English and Hindi when relevant.
3. **Be practical** — give actionable advice farmers can follow immediately.
4. **Cite sources** — mention the document name when referencing specific information.
5. **Format well** — use bullet points, numbered lists, and bold text for readability.
6. **Be concise** — keep responses focused and under 300 words unless the user asks for detail.''');

    if (contextChunks.isNotEmpty) {
      buffer.writeln('\n\n---\n📄 REFERENCE DOCUMENTS:\n');
      for (int i = 0; i < contextChunks.length; i++) {
        final chunk = contextChunks[i];
        final source = chunk['source'] ?? 'Unknown';
        final page = chunk['page'] ?? '?';
        buffer.writeln('**[Source ${i + 1}: $source, Page $page]**');
        buffer.writeln(chunk['text'] ?? '');
        buffer.writeln('');
      }
      buffer.writeln('---');
    }

    return buffer.toString();
  }
}
