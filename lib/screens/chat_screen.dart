import 'dart:convert';

import 'package:chatgpt_flutter/LogUtils.dart';
import 'package:flutter/material.dart';
import 'package:chatgpt_flutter/settings.dart';
import 'package:chatgpt_flutter/models/chat_message.dart';
import 'package:chatgpt_flutter/services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.getInstance().then((prefs) {
      _settings = Settings(prefs: prefs);
      _chatService = ChatService(apiKey: _settings!.openaiApiKey);
      _history = ChatHistory(prefs: prefs);
      _messages.addAll(_history!.messages);
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
      final response = await _chatService!
          .getCompletion(messageSend.content, _settings!.promptString, _settings!.temperatureValue, _get5ChatHistory());
      final completion = response['choices'][0]['message']['content'];
      LogUtils.error(completion);

      setState(() {
        _isLoading = false;
        final messageReceived = ChatMessage(role: 'assistant', content: completion);
        _messages.add(messageReceived);
        _history?.addMessage(messageSend);
        _history?.addMessage(messageReceived);
      });
    } catch (e) {
      LogUtils.error(e.toString());
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message'),
        ),
      );
    }
  }

  List<ChatMessage>? _get5ChatHistory() {
    final recentHistory = _history?.latestMessages;

    return _settings!.continueConversationEnable ? recentHistory: [];
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
              onPressed: (){
                Navigator.pushNamed(context, '/settings');
              }
            ),
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
                    return ListTile(
                      title: Text(
                        message.content.replaceAll("\n\n", "\n"),
                        textAlign: message.isUser ? TextAlign.right : TextAlign.left,
                      ),
                      tileColor: message.isUser ? Colors.blue[100] : Colors.grey[200],
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
                        icon: Icon(Icons.send),
                        onPressed: () => _sendMessage(_controller.text),
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
