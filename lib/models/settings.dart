import 'package:shared_preferences/shared_preferences.dart';
import 'package:chitchat/models/constants.dart';

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
      prefs.getBool(Constants.ttsEnableKey) ?? Constants.defaultTtsEnable;

  set ttsEnable(bool value) {
    prefs.setBool(Constants.ttsEnableKey, value);
  }

  bool get enableEnterKeyToSend =>
      prefs.getBool(Constants.enableEnterKeyToSendKey) ??
      Constants.defaultEnableEnterKeyToSend;

  set enableEnterKeyToSend(bool value) {
    prefs.setBool(Constants.enableEnterKeyToSendKey, value);
  }

  bool get streamModeEnable {
    if (prefs.getBool(Constants.useBTP) ?? false) {
      return false;
    } else {
      return prefs.getBool(Constants.streamModeEnableKey) ??
          Constants.defaultStreamModeEnable;
    }
  }

  set streamModeEnable(bool value) {
    prefs.setBool(Constants.streamModeEnableKey, value);
  }

  // new property for proxy settings
  String get proxyUrl => prefs.getString(Constants.proxyUrlKey) ?? '';
  String get btpKeyJson => prefs.getString(Constants.btpKeyJson) ?? '';

  set proxyUrl(String value) {
    prefs.setString(Constants.proxyUrlKey, value);
  }

  String get baseUrl =>
      prefs.getString(Constants.baseUrlKey) ?? 'https://api.openai.com';

  String get btpJsonKey => prefs.getString(Constants.btpKeyJson) ?? '';

  String get selectedModel =>
      prefs.getString(Constants.selectedModelKey) ?? Constants.defaultAIModel;

  set baseUrl(String value) {
    prefs.setString(Constants.baseUrlKey, value);
  }

  bool get useOpenAI => prefs.getBool(Constants.useOpenAI) ?? true;
  set useOpenAI(bool value) {
    prefs.setBool(Constants.useOpenAI, value);
  }

  bool get useBTP => prefs.getBool(Constants.useBTP) ?? false;
  set useBTP(bool value) {
    prefs.setBool(Constants.useBTP, value);
  }
}
