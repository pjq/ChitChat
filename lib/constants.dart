class Constants {
  static const String apiKeyKey = 'openai_api_key';
  static const String promptStringKey = 'prompt_string';
  static const String temperatureValueKey = '1.0';
  static const String continueConversationEnableKey =
      'continue_conversation_enable';
  static const String localCacheEnableKey = 'local_cache_enable';
  static const String ttsEnableKey = 'tts_enable';
  static const String cacheHistoryKey = "chat_history";

  static const String ttsSelectedLanguageKey = 'ttsSelectedLanguage';
  static const String sttSelectedLanguageKey = 'sttSelectedLanguage';

  static const String selectedModelKey = "selectedModel";


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

  static String translationPrompt = "Play a role as translator, auto detect the language, if the text is LOCALE_ID, then translate to English, if other languages, then translate to LOCALE_ID, nothing else, do not write explanations:\n\n ";

  // static String translationPrompt = "I want you to act as an English translator, spelling corrector and improver. I will speak to you in any language and you will detect the language, translate it and answer in the corrected and improved version of my text, . I want you to replace my simplified A0-level words and sentences with more beautiful and elegant, upper level English words and sentences. Keep the meaning same, but make them more literary. I want you to only reply the correction, the improvements and nothing else, do not write explanations: ";
  static String rephrasePrompt = "Play a role as language expert,rephrase the folllowing content with original language, while keeping its meaning,  nothing else, do not write explanations:\n\n ";

  //animation duration
  static int scrollDuration = 100;

  static bool useStream = true;

  static String cachePromptKey ="prompt_list";

  static var defaultPrompt = "You are my personal Assistant";

  static var default_ai_model = "gpt-3.5-turbo";

  static int MAX_MESSAGE_COUNT_FOR_CONVERSTAION = 100;
}
