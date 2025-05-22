import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/about_screen.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const StreetAIApp());
}

class StreetAIApp extends StatelessWidget {
  const StreetAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreeAIability',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.grey[100],
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFCEFF00)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/main': (context) => const MainScreen(),
        '/about': (context) => const AboutScreen(),
      },
    );
  }
}
