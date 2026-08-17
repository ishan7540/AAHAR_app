import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';

import 'package:aahar_app/services/gemini_service.dart';

/// A document chunk with its text, metadata, and embedding vector.
class DocumentChunk {
  final String text;
  final String source;
  final int page;
  List<double>? embedding;

  DocumentChunk({
    required this.text,
    required this.source,
    required this.page,
    this.embedding,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'source': source,
        'page': page,
        'embedding': embedding,
      };

  factory DocumentChunk.fromJson(Map<String, dynamic> json) {
    return DocumentChunk(
      text: json['text'] as String,
      source: json['source'] as String,
      page: json['page'] as int,
      embedding: (json['embedding'] as List<dynamic>?)
          ?.map((v) => (v as num).toDouble())
          .toList(),
    );
  }
}

/// RAG (Retrieval-Augmented Generation) service.
///
/// Handles:
/// 1. PDF text extraction from bundled assets
/// 2. Text chunking with overlap
/// 3. Embedding generation via Gemini API
/// 4. Local vector store persistence
/// 5. Similarity search for query retrieval
class RagService {
  static const List<String> _pdfAssets = [
    'pdf/AGRICULTURE.pdf',
    'pdf/Crop Rotation.pdf',
    'pdf/Crop-Rotation-in-Home-Gardens.pdf',
    'pdf/Garden-to-Table-Crop-Rotation.pdf',
    'pdf/Indian_Government_Farming_Schemes_2026_Compendium.pdf',
    'pdf/Keep-it-Moving-Crop-Rotation.pdf',
  ];

  static const int _chunkSize = 500;
  static const int _chunkOverlap = 100;
  static const int _topK = 5;
  static const String _indexFileName = 'rag_vector_index.json';
  static const int _indexVersion = 2; // Bump this to force re-index

  static List<DocumentChunk>? _chunks;
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// Whether the RAG index has been built and is ready.
  static bool get isReady => _isInitialized && _chunks != null;

  /// Whether the RAG index is currently being built.
  static bool get isInitializing => _isInitializing;

