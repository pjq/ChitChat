import 'dart:convert';
import 'package:chitchat/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  static const String ROLE_USER = 'user';
  static const String ROLE_ASSISTANT = 'assistant';
  static const String DONE = '[DONE]';
  static String STOP = "stop";

  String role;
  String content;

  ChatMessage({required this.role, required this.content});

  ChatMessage.fromJson(Map<String, dynamic> json)
      : role = json['role'],
        content = json['content'];

  bool get isUser => role == ROLE_USER;

  bool get isStop=> content.contains(STOP);

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class ChatHistory {
  SharedPreferences _prefs;
  List<ChatMessage> _messages = [];

  ChatHistory({required SharedPreferences prefs})
      : _prefs = prefs,
        _messages = _loadHistory(prefs);

  List<ChatMessage> get messages => _messages;

  List<ChatMessage> get latestMessages {
    if (_messages.length < 4) {
      return _messages;
    } else {
      return _messages.sublist(_messages.length - 4);
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    _saveHistory();
  }

  void deleteMessage(ChatMessage message) {
    _messages.remove(message);
    _saveHistory();
  }

  static List<ChatMessage> _loadHistory(SharedPreferences prefs) {
    final String? json = prefs.getString(Constants.cacheHistoryKey);
    if (json == null) {
      return [];
    }

    final List<dynamic> data = jsonDecode(json);
    final List<ChatMessage> messages =
        data.map((item) => ChatMessage.fromJson(item)).toList(growable: false);

    final List<ChatMessage> newList = [];
    newList.addAll(messages);

    return newList;
    // return messages;
  }

  void _saveHistory() {
    final List<Map<String, dynamic>> data =
        _messages.map((message) => message.toJson()).toList(growable: false);
    final String json = jsonEncode(data);
    _prefs.setString(Constants.cacheHistoryKey, json);
  }

  void _clearHistory() {
    _messages.clear();
    _saveHistory();
  }
}
