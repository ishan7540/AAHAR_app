import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:aahar_app/theme.dart';
import 'package:aahar_app/models/chat_message.dart';
import 'package:aahar_app/services/rag_service.dart';
import 'package:aahar_app/services/gemini_service.dart';
import 'package:aahar_app/services/tts_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _conversationHistory = [];

  bool _isTyping = false;
  bool _isIndexing = false;
  String _indexingStatus = '';
  String? _errorMessage;

  // Track which message TTS is playing for
  int? _playingMessageIndex;

  final List<String> _suggestions = [
    'What is PM-KISAN scheme?',
    'Best crop rotation for wheat?',
    'Government farming schemes',
    'How to improve soil health?',
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize TTS
    await TtsService.initialize();
    TtsService.setCompletionCallback(() {
      if (mounted) {
        setState(() {
          if (_playingMessageIndex != null &&
              _playingMessageIndex! < _messages.length) {
            _messages[_playingMessageIndex!].isPlaying = false;
          }
          _playingMessageIndex = null;
        });
      }
    });

    // Add welcome message
    setState(() {
      _messages.add(ChatMessage(
        text:
            'Namaste! 🙏 I\'m **Krishi AI**, your farming assistant powered by AI.\n'
            'नमस्ते! मैं **कृषि AI** हूँ, आपका AI-संचालित खेती सहायक।\n\n'
            'I have knowledge about:\n'
            '• 📋 Government farming schemes / सरकारी कृषि योजनाएं\n'
            '• 🔄 Crop rotation guides / फसल चक्र मार्गदर्शन\n'
            '• 🌾 Agricultural best practices / कृषि सर्वोत्तम अभ्यास\n\n'
            '_Ask me anything! / कुछ भी पूछें!_',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });

    // Initialize RAG index
    if (!RagService.isReady) {
      setState(() {
        _isIndexing = true;
        _indexingStatus = 'Initializing knowledge base...';
      });

      try {
        await RagService.initialize(
          onProgress: (status) {
            if (mounted) {
              setState(() {
                _indexingStatus = status;
              });
            }
          },
        );
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to initialize knowledge base: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isIndexing = false;
          });
        }
      }
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (_isTyping) return;

    final userMessage = text.trim();
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'text': userMessage});

    try {
      // Step 1: Retrieve relevant chunks
      List<Map<String, dynamic>> contextChunks = [];
      if (RagService.isReady) {
        contextChunks = await RagService.search(userMessage);
      }

      // Step 2: Generate response with Gemini
      final response = await GeminiService.generateChatResponse(
        query: userMessage,
        contextChunks: contextChunks,
        conversationHistory: _conversationHistory,
      );

      // Add to conversation history
      _conversationHistory.add({'role': 'model', 'text': response});

      // Build source references
      final sources = contextChunks
          .map((c) => {
                'source': c['source'] as dynamic,
                'page': c['page'] as dynamic,
                'score': c['score'] as dynamic,
              })
          .toList();

      // De-duplicate sources by filename
      final seenSources = <String>{};
      final uniqueSources = sources.where((s) {
        final key = '${s['source']}_${s['page']}';
        if (seenSources.contains(key)) return false;
        seenSources.add(key);
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
            sources: uniqueSources,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            text:
                '⚠️ Sorry, I encountered an error. Please try again.\n\n_Error: ${e.toString()}_',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    }
  }

  void _toggleTts(int messageIndex) async {
    final message = _messages[messageIndex];

    if (message.isPlaying) {
      // Stop playing
      await TtsService.stop();
      setState(() {
        message.isPlaying = false;
        _playingMessageIndex = null;
      });
    } else {
      // Stop any currently playing message
      if (_playingMessageIndex != null &&
          _playingMessageIndex! < _messages.length) {
        await TtsService.stop();
        _messages[_playingMessageIndex!].isPlaying = false;
      }

      // Start playing this message
      setState(() {
        message.isPlaying = true;
        _playingMessageIndex = messageIndex;
      });

      await TtsService.speak(message.text);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    TtsService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            TtsService.stop();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy,
                  color: AppTheme.primaryContainer, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Krishi AI / कृषि AI',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  _isIndexing
                      ? 'Indexing...'
                      : _isTyping
                          ? 'Thinking...'
                          : 'Online',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _isIndexing
                            ? AppTheme.statusWarning
                            : AppTheme.statusOptimal,
                      ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (RagService.isReady)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'reindex') {
                  _reindexKnowledgeBase();
                } else if (value == 'clear') {
                  _clearChat();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'reindex',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Re-index PDFs'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep, size: 20),
                      SizedBox(width: 8),
                      Text('Clear Chat'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Indexing progress banner
          if (_isIndexing) _buildIndexingBanner(),

          // Error banner
          if (_errorMessage != null) _buildErrorBanner(),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index], index);
              },
            ),
          ),

          // Suggestion chips
          if (_messages.length <= 2 && !_isIndexing)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                separatorBuilder: (_, a) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ActionChip(
                    label: Text(
                      _suggestions[index],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primaryContainer,
                          ),
                    ),
                    backgroundColor:
                        AppTheme.primaryContainer.withValues(alpha: 0.08),
                    side: BorderSide(
                        color:
                            AppTheme.primaryContainer.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    onPressed: () => _sendMessage(_suggestions[index]),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.04),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Ask anything / कुछ भी पूछें...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceContainerHigh,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: _sendMessage,
                      enabled: !_isTyping,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: _isTyping ? null : AppTheme.primaryGradient,
                      color: _isTyping ? AppTheme.surfaceContainerHigh : null,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed:
                          _isTyping ? null : () => _sendMessage(_textController.text),
                      icon: Icon(
                        Icons.send,
                        color: _isTyping
                            ? AppTheme.onSurfaceVariant
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndexingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.statusWarning.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
              color: AppTheme.statusWarning.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.statusWarning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _indexingStatus,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        border: Border(
          bottom:
              BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.error, size: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.error,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: AppTheme.error),
            onPressed: () => setState(() => _errorMessage = null),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy,
                  color: AppTheme.primaryContainer, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppTheme.primaryContainer
                        : AppTheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft:
                          isUser ? const Radius.circular(20) : Radius.zero,
                      bottomRight:
                          isUser ? Radius.zero : const Radius.circular(20),
                    ),
                    boxShadow: isUser ? null : AppTheme.subtleShadow,
                  ),
                  child: isUser
                      ? Text(
                          message.text,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    height: 1.5,
                                  ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.onSurface,
                                  height: 1.5,
                                ),
                            strong: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                  height: 1.5,
                                ),
                            em: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                ),
                            listBullet: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.primaryContainer,
                                  height: 1.5,
                                ),
                            h1: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(color: AppTheme.onSurface),
                            h2: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppTheme.onSurface),
                            h3: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(color: AppTheme.onSurface),
                            blockSpacing: 8,
                          ),
                          shrinkWrap: true,
                          softLineBreak: true,
                        ),
                ),

                // Bot message actions: TTS + Sources
                if (!isUser) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TTS button
                      InkWell(
                        onTap: () => _toggleTts(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: message.isPlaying
                                ? AppTheme.primaryContainer
                                    .withValues(alpha: 0.15)
                                : AppTheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                message.isPlaying
                                    ? Icons.stop_circle_outlined
                                    : Icons.volume_up_outlined,
                                size: 14,
                                color: message.isPlaying
                                    ? AppTheme.primaryContainer
                                    : AppTheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                message.isPlaying ? 'Stop' : 'Listen',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: message.isPlaying
                                          ? AppTheme.primaryContainer
                                          : AppTheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Source citations
                  if (message.sources.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: message.sources.map((source) {
                        final sourceName =
                            (source['source'] as String?)?.replaceAll('.pdf', '') ??
                                'Unknown';
                        final page = source['page'] ?? '?';
                        // Truncate long source names
                        final displayName = sourceName.length > 20
                            ? '${sourceName.substring(0, 20)}...'
                            : sourceName;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryContainer
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.secondary
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.description_outlined,
                                size: 10,
                                color: AppTheme.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$displayName (p.$page)',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppTheme.secondary,
                                      fontSize: 9,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.smart_toy,
                color: AppTheme.primaryContainer, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: AppTheme.subtleShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
                const SizedBox(width: 10),
                Text(
                  RagService.isReady
                      ? 'Searching & thinking...'
                      : 'Thinking...',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.onSurfaceVariant
                .withValues(alpha: 0.3 + (0.4 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  void _reindexKnowledgeBase() async {
    setState(() {
      _isIndexing = true;
      _indexingStatus = 'Re-indexing knowledge base...';
    });

    try {
      await RagService.reindex(
        onProgress: (status) {
          if (mounted) {
            setState(() {
              _indexingStatus = status;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: '✅ Knowledge base has been re-indexed successfully!',
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Re-indexing failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isIndexing = false;
        });
      }
    }
  }

  void _clearChat() {
    TtsService.stop();
    setState(() {
      _messages.clear();
      _conversationHistory.clear();
      _playingMessageIndex = null;
      _messages.add(ChatMessage(
        text:
            'Chat cleared! 🗑️ Ask me anything about farming schemes or crop rotation.\n'
            'चैट साफ़! खेती की योजनाओं या फसल चक्र के बारे में कुछ भी पूछें।',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }
}
