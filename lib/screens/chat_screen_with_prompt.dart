import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:chitchat/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/screens/chat_screen.dart';
import 'package:chitchat/screens/prompt_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreenWithPrompt extends StatefulWidget {

  @override
  _ChatScreenWithPromptState createState() => _ChatScreenWithPromptState();
}

class _ChatScreenWithPromptState extends State<ChatScreenWithPrompt> {
  late AppLocalizations loc;
  late Settings? settings;
  late ChatHistory? chatHistory = null;
  late PromptStorage? promptStorage;
  final GlobalKey<ChatScreenState> chatScreenKey = GlobalKey<ChatScreenState>();

  @override
  void initState() {
    super.initState();

    settings = null;
    chatHistory = null;
    promptStorage = null;

    Future.delayed(Duration.zero, () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        settings = Settings(prefs: prefs);
        chatHistory = ChatHistory(prefs: prefs);
        promptStorage = PromptStorage(prefs: prefs);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: settings == null || chatHistory == null || promptStorage == null
          ? Center(child: CircularProgressIndicator())
          : Row(
        children: <Widget>[
          Container(
            width: 250,
            child: PromptListScreen(
              promptStorage: promptStorage!,
              history: chatHistory!,
              onSelectedPrompt: (prompt) {
                chatScreenKey.currentState?.switchToPromptChannel(prompt);
              },
            ),
          ),
          Expanded(
            child: ChatScreen(
              settings: settings,
              key:chatScreenKey,
            ),
          ),
        ],
      ),
    );
  }
}
