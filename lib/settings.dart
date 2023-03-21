import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitchat/constants.dart';

class Settings {
  final SharedPreferences prefs;

  Settings({required this.prefs});

  String get openaiApiKey => prefs.getString(Constants.apiKeyKey) ?? '';

  set openaiApiKey(String value) {
    prefs.setString(Constants.apiKeyKey, value);
  }

  String get promptString => prefs.getString(Constants.promptStringKey) ?? '';

  set promptString(String value) {
    prefs.setString(Constants.promptStringKey, value);
  }

  double get temperatureValue =>
      prefs.getDouble(Constants.temperatureValueKey) ??
          Constants.defaultTemperatureValue;

  set temperatureValue(double value) {
    prefs.setDouble(Constants.temperatureValueKey, value);
  }

  bool get continueConversationEnable =>
      prefs.getBool(Constants.continueConversationEnableKey) ??
          Constants.defaultContinueConversationEnable;

  set continueConversationEnable(bool value) {
    prefs.setBool(Constants.continueConversationEnableKey, value);
  }

  bool get ttsEnable =>
      prefs.getBool(Constants.ttsEnableKey) ??
          Constants.defaultTtsEnable;

  set ttsEnable(bool value) {
    prefs.setBool(Constants.ttsEnableKey, value);
  }

  // new property for proxy settings
  String get proxyUrl => prefs.getString(Constants.proxyUrlKey) ?? '';

  set proxyUrl(String value) {
    prefs.setString(Constants.proxyUrlKey, value);
  }

  String get baseUrl => prefs.getString(Constants.baseUrlKey) ?? 'https://api.openai.com';

  set baseUrl(String value) {
    prefs.setString(Constants.baseUrlKey, value);
  }

}
