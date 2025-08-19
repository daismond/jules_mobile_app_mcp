import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_desktop/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domains/settings/data/settings_repository_impl.dart';
import 'presentation/chat_screen.dart';
import 'presentation/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final prefs = await SharedPreferences.getInstance();

    final initialSettingsRepo = SettingsRepositoryImpl(prefs);
    final initialApiKey = await initialSettingsRepo.getApiKey();
    final initialServerList = await initialSettingsRepo.getMcpServerList();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWith(
            (ref) =>
                SettingsRepositoryImpl(ref.watch(sharedPreferencesProvider)),
          ),
          apiKeyProvider.overrideWith((ref) => initialApiKey),
          mcpServerListProvider.overrideWith((ref) => initialServerList),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    // If initialization fails, show a fallback error screen
    debugPrint('FATAL: App initialization failed: $e\n$stackTrace');
    runApp(ErrorScreen(error: e));
  }
}

/// A fallback screen to display critical errors that occur on startup.
class ErrorScreen extends StatelessWidget {
  final Object error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'Application Initialization Failed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'A critical error occurred and the application cannot start. '
                  'Please try restarting the app. If the problem persists, '
                  'you may need to clear application data.\n\nError: $error',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Chat Desktop (Refactored)',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      routes: {
        '/': (context) => const ChatScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
