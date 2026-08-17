import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:aahar_app/theme.dart';
import 'package:aahar_app/screens/login_screen.dart';
import 'package:aahar_app/services/rag_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppTheme.surfaceContainerLowest,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Start RAG indexing in background (non-blocking)
  RagService.initialize();

  runApp(const AaharApp());
}

class AaharApp extends StatelessWidget {
  const AaharApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aahar - Precision Agriculture',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
