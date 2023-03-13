import 'dart:convert';

import 'package:chitchat/LogUtils.dart';
import 'package:flutter/material.dart';
import 'package:chitchat/settings.dart';
import 'package:chitchat/constants.dart';
import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/services/chat_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:about/about.dart';
import 'package:chitchat/pubspec.dart';
import 'package:share_plus/share_plus.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key, Settings? settings}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> implements IChatService {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  ChatService? _chatService;
  Settings? _settings;
  ChatHistory? _history;
  final _chatListController = ScrollController();

  @override
  void initState() {
    super.initState();
    LogUtils.info("init state");

    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        _settings = Settings(prefs: prefs);
        _chatService = ChatService(apiKey: _settings!.openaiApiKey);
        _history = ChatHistory(prefs: prefs);
        _messages.addAll(_history!.messages);
        LogUtils.info("history size: ${_messages.length}");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _listViewScrollToBottom();
        });
      });
    });
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
    );

    return completion;
  }

  @override
  Future<String> translate(String content, String translationPrompt) async {
    setState(() {
      _isLoading = true;
    });
    final completion = await _chatService!.getTranslation(
      content,
      translationPrompt,
      _settings,
    );

    setState(() {
      _isLoading = false;
    });

    return completion;
  }

  void _sendMessage(String text) async {
    if (_settings!.openaiApiKey.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('OpenAI API key not set'),
          content: Text('Kindly configure the OpenAI API key in the settings'),
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

    _listViewScrollToBottom();

    final messageSend = ChatMessage(role: 'user', content: text);
    _messages.add(messageSend);
    _controller.clear();

    try {
      final completion = await _callAPI(messageSend.content);

      setState(() {
        _isLoading = false;
        final messageReceived =
            ChatMessage(role: 'assistant', content: completion);
        _messages.add(messageReceived);
        _history?.addMessage(messageSend);
        _history?.addMessage(messageReceived);
      });

      _listViewScrollToBottom();
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
          title: Text('ChitChat'),
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
            IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _messages.clear();
                    _history?.messages.clear();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Conversation records erased'),
                      ),
                    );
                  });
                }),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
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
                        icon: Icon(Icons.send, color: _isLoading ? Colors.grey : null),
                        onPressed: () => _isLoading ? null : _sendMessage(_controller.text),
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
                  translate(message.content, Constants.translationPrompt)
                      .then((translatedText) {
                    setState(() {
                      _messages.add(ChatMessage(
                          role: "assistant", content: translatedText));
                    });
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.book),
                title: Text('Rephrase'),
                onTap: () {
                  translate(message.content, Constants.rephrasePrompt)
                      .then((translatedText) {
                    setState(() {
                      _messages.add(ChatMessage(
                          role: "assistant", content: translatedText));
                    });
                  });
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
    Future.delayed(const Duration(milliseconds: 500), () {
      _chatListController.animateTo(
        _chatListController.position.maxScrollExtent,
        duration: Duration(milliseconds: Constants.scrollDuration),
        curve: Curves.easeOutSine,
      );
    });
  }
}

class ChatMessageWidgetSimple extends StatelessWidget {
  final ChatMessage message;
  final IChatService chatService;

  const ChatMessageWidgetSimple(
      {required this.message, required this.chatService});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        message.content.replaceAll("\n\n", "\n"),
        textAlign: message.isUser ? TextAlign.right : TextAlign.left,
        // onSelectionChanged: (text, _) {
        //   _showMessageActions(
        //       context, ChatMessage(role: "user", content: text.toString()));
        // },
      ),
      onTap: () => chatService.showMessageActions(context, message),
      tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
    );
  }
}

class ChatMessageWidgetMarkdown extends StatelessWidget {
  final ChatMessage message;
  final IChatService chatService;

  const ChatMessageWidgetMarkdown(
      {required this.message, required this.chatService});

  @override
  Widget build(BuildContext context) {

    ThemeData themeData = Theme.of(context);
    MarkdownStyleSheet markdownStyleSheet = MarkdownStyleSheet.fromTheme(themeData);
    // markdownStyleSheet.textAlign = message.isUser ?  WrapAlignment.end : WrapAlignment.start;
    return ListTile(
      title: MarkdownBody(
        data:message.content,
      ),
      tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
      onTap: () => chatService.showMessageActions(context, message),
      // hoverColor: Colors.grey[100],
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
        height: message.isUser ? 55 : 200,
        child: message.isUser
            ? ListTile(
                title: Text(
                  message.content.replaceAll("\n\n", "\n"),
                  textAlign: message.isUser ? TextAlign.right : TextAlign.left,
                ),
                tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
              )
            : Markdown(
                selectable: true,
                data: message.content,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
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
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
    );
    // tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
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

abstract class IChatService {
  Future<String> translate(String content, String translationPrompt);

  void showMessageActions(BuildContext context, ChatMessage message);
}
