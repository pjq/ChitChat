class Constants {
  static const String apiKeyKey = 'openai_api_key';
  static const String promptStringKey = 'prompt_string';
  static const String temperatureValueKey = '1.0';
  static const String continueConversationEnableKey =
      'continue_conversation_enable';
  static const String localCacheEnableKey = 'local_cache_enable';

  static const double defaultTemperatureValue = 1.0;
  static const bool defaultContinueConversationEnable = false;
  static const bool defaultLocalCacheEnable = true;

  static const List<String> fontFamilies = [
    'Noto Sans',
    'Arial',
    'sans-serif',
  ];

  static String proxyUrlKey="proxy_url";
  static const String baseUrlKey = 'base_url';

  static String translationPrompt = "Play a role as translator, if the text is Chinese, then translate to English, if English, then Chinese: ";
  static String rephrasePrompt = "Play a role as language expert, use the same language to rephrase the text: ";

}
