import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/design.dart';
import 'screens/home_screen.dart';
import 'screens/main_screen.dart';
import 'screens/about_screen.dart';
import 'screens/community_designs_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env only in dev/local; skip if building with --dart-define
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (_) {
    // ignore: avoid_print
    print(
      'No local .env file found – assuming production build with --dart-define',
    );
  }

  await Hive.initFlutter();
  Hive.registerAdapter(DesignAdapter());
  await Hive.openBox<Design>('designs');

  runApp(const StreetAIApp());
}

class StreetAIApp extends StatelessWidget {
  const StreetAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreetAIbility',
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
        '/community': (context) => const CommunityDesignsScreen(),
      },
    );
  }
}
