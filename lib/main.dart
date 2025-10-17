import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get API key from environment variables
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Error: GEMINI_API_KEY not found in .env file',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Japanese Learning',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
