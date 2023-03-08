import 'package:flutter/material.dart';
import 'package:chatgpt_flutter/screens/chat_screen.dart';
import 'package:chatgpt_flutter/screens/settings_screen.dart';
import 'package:chatgpt_flutter/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final settings = Settings(prefs: prefs);

  runApp(MyApp(settings: settings));
}

class MyApp extends StatelessWidget {
  final Settings settings;

  const MyApp({Key? key, required this.settings}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAI Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => ChatScreen(settings: settings),
        '/settings': (context) => SettingsScreen(prefs: settings.prefs),
      },
    );
  }
}
