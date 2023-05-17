import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:chitchat/models/settings.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/screens/chat_screen.dart';
import 'package:chitchat/screens/prompt_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatScreenWithPrompt extends StatefulWidget {
  final Settings settings;

  const ChatScreenWithPrompt(
      {required this.settings});

  @override
  _ChatScreenWithPromptState createState() => _ChatScreenWithPromptState();
}

class _ChatScreenWithPromptState extends State<ChatScreenWithPrompt> {
  late AppLocalizations loc;
  late Settings settings;
  late ChatHistory chatHistory;
  late PromptStorage promptStorage;

  @override
  void initState() {
    super.initState();
    // Settings? settings;
    // PromptStorage? promptStorage = null;
    // ChatHistory? chatHistory;

    SharedPreferences.getInstance().then((prefs) {
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
      appBar: AppBar(
        title: Text('Chat Screen With Prompt'),
      ),
      body: Row(
        children: <Widget>[
          Container(
            width: 250,
            child: PromptListScreen(
              promptStorage: promptStorage!,
              history: chatHistory!,
              onSelectedPrompt: (prompt) {
                // TODO: Handle selected prompt
              },
            ),
          ),
          Expanded(
            child: ChatScreen(
              settings: settings, // TODO: Add appropriate settings
            ),
          ),
        ],
      ),
    );
  }
}
