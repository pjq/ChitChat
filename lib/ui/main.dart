import 'package:flutter/material.dart';
import 'package:chitchat/screens/chat_screen.dart';
import 'package:chitchat/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.getInstance().then((prefs) {
    runApp(MyApp(prefs: prefs));
  });
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({Key? key, required this.prefs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAI Chat',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => ChatScreen(),
        '/settings': (context) => SettingsScreen(prefs: prefs),
      },
    );
  }
}