  /// Initialize the RAG pipeline:
  /// 1. Try loading cached index from disk
  /// 2. If no cache, extract PDFs, chunk, embed, and persist
  ///
  /// [onProgress] callback reports progress as (current step description).
  static Future<void> initialize({
    void Function(String status)? onProgress,
  }) async {
    if (_isInitialized || _isInitializing) return;
    _isInitializing = true;

    try {
      // Try loading from cache first
      onProgress?.call('Checking knowledge base cache...');
      final cached = await _loadCachedIndex();
      if (cached != null) {
        _chunks = cached;
        _isInitialized = true;
        _isInitializing = false;
        onProgress?.call('Knowledge base loaded from cache!');
        return;
      }

      // Extract text from all PDFs
      onProgress?.call('Extracting text from PDF documents...');
      final allChunks = <DocumentChunk>[];

      for (int i = 0; i < _pdfAssets.length; i++) {
        final assetPath = _pdfAssets[i];
        final fileName = assetPath.split('/').last;
        onProgress?.call(
            'Processing ${i + 1}/${_pdfAssets.length}: $fileName');

        try {
          final chunks = await _extractAndChunkPdf(assetPath);
          allChunks.addAll(chunks);
        } catch (e) {
          // Log but continue with other PDFs
          onProgress?.call('Warning: Could not process $fileName: $e');
        }
      }

      if (allChunks.isEmpty) {
        throw Exception('No text could be extracted from any PDF.');
      }

      // Generate embeddings
      onProgress?.call(
          'Generating embeddings for ${allChunks.length} text chunks...');
      final texts = allChunks.map((c) => c.text).toList();

      // Process embeddings in smaller sub-batches for progress feedback
      final batchSize = 20;
      final allEmbeddings = <List<double>>[];

      for (int i = 0; i < texts.length; i += batchSize) {
        final end = (i + batchSize > texts.length) ? texts.length : i + batchSize;
        final batch = texts.sublist(i, end);
        onProgress?.call(
            'Embedding chunks ${i + 1}-$end of ${texts.length}...');
        final embeddings = await GeminiService.generateEmbeddings(batch);
        allEmbeddings.addAll(embeddings);
      }

      // Assign embeddings to chunks
      for (int i = 0; i < allChunks.length; i++) {
        allChunks[i].embedding = allEmbeddings[i];
      }

      // Persist to disk
      onProgress?.call('Saving knowledge base to cache...');
      await _saveCachedIndex(allChunks);

      _chunks = allChunks;
      _isInitialized = true;
      onProgress?.call('Knowledge base ready! 🎉');
    } catch (e) {
      _isInitializing = false;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Search for the most relevant document chunks for a given query.
  /// Returns top-K chunks with their similarity scores.
  static Future<List<Map<String, dynamic>>> search(String query) async {
    if (_chunks == null || _chunks!.isEmpty) {
      throw Exception('RAG index not initialized. Call initialize() first.');
    }

    // Generate query embedding
    final queryEmbedding = await GeminiService.generateQueryEmbedding(query);

    // Compute cosine similarity with all chunks
    final scored = <MapEntry<int, double>>[];
    for (int i = 0; i < _chunks!.length; i++) {
      final chunkEmbedding = _chunks![i].embedding;
      if (chunkEmbedding != null) {
        final similarity = _cosineSimilarity(queryEmbedding, chunkEmbedding);
        scored.add(MapEntry(i, similarity));
      }
    }

    // Sort by similarity (descending) and take top-K
    scored.sort((a, b) => b.value.compareTo(a.value));
    final topK = scored.take(_topK);

    return topK.map((entry) {
      final chunk = _chunks![entry.key];
      return {
        'text': chunk.text,
        'source': chunk.source,
        'page': chunk.page,
        'score': entry.value,
      };
    }).toList();
  }

  // ─── Private helpers ─────────────────────────────────────────────

  /// Extract text from a PDF asset and chunk it.
  static Future<List<DocumentChunk>> _extractAndChunkPdf(
      String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final fileName = assetPath.split('/').last;

    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final chunks = <DocumentChunk>[];

    for (int pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
      // Extract text from the specific page
      final String pageText =
          PdfTextExtractor(document).extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);

      if (pageText.trim().isEmpty) continue;

      // Clean the text
      final cleanedText = _cleanText(pageText);
      if (cleanedText.isEmpty) continue;

      // Chunk the page text
      final pageChunks = _chunkText(cleanedText, fileName, pageIndex + 1);
      chunks.addAll(pageChunks);
    }

    document.dispose();
    return chunks;
  }

  /// Clean extracted PDF text.
  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'\s+'), ' ') // Collapse whitespace
        .replaceAll(RegExp(r'[^\x20-\x7E\u0900-\u097F\n]'),
            '') // Keep ASCII + Devanagari
        .trim();
  }

  /// Split text into overlapping chunks.
  static List<DocumentChunk> _chunkText(
      String text, String source, int page) {
    final chunks = <DocumentChunk>[];

    if (text.length <= _chunkSize) {
      chunks.add(DocumentChunk(text: text, source: source, page: page));
      return chunks;
    }

    int start = 0;
    while (start < text.length) {
      int end = start + _chunkSize;
      if (end > text.length) end = text.length;

      // Try to break at a sentence boundary
      if (end < text.length) {
        final lastPeriod = text.lastIndexOf('. ', end);
        if (lastPeriod > start + (_chunkSize ~/ 2)) {
          end = lastPeriod + 1;
        }
      }

      final chunkText = text.substring(start, end).trim();
      if (chunkText.isNotEmpty) {
        chunks.add(DocumentChunk(text: chunkText, source: source, page: page));
      }

      start = end - _chunkOverlap;
      if (start < 0) start = 0;
      if (start >= text.length) break;
    }

    return chunks;
  }

  /// Compute cosine similarity between two vectors.
  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0) return 0.0;
    return dotProduct / denominator;
  }

  /// Get the path for the local vector index cache.
  static Future<String> _getIndexPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$_indexFileName';
  }

  /// Try to load a cached vector index from disk.
  static Future<List<DocumentChunk>?> _loadCachedIndex() async {
    try {
      final path = await _getIndexPath();
      final file = File(path);
      if (!await file.exists()) return null;

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      // Check version
      final version = data['version'] as int? ?? 0;
      if (version != _indexVersion) return null;

      final chunksJson = data['chunks'] as List<dynamic>;
      return chunksJson
          .map((c) => DocumentChunk.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Save the vector index to disk for caching.
  static Future<void> _saveCachedIndex(List<DocumentChunk> chunks) async {
    final path = await _getIndexPath();
    final data = {
      'version': _indexVersion,
      'created': DateTime.now().toIso8601String(),
      'chunkCount': chunks.length,
      'chunks': chunks.map((c) => c.toJson()).toList(),
    };
    await File(path).writeAsString(jsonEncode(data));
  }

  /// Force re-index by deleting the cache and re-initializing.
  static Future<void> reindex({
    void Function(String status)? onProgress,
  }) async {
    try {
      final path = await _getIndexPath();
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    _isInitialized = false;
    _chunks = null;
    await initialize(onProgress: onProgress);
  }
}
