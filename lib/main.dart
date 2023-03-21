import 'dart:io';

import 'package:chitchat/screens/about_screen.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/screens/chat_screen.dart';
import 'package:chitchat/screens/settings_screen.dart';
import 'package:chitchat/screens/splash_screen.dart';
import 'package:chitchat/settings.dart';
import 'package:chitchat/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'generated/app_localizations.dart';
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
        '/': (context) => ChatScreen(settings: settings),
        '/settings': (context) => SettingsScreen(prefs: settings.prefs),
        '/splash': (context) => SplashScreen(),
        '/about': (context) => const AboutScreen(),
      },
      // home: SplashScreen(),
      // // Display the splash screen initially
      // onGenerateRoute: (RouteSettings settings) {
      //   if (settings.name == '/') {
      //     return MaterialPageRoute(
      //       builder: (context) => SplashScreen(),
      //       settings: RouteSettings(name: '/splash'),
      //     );
      //   } else if (settings.name == '/splash') {
      //     Future.delayed(
      //       const Duration(seconds: 2),
      //       () => Navigator.pushReplacementNamed(context, '/'),
      //     );
      //   } else if (settings.name == '/') {
      //     return MaterialPageRoute(
      //       builder: (context) => ChatScreen(),
      //       settings: settings,
      //     );
      //   }
      //   return null;
      // },
    );
  }
}
