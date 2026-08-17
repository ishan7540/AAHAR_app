/// Represents a single chat message in the Krishi AI chatbot.
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// Source references from the RAG retrieval (for bot messages).
  /// Each entry has 'source' (filename) and 'page' (page number).
  final List<Map<String, dynamic>> sources;

  /// Whether TTS is currently playing for this message.
  bool isPlaying;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources = const [],
    this.isPlaying = false,
  });
}
