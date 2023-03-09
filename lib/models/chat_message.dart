import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  String role;
  String content;

  ChatMessage({required this.role, required this.content});

  ChatMessage.fromJson(Map<String, dynamic> json)
      : role = json['role'],
        content = json['content'];

  bool get isUser => role == "user";

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

  List<ChatMessage> get latestMessages =>
      _messages.sublist(_messages.length - 3).toList();

  void addMessage(ChatMessage message) {
    _messages.add(message);
    _saveHistory();
  }

  static const String cacheHistoryKey = "chat_history3";

  static List<ChatMessage> _loadHistory(SharedPreferences prefs) {
    final String? json = prefs.getString(cacheHistoryKey);
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
    _prefs.setString(cacheHistoryKey, json);
  }
}
