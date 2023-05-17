
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:chitchat/screens/chat_screen_with_prompt.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/screens/chat_screen.dart';
import 'package:chitchat/models/settings.dart';
import 'package:chitchat/models/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


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
      title: 'ChitChat',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily:
        Constants.fontFamilies.join(', '), // Use the new font families
      ),
      initialRoute: '/',
      routes: {
        '/': (context) {
          if (Platform.isMacOS || Platform.isWindows || Platform.isLinux || Platform.isFuchsia || kIsWeb) {
            return ChatScreenWithPrompt(settings: settings);
          } else {
            return ChatScreen(settings: settings);
          }
        }
      },
      debugShowCheckedModeBanner: false,
    );
  }

}
