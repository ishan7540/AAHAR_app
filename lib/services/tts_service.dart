import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-Speech service wrapping flutter_tts.
/// Supports English and Hindi, with play/pause/stop controls.
class TtsService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static bool _isSpeaking = false;
  static String _currentLanguage = 'en-IN';

  /// Whether TTS is currently speaking.
  static bool get isSpeaking => _isSpeaking;

  /// Current language code.
  static String get currentLanguage => _currentLanguage;

  /// Initialize TTS engine with default settings.
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // iOS specific
    if (Platform.isIOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }

    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _tts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
    });

    _isInitialized = true;
  }

  /// Speak the given text. Stops any current speech first.
  static Future<void> speak(String text) async {
    if (!_isInitialized) await initialize();
    
    // Stop any current speech
    await stop();

    // Clean text for speech (remove markdown formatting)
    final cleanText = _cleanForSpeech(text);
    if (cleanText.isEmpty) return;

    // Auto-detect language and set accordingly
    final hasHindi = RegExp(r'[\u0900-\u097F]').hasMatch(cleanText);
    if (hasHindi) {
      await _tts.setLanguage('hi-IN');
    } else {
      await _tts.setLanguage('en-IN');
    }

    _isSpeaking = true;
    await _tts.speak(cleanText);
  }

  /// Stop current speech.
  static Future<void> stop() async {
    if (!_isInitialized) return;
    _isSpeaking = false;
    await _tts.stop();
  }

  /// Pause current speech (Android only).
  static Future<void> pause() async {
    if (!_isInitialized) return;
    _isSpeaking = false;
    await _tts.pause();
  }

  /// Set speech rate (0.0 to 1.0).
  static Future<void> setSpeechRate(double rate) async {
    if (!_isInitialized) await initialize();
    await _tts.setSpeechRate(rate);
  }

  /// Set language manually.
  static Future<void> setLanguage(String languageCode) async {
    if (!_isInitialized) await initialize();
    _currentLanguage = languageCode;
    await _tts.setLanguage(languageCode);
  }

  /// Set a callback for when speech completes.
  static void setCompletionCallback(void Function() callback) {
    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      callback();
    });
  }

  /// Clean text for better TTS output.
  /// Removes markdown formatting, emojis, and special characters.
  static String _cleanForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'\*\*'), '') // Remove bold markers
        .replaceAll(RegExp(r'\*'), '') // Remove italic markers
        .replaceAll(RegExp(r'#{1,6}\s'), '') // Remove heading markers
        .replaceAll(RegExp(r'`[^`]*`'), '') // Remove inline code
        .replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1') // Links → text
        .replaceAll(RegExp(r'[•●◦▪]'), ',') // Replace bullets with pauses
        .replaceAll(RegExp(r'---+'), '') // Remove horizontal rules
        .replaceAll(RegExp(r'\n{2,}'), '. ') // Multiple newlines → pause
        .replaceAll(RegExp(r'\n'), ' ') // Single newlines → space
        .replaceAll(
            RegExp(
                r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
                unicode: true),
            '') // Remove emojis
        .replaceAll(RegExp(r'\s+'), ' ') // Collapse whitespace
        .trim();
  }

  /// Dispose TTS resources.
  static Future<void> dispose() async {
    await stop();
    // FlutterTts doesn't have a dispose method, stop is sufficient
  }
}
