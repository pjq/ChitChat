import 'dart:convert';

import 'package:chatgpt_flutter/LogUtils.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt_flutter/settings.dart';
import 'package:chatgpt_flutter/constants.dart';
import 'package:chatgpt_flutter/models/chat_message.dart';
import 'package:chatgpt_flutter/services/chat_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:about/about.dart';
import 'package:chatgpt_flutter/pubspec.dart';
import 'package:share_plus/share_plus.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key, Settings? settings}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  ChatService? _chatService;
  Settings? _settings;
  ChatHistory? _history;

  @override
  void initState() {
    super.initState();
    setState(() {
      SharedPreferences.getInstance().then((prefs) {
        _settings = Settings(prefs: prefs);
        _chatService = ChatService(apiKey: _settings!.openaiApiKey);
        _history = ChatHistory(prefs: prefs);
        _messages.addAll(_history!.messages);
      });
    });
  }

  void _sendMessage(String text) async {
    if (_settings!.openaiApiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('API key not set'),
          content: Text('Please set the OpenAI API key in the settings.'),
          actions: [
            TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/settings');
                }),
          ],
        ),
      );
      return;
    }

    if (text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final messageSend = ChatMessage(role: 'user', content: text);
    _messages.add(messageSend);
    _controller.clear();

    try {
      final response = await _chatService!.getCompletion(
          messageSend.content,
          _settings!.promptString,
          _settings!.temperatureValue,
          _get5ChatHistory());
      final completion = response['choices'][0]['message']['content'];
      LogUtils.error(completion);

      setState(() {
        _isLoading = false;
        final messageReceived =
            ChatMessage(role: 'assistant', content: completion);
        _messages.add(messageReceived);
        _history?.addMessage(messageSend);
        _history?.addMessage(messageReceived);
      });
    } catch (e) {
      LogUtils.error(e.toString());
      setState(() {
        _isLoading = false;
      });
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Failed to send message'),
      //   ),
      // );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Failed to send message'),
            TextButton(
              child: Text('Retry'),
              onPressed: () => _sendMessage(messageSend.content),
            ),
          ],
        ),
      ));
    }
  }

  List<ChatMessage>? _get5ChatHistory() {
    final recentHistory = _history?.latestMessages;

    return _settings!.continueConversationEnable ? recentHistory : [];
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      bottom: 10,
      right: 10,
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  void _showAbout() {
    showAboutPage(
      context: context,
      values: {
        'version': Pubspec.version,
        'year': DateTime.now().year.toString(),
      },
      applicationLegalese:
          'Copyright © ${Pubspec.authorsName.join(', ')}, {{ year }}',
      applicationDescription: Text(Pubspec.description),
      children: const <Widget>[
        MarkdownPageListTile(
          icon: Icon(Icons.list),
          title: Text('Changelog'),
          filename: 'assets/CHANGELOG.md',
        ),
        LicensesPageListTile(
          icon: Icon(Icons.favorite),
        ),
      ],
      applicationIcon: const SizedBox(
        width: 100,
        height: 100,
        child: Image(
          image: AssetImage(
              'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png'),
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: message.role == 'user' ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: message.role == 'user' ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Chat'),
          actions: [
            IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                }),
            IconButton(
                icon: Icon(Icons.info),
                onPressed: () {
                  _showAbout();
                }),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ChatMessage message = _messages[index];
                    return ChatMessageWidgetSimple(message: message);
                  },
                ),
              ),
              BottomAppBar(
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 5,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: _sendMessage,
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () => _sendMessage(_controller.text),
                      ),
                      if (_isLoading)
                        SizedBox(
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
          ),
        ),
      ),
    );
  }
}

class ChatMessageWidget2 extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget2({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Markdown(
        data: message.content,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
      ),
      tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
    );
  }
}

class ChatMessageWidget3 extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget3({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: message.role == 'user' ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Markdown(
        data: message.content,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class ChatMessageWidget4 extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget4({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Expanded(
        child: Markdown(
          data: message.content,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      ),
      tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
    );
  }
}

void _showMessageActions(BuildContext context, ChatMessage message) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.content_copy),
              title: Text('Copy'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied to clipboard'),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share),
              title: Text('Share'),
              onTap: () {
                Share.share(message.content);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.translate),
              title: Text('Translation'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Not implemented yet'),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

class ChatMessageWidgetSimple extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidgetSimple({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        message.content.replaceAll("\n\n", "\n"),
        textAlign: message.isUser ? TextAlign.right : TextAlign.left,
      ),
      onTap: () => _showMessageActions(context, message),
      tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
    );
  }
}

class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(
        width: double.infinity,
        // Sets the width to be as large as the parent allows
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        height: message.isUser ? 55 : 100,
        child: message.isUser
            ? ListTile(
                title: Text(
                  message.content.replaceAll("\n\n", "\n"),
                  textAlign: message.isUser ? TextAlign.right : TextAlign.left,
                ),
                tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
              )
            : Markdown(
                data: message.content,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
              ),

      ),
    );
  }
}
