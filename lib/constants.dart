class Constants {
  static const String apiKeyKey = 'openai_api_key';
  static const String promptStringKey = 'prompt_string';
  static const String temperatureValueKey = '1.0';
  static const String continueConversationEnableKey =
      'continue_conversation_enable';
  static const String localCacheEnableKey = 'local_cache_enable';
  static const String ttsEnableKey = 'tts_enable';
  static const String cacheHistoryKey = "chat_history";

  static const double defaultTemperatureValue = 1.0;
  static const bool defaultContinueConversationEnable = false;
  static const bool defaultLocalCacheEnable = true;
  static const bool defaultTtsEnable= false;

  static const List<String> fontFamilies = [
    'Noto Sans',
    'Arial',
    'sans-serif',
  ];

  static String proxyUrlKey="proxy_url";
  static const String baseUrlKey = 'base_url';

  static String translationPrompt = "Play a role as translator, if the text is Chinese, then translate to English, if English, then translate to Chinese, nothing else, do not write explanations: ";
  // static String translationPrompt = "I want you to act as an English translator, spelling corrector and improver. I will speak to you in any language and you will detect the language, translate it and answer in the corrected and improved version of my text, . I want you to replace my simplified A0-level words and sentences with more beautiful and elegant, upper level English words and sentences. Keep the meaning same, but make them more literary. I want you to only reply the correction, the improvements and nothing else, do not write explanations: ";
  static String rephrasePrompt = "Play a role as language expert,rephrase the folllowing content with original language, while keeping its meaning,  nothing else, do not write explanations: ";

  //animation duration
  static int scrollDuration = 500;

  static bool useStream = true;

  static String cachePromptKey ="prompt_list";

  static var defaultPrompt = "You are my personal Assistant";

}
