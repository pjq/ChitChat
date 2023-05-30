// ignore_for_file: library_private_types_in_public_api

import 'dart:async';
import 'dart:ui' as ui;
import 'package:chitchat/models/colors.dart';
import 'package:chitchat/utils/log_utils.dart';
import 'package:chitchat/models/global_data.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:chitchat/screens/syntax_highlight.dart';
import 'package:chitchat/screens/prompt_list_screen.dart';
import 'package:chitchat/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/models/settings.dart';
import 'package:chitchat/models/constants.dart';
import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/services/chat_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:chitchat/utils/Utils.dart';
import 'dart:collection';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key, Settings? settings}) : super(key: key);

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> implements IChatService {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  ChatService? _chatService;
  Settings? _settings;
  late SharedPreferences _prefs;

  ChatHistory? _history;
  String defaultAppTitle = "ChitChat";
  String appTitle = "";
  late Prompt currentPrompt;
  late PromptStorage promptStorage;

  final FlutterTts flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isSpeechToTextAvailable = false;
  String _lastRecognizedWords = "";
  String _currentLocaleId = '';
  String _currentLanguageCode = '';
  LocaleName? _sttSelectedLanguage;
  List<LocaleName> sttLocaleNames = [];
  List<dynamic> ttsLanguages = [];
  late AppLocalizations loc;

  bool _autoScrollEnabled = true;
  late ScrollController _chatListController;

  StreamSubscription? _streamSubscription;
  final StreamController<ChatMessage> _messageController =
      StreamController<ChatMessage>.broadcast();

  final FocusNode _focusNode = FocusNode();

  Queue<String> _messageQueue = Queue();
  bool _isSpeaking = false;
  static const int wordThreshold = 2;
  StringBuffer _wordBuffer = StringBuffer();

  @override
  void initState() {
    super.initState();
    LogUtils.info("init state");
    appTitle = defaultAppTitle;

    _streamSubscription = _messageController.stream.listen((data) {
      setState(() {
        _processData(data);
        // LogUtils.info("recv: ${_isLoading}, ${data.content}");
        //save to chat history
        // if (data.isStop) {
        //   _history?.addMessageWithPromptChannel(
        //       _messages.elementAt(_messages.length - 2), currentPrompt.id);
        //   _history?.addMessageWithPromptChannel(
        //       _messages.last, currentPrompt.id);
        //   _speak(_messages.last.content);
        //   // receive message finished
        //   _isLoading = false;
        // } else {
        //   if (_messages.last.content.startsWith("...")) {
        //     _messages.last.content = "";
        //   }
        //
        //   _messages.last.content += data.content;
        //   _listViewScrollToBottom();
        // }
      });
    });

    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      _settings = Settings(prefs: prefs);
      _chatService = ChatService(_messageController);

      setState(() {
        _history = ChatHistory(prefs: prefs);
        // _messages.addAll(_history!.messages);
        promptStorage = PromptStorage(prefs: prefs);
        currentPrompt = promptStorage.getSelectedPrompt();
        switchToPromptChannel(currentPrompt);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _listViewScrollToBottom();
        });
      });
    });

    _initializeSpeechRecognition();

    _chatListController = ScrollController();
    _chatListController.addListener(_onScrollStart);
    _chatListController.addListener(_onScrollEnd);
  }


  void _processData(dynamic data) {
    if (data.isStop) {
      _history?.addMessageWithPromptChannel(
          _messages.elementAt(_messages.length - 2), currentPrompt.id);
      _history?.addMessageWithPromptChannel(
          _messages.last, currentPrompt.id);
      // _speak(_messages.last.content);
      // receive message finished
      _isLoading = false;

      // Process the remaining words in the buffer
      if (_wordBuffer.isNotEmpty) {
        _messageQueue.add(_wordBuffer.toString());
        _wordBuffer.clear();

        if (!_isSpeaking) {
          _processQueue();
        }
      }

    } else {
      if (_messages.last.content.startsWith("...")) {
        _messages.last.content = "";
        _messageQueue.clear();
      }

      _messages.last.content += data.content;

      // Call _processQueue without blocking the UI
      if (true == _settings?.ttsEnable) {
        _wordBuffer.write(data.content);

        // If the number of words in the buffer reaches the threshold
        if (RegExp(r'(\,|\，|\"|\?|\.|\:|\;|\!|\-|\(|\)|[\u3000-\u303f\u3002\uff1b\uff0c\uff1a\uff1f])').allMatches(_wordBuffer.toString()).length >= wordThreshold) {
          // Enqueue the words and clear the buffer
          _messageQueue.add(_wordBuffer.toString());
          _wordBuffer.clear();

          // Call _processQueue without blocking the UI
          if (!_isSpeaking) {
            _processQueue();
          }
        }
      }

      _listViewScrollToBottom();
    }
  }

  void _processQueue() async {
    while (_messageQueue.isNotEmpty) {
      String messagePart = _messageQueue.removeFirst();
      await _speak(messagePart);
    }
  }

  void _onScrollStart() {
    setState(() {
      _autoScrollEnabled = false;
    });
  }

  void _onScrollEnd() {
    setState(() {
      _autoScrollEnabled = true;
    });
  }

  void handleSettingsChanged() {
    // Do the initialization here
    _initializeSpeechRecognition();
  }

  void startSettingsScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          prefs: _prefs,
          onSettingsChanged: handleSettingsChanged,
        ),
      ),
    );
  }

  Future<void> _initializeSpeechRecognition() async {
    bool available = await _speechToText.initialize(
      debugLogging: true,
      onError: (SpeechRecognitionError error) {
        LogUtils.debug("Error: ${error.errorMsg}");
        setState(() {
          _isListening = false;
        });
        showToast(error.errorMsg);
      },
      onStatus: (String status) {
        LogUtils.debug("Status: $status");

        if (status == "avalilable") {
          //   LogUtils.debug("Speech recognition available ${_isSpeechToTextAvailable}");
          //
          //   if (_isSpeechToTextAvailable) {
          //     // Get the list of languages installed on the supporting platform so they
          //     // can be displayed in the UI for selection by the user.
          //     _localeNames = _speechToText.locales();
          //     LogUtils.debug(_localeNames);
          //
          //     var systemLocale = _speechToText.systemLocale();
          //     _currentLocaleId = systemLocale?.localeId ?? '';
          //   }
          //
          setState(() {
            // _isSpeechToTextAvailable = true;
          });
        }
      },
    );

    setState(() {
      _isSpeechToTextAvailable = available;
    });

    LogUtils.debug("Speech recognition available $_isSpeechToTextAvailable");
    // Get the list of languages installed on the supporting platform so they
    // can be displayed in the UI for selection by the user.
    if (_isSpeechToTextAvailable) {
      sttLocaleNames = await _speechToText.locales();
      // for (var element in sttLocaleNames) {
      //    LogUtils.debug("sttLocaleNames: " + element.name + ", " + element.localeId);
      // }

      var systemLocale = await _speechToText.systemLocale();
      _currentLocaleId = systemLocale?.localeId ?? '';
      LogUtils.debug("_currentLocaleId: $_currentLocaleId");
    }

    _currentLanguageCode = ui.window.locale.toString();

    ttsLanguages = await flutterTts.getLanguages;
    LogUtils.debug("tts langs:");
    // for (var element in ttsLanguages) {
    //    LogUtils.debug("ttsLanguages: " + element);
    // }
    // [nn, bg, kea, mg, mr, zu, ko, hsb, ak, kde, lv, seh, dz, mgo, ia, kkj, sd-Arab, pa-Guru, mer, pcm, sah, mni, br, sk, ml, ast, yue-Hans, cs, sv, el, pa, rn, rwk, tg, hu, ks-Arab, af, twq, bm, smn, dsb, sd-Deva, khq, ku, tr, cgg, ksf, cy, yi, fr, sq, de, agq, sa, ebu, zh-Hans, lg, sat-Olck, ff, mn, sd, teo, eu, wo, shi-Tfng, xog, so, ru, az, su-Latn, fa, kab, ms, nus, nd, ug, kk, az-Cyrl, hi, tk, hy, shi-Latn, vai, vi, dyo, mi, mt, ksb, lb, luo, mni-Beng, yav, ne, eo, kam, su, ro, ee, pl, my, ka, ur, mgh, shi, uz-Arab, kl, se, chr, doi, zh, yue-Hant, saq, az-Latn, ta, lag, luy, bo, as, bez, it, kln, uk, kw, mai, vai-Latn, mzn, ii, tt, ksh, ln, naq, pt, tzm, gl, sr-Cyrl, ff-Adlm, fur, om, to, ga, qu, et, asa, mua, jv, id, ps, sn, rof, ff-Latn, km, zgh, be, fil, gv, uz-Cyrl, dua, es, jgo, fo, gsw, hr, lt, guz, mfe, ccp, ja, lkt, ceb, is, or, si, brx, en, ca, te, ks, ha, sl, sbp, nyn, jmc, yue, fi, mk, sat, bs-Cyrl, uz, pa-Arab, sr-Latn, bs, sw, fy, nmg, rm, th, bn, ar, vai-Vaii, haw, kn, dje, bas, nnh, sg, uz-La
    // await flutterTts.isLanguageAvailable("en-US")
    //     ? flutterTts.setLanguage("en-US")
    //     : flutterTts.setLanguage("en");
    flutterTts.setVolume(1.0);
    // await flutterTts.setSpeechRate(0.5);
    // await flutterTts.setVolume(1.0);
    // await flutterTts.setPitch(1.0);

    GlobalData().ttsLanguages.addAll(ttsLanguages.toSet().toList());
    GlobalData().sttLocaleNames.addAll(sttLocaleNames.toSet().toList());

    flutterTts.setCompletionHandler(() {
      _isSpeaking = false;

      // Process the remaining queue when the current speech is finished
      _processQueue();
    });


    updateTTSAndSTT();
  }

  void updateTTSAndSTT() {
    if (GlobalData().ttsLanguages.isNotEmpty) {
      String ttsSelectedLanguage =
          _settings?.prefs.getString(Constants.ttsSelectedLanguageKey) ??
              GlobalData().ttsLanguages[0];
      flutterTts.setLanguage(ttsSelectedLanguage);
    }

    if (GlobalData().sttLocaleNames.isNotEmpty) {
      String? savedSttSelectedLanguage =
          _settings?.prefs.getString(Constants.sttSelectedLanguageKey);

      LogUtils.debug("selected stt: $savedSttSelectedLanguage");
      if (savedSttSelectedLanguage == null) {
        // if not set before, just use the current localeId.
        _settings?.prefs
            .setString(Constants.sttSelectedLanguageKey, _currentLocaleId);
        savedSttSelectedLanguage = _currentLocaleId;
      }

      _sttSelectedLanguage = GlobalData().sttLocaleNames.firstWhere(
            (element) => savedSttSelectedLanguage == element.localeId,
            orElse: () => GlobalData().sttLocaleNames[0], // Set a default value
          );

      LogUtils.debug("selected stt: ${_sttSelectedLanguage!.localeId}");
    } else {
      setState(() {
        _isSpeechToTextAvailable = false;
      });
    }
  }


  void showToast(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  void _toggleListening() async {
    if (_isLoading) {
      return;
    }

    flutterTts.stop();
    Timer? listeningTimeout;

    void resetListeningTimeout() {
      listeningTimeout?.cancel();
      listeningTimeout = Timer(const Duration(milliseconds: 1000), () {
        if (_isListening) {
          _speechToText.stop();
          _sendMessage(_lastRecognizedWords);
          setState(() {
            _isListening = false;
            _controller.clear();
          });
        }
      });
    }

    if (_isListening) {
      _speechToText.stop();
      _sendMessage(_lastRecognizedWords);
      setState(() {
        _isListening = false;
      });
    } else {
      String? savedSelectedLanguage =
          _settings?.prefs.getString(Constants.sttSelectedLanguageKey);
      String localeId = savedSelectedLanguage ?? _currentLocaleId;
      LogUtils.debug("saved stt: $localeId");
      await _speechToText.listen(
        localeId: localeId,
        onResult: (SpeechRecognitionResult result) {
          setState(() {
            if (!_isLoading) {
              // If it's in the sending status, then no need update the input entry.
              _controller.text = result.recognizedWords;
              _lastRecognizedWords = result.recognizedWords;
            }
          });
          resetListeningTimeout();
        },
      );

      setState(() {
        _isListening = true;
      });
    }
  }

  // void _speak(String text) async {
  //   if (false == _settings?.ttsEnable) return;
  //
  //   LogUtils.debug("speak start");
  //   await flutterTts.speak(text);
  // }

  Future<void> _speak(String text) async {
    if (false == _settings?.ttsEnable) return;

    LogUtils.debug("speak start");
    _isSpeaking = true;
    await flutterTts.speak(text);
  }


  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
    _messageController.close();
    _focusNode.dispose();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    LogUtils.info("didChangeDependencies");
  }

  Future<String> _callAPI(
    String content,
  ) async {
    final completion = await _chatService!.getCompletion(
      content,
      _get5ChatHistory(),
      _settings,
      promptStorage,
    );

    return completion;
  }

  @override
  Future<String> translate(String content, String translationPrompt) async {
    setState(() {
      _isLoading = true;
    });
    // check the Constants.translationPrompt, it has the placeholder "CONTENT" for the real content.
    final completion = await _chatService!.getTranslation(
      translationPrompt.replaceAll("CONTENT", content),
      _settings!,
    );

    setState(() {
      if (!_settings!.streamModeEnable) {
        _isLoading = false;
      }
    });

    return completion;
  }

  void delete(ChatMessage message) {
    setState(() {
      _messages.remove(message);
      _history?.deleteMessageWithPromptChannel(message, currentPrompt.id);
    });
  }

  void deleteAllMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.delete),
        content: Text(loc.delete_all_messages_confirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _history?.deleteMessageForPromptChannel(currentPrompt.id);
                showToast(loc.conversationRecordsErased);
              });

              Navigator.pop(context);
            },
            child: Text(loc.delete),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) async {
    if (_isLoading) {
      return;
    }

    if (_settings!.openaiApiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.openai_api_key_not_set),
          content: Text(loc.kindly_configure_openai_api_key),
          actions: [
            TextButton(
                child: Text(loc.ok),
                onPressed: () {
                  Navigator.pop(context);
                  startSettingsScreen();
                }),
          ],
        ),
      );
      return;
    }

    if (text.isEmpty) {
      return;
    }

    _listViewScrollToBottom();

    final messageSend = ChatMessage(role: ChatMessage.ROLE_USER, content: text);
    _messages.add(messageSend);

    if (_settings!.streamModeEnable) {
      //add as a placeholder for the stream message.
      final messageSend =
          ChatMessage(role: ChatMessage.ROLE_ASSISTANT, content: "...");
      _messages.add(messageSend);
    }

    try {
      setState(() {
        _isLoading = true;
        _controller.clear();
        _controller.text = "";
      });

      final completion = await _callAPI(messageSend.content);

      setState(() {
        final messageReceived =
            ChatMessage(role: ChatMessage.ROLE_ASSISTANT, content: completion);
        if (!_settings!.streamModeEnable) {
          _isLoading = false;
          _messages.add(messageReceived);
          _history?.addMessageWithPromptChannel(messageSend, currentPrompt.id);
          _history?.addMessageWithPromptChannel(
              messageReceived, currentPrompt.id);
        } else {
        }
      });

      _listViewScrollToBottom();
    } catch (e) {
      LogUtils.error(e.toString());
      if (_settings!.streamModeEnable) {
        _messages.removeLast();
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(loc.failed_to_send_message),
            TextButton(
              child: Text(loc.retry),
              onPressed: () => _sendMessage(messageSend.content),
            ),
          ],
        ),
      ));
    }
  }

  List<ChatMessage>? _get5ChatHistory() {
    final recentHistory = _history?.getLatestMessages(currentPrompt.id);
    LogUtils.info("recentHistory length: $recentHistory");

    return _settings!.continueConversationEnable ? recentHistory : [];
  }

  // Add a new method to switch to a selected prompt channel.
  void switchToPromptChannel(Prompt promptChannel) {
    currentPrompt = promptChannel;
    LogUtils.info("currentPrompt: $currentPrompt");
    setState(() {
      appTitle = "$defaultAppTitle(${currentPrompt.title})";
      _messages.clear();
      if (null != _history) {
        _messages
            .addAll(_history!.getMessagesForPromptChannel(currentPrompt.id));
      }
      _listViewScrollToBottom();
      LogUtils.info("history size: ${_messages.length}");
    });
  }

  // Widget _buildChatMessage(ChatMessage message) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  //     margin: const EdgeInsets.symmetric(vertical: 5),
  //     decoration: BoxDecoration(
  //       color: message.isUser ? Colors.blue : Colors.grey[200],
  //       borderRadius: BorderRadius.circular(10),
  //     ),
  //     child: Text(
  //       message.content,
  //       style: TextStyle(
  //         color: message.isUser ? Colors.white : Colors.black,
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: !Utils.isBigScreen(context)? IconButton(
            icon: const Icon(Icons.list),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PromptListScreen(
                    onSelectedPrompt: (prompt) {
                      LogUtils.info("selected: $prompt");
                      setState(() {
                        switchToPromptChannel(prompt);
                      });
                    },
                    promptStorage: promptStorage,
                    history: _history!,
                  ),
                ),
              );
            },
          ): null,
          title: Text(appTitle),
          actions: [
            IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  startSettingsScreen();
                }),
            IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  deleteAllMessage();
                }),
          ],
        ),
        body: SafeArea(
          child: KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              if (isKeyboardVisible) {
                _listViewScrollToBottom();
              }

              return Column(
                children: [
                  Expanded(
                    child: Container(
                      color: MyColors.bg100, // Set the background color here
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                        controller: _chatListController,
                        itemCount: _messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          final ChatMessage message = _messages[index];
                          return ChatMessageWidgetMarkdown(
                            message: message,
                            chatService: this,
                          );
                        },
                      ),
                    ),
                  ),

                  BottomAppBar(
                    child: Container(
                      // height: 60,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: RawKeyboardListener(
                              focusNode: _focusNode,
                              onKey: (event) {
                                final isShiftPressed = event.isShiftPressed;
                                final isEnterKeyPressed = event.logicalKey ==
                                    LogicalKeyboardKey.enter;
                                print("isShiftPressed $isEnterKeyPressed, isEnterKeyPressed $isEnterKeyPressed event:$event");

                                if (isEnterKeyPressed && isShiftPressed) {
                                  _controller.value =
                                      _controller.value.copyWith(
                                    text: _controller.value.text + '\n',
                                    selection: TextSelection.collapsed(
                                        offset:
                                            _controller.value.selection.end +
                                                1),
                                  );
                                  print("new line");
                                } else if (isEnterKeyPressed) {
                                  if (_controller.text.trim().isNotEmpty) {
                                    _sendMessage(_controller.text);
                                  }
                                }
                              },
                              child: TextField(
                                controller: _controller,
                                decoration: InputDecoration(
                                  hintText: AppLocalizations.of(context)!.type_a_message,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                ),
                                keyboardType: TextInputType.multiline,
                                maxLines: Utils.isBigScreen(context) ? 20 : 10,
                                minLines: 1,
                                textInputAction: Utils.isMobile(context)? TextInputAction.send: null,
                                onSubmitted: (value) {
                                  if (Utils.isMobile(context)) {
                                    if (value.trim().isNotEmpty) {
                                      _sendMessage(value);
                                    }
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.send,
                                color: _isLoading ? Colors.grey : MyColors.primary100),
                            onPressed: () => _isLoading
                                ? null
                                : _sendMessage(_controller.text),
                          ),
                          if (_isSpeechToTextAvailable)
                            IconButton(
                              icon: Icon(
                                _isListening ? Icons.mic_off : Icons.mic, color: MyColors.primary100
                              ),
                              onPressed: _toggleListening,
                            ),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void showMessageActions(BuildContext context, ChatMessage message) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.content_copy, color: MyColors.primary100),
                title: Text(loc.copy),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                  showToast(loc.copied_to_clipboard);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: MyColors.primary100),
                title: Text(loc.share),
                onTap: () {
                  Share.share(message.content);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.translate, color: MyColors.primary100),
                title: Text(loc.translation),
                onTap: () {
                  String prompt = Constants.translationPrompt
                      .replaceAll("LOCALE_ID", _currentLanguageCode);
                  LogUtils.debug(prompt);

                  translate(message.content, prompt).then((translatedText) {
                    setState(() {
                      _messages.add(ChatMessage(
                          role: ChatMessage.ROLE_ASSISTANT,
                          content: translatedText));
                    });
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.book, color: MyColors.primary100),
                title: Text(loc.rephrase),
                onTap: () {
                  translate(message.content, Constants.rephrasePrompt)
                      .then((translatedText) {
                    setState(() {
                      _messages.add(ChatMessage(
                          role: ChatMessage.ROLE_ASSISTANT,
                          content: translatedText));
                    });
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove, color: MyColors.primary100),
                title: Text(loc.delete),
                onTap: () {
                  delete(message);
                  showToast(loc.message_deleted);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _listViewScrollToBottom() {
    if (!_autoScrollEnabled) {
      return;
    }

    Future.delayed(const Duration(milliseconds: 50), () {
      _chatListController.animateTo(
        _chatListController.position.maxScrollExtent,
        duration: Duration(milliseconds: Constants.scrollDuration),
        curve: Curves.easeOutSine,
      );
    });
  }

}
class ChatMessageWidgetMarkdown extends StatelessWidget {
  final ChatMessage message;
  final IChatService chatService;

  const ChatMessageWidgetMarkdown({
    Key? key,
    required this.message,
    required this.chatService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final markdownStyleSheet = MarkdownStyleSheet.fromTheme(themeData).copyWith(
      p: themeData.textTheme.bodyMedium!.copyWith(fontSize: 16),
    );

    Widget messageIcon;
    if (this.message.isUser) {
      messageIcon = Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Icon(Icons.person, color: MyColors.primary100),
      );
    } else {
      messageIcon = const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: Icon(Icons.cloud, color: MyColors.primary100),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          messageIcon,
          Expanded(
            child: Container(
              padding:
              const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              decoration: BoxDecoration(
                color: message.isUser ? MyColors.bg100 : MyColors.bg200,
                borderRadius: BorderRadius.circular(4.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: ListTile(
                title: MarkdownBody(
                  key: const Key("defaultmarkdownformatter"),
                  data: message.content,
                  selectable: true,
                  onTapText: () =>
                      chatService.showMessageActions(context, message),
                  styleSheet: markdownStyleSheet,
                  styleSheetTheme: MarkdownStyleSheetBaseTheme.platform,
                  extensionSet: md.ExtensionSet(
                    md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                    [
                      md.EmojiSyntax(),
                      ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes
                    ],
                  ),
                  builders: {
                    'code': CodeElementBuilder(context),
                  },
                ),
                onTap: () => chatService.showMessageActions(context, message),
                // onLongPress: () => chatService.showMessageActions(context, message),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


abstract class IChatService {
  Future<String> translate(String content, String translationPrompt);

  void showMessageActions(BuildContext context, ChatMessage message);
}
