class Constants {
  static const String apiKeyKey = 'openai_api_key';
  static const String promptStringKey = 'prompt_string';
  static const String temperatureValueKey = '1.0';
  static const String continueConversationEnableKey =
      'continue_conversation_enable';
  static const String localCacheEnableKey = 'local_cache_enable';
  static const String ttsEnableKey = 'tts_enable';
  static const String cacheHistoryKey = "chat_history";
  static const String streamModeEnableKey = 'stream_mode_enable';

  static const String ttsSelectedLanguageKey = 'ttsSelectedLanguage';
  static const String sttSelectedLanguageKey = 'sttSelectedLanguage';

  static const String selectedModelKey = "selectedModel";


  static const double defaultTemperatureValue = 1.0;
  static const bool defaultContinueConversationEnable = false;
  static const bool defaultLocalCacheEnable = true;
  static const bool defaultTtsEnable= false;
  static const bool defaultStreamModeEnable= true;

  static const List<String> fontFamilies = [
    'Noto Sans',
    'Arial',
    'sans-serif',
  ];

  static String proxyUrlKey="proxy_url";
  static const String baseUrlKey = 'base_url';

  static String translationPrompt = "Play a role as translator, auto detect the language, if the text is LOCALE_ID, then translate to English, if other languages, then translate to LOCALE_ID, Keep the meaning the same. Do not alter the original structure and formatting outlined in any way. Only give me the output and nothing else: \n\"\"\"\n"
      + "CONTENT"
      +"\n\"\"\"";

  // static String translationPrompt = "I will give you text content, you will rewrite it and translate the text into English language. \n
  // Keep the meaning the same. Do not alter the original structure and formatting outlined in any way. Only give me the output and nothing else. \n
  // Now, using the concepts above, translate the following text: \n
  // """ \n
  // """ \n
  // ";

  // static String translationPrompt = "I want you to act as an English translator, spelling corrector and improver. I will speak to you in any language and you will detect the language, translate it and answer in the corrected and improved version of my text, . I want you to replace my simplified A0-level words and sentences with more beautiful and elegant, upper level English words and sentences. Keep the meaning same, but make them more literary. I want you to only reply the correction, the improvements and nothing else, do not write explanations: ";
  static String rephrasePrompt = "Play a role as language expert,rephrase the folllowing content with original language, while keeping its meaning,  nothing else, do not write explanations:\n\"\"\"\n"
  + "CONTENT"
  +"\n\"\"\"";

  //animation duration
  static int scrollDuration = 100;

  static String cachePromptKey ="prompt_list";

  static var defaultPrompt = "You are my personal Assistant";

  static var defaultAIModel = "gpt-3.5-turbo-0613";

  // ignore: non_constant_identifier_names
  static int MAX_MESSAGE_COUNT_FOR_CONVERSTAION = 100;

  static var smart_string_review_prompt = "Play a role as the Strings Translations Reviewers, review the translations carefully and review as the NATIVE speaker, and ONLY show the incorrect translations, English is the default Language. Review it carefully with the context, point out the inaccurate translations, Show in the table, include the US English key, US English Label, Current Translation Label, Expected Translation Label, and Context.";

  static var word_class_engineer_prompt = "You are the world class software engineer.";
}
