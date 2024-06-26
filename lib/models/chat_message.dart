import 'dart:convert';

import 'package:chitchat/models/constants.dart';
import 'package:chitchat/utils/log_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatMessage {
  // ignore: constant_identifier_names
  static const String ROLE_USER = 'user';

  // ignore: constant_identifier_names
  static const String ROLE_ASSISTANT = 'assistant';
  static const String ERROR = 'error';

  // ignore: constant_identifier_names
  static const String DONE = '[DONE]';

  // ignore: non_constant_identifier_names
  static String STOP = "stop";

  String role;
  String content;

  ChatMessage({required this.role, required this.content});

  ChatMessage.fromJson(Map<String, dynamic> json)
      : role = json['role'],
        content = json['content'];

  bool get isUser => role == ROLE_USER;

  bool get isStop => content.contains(STOP);

  bool get isError => role.contains(ERROR);

  Map<String, dynamic> toJson() => {
        'role': role,
        'content': content,
      };
}

class ChatHistory {
  static const String tag = 'ChatHistory';
  SharedPreferences _prefs;
  List<ChatMessage> _messages = [];

  // ChatHistory({required SharedPreferences prefs})
  //     : _prefs = prefs,
  //       _messages = _loadHistory(prefs);

  ChatHistory({required SharedPreferences prefs}) : _prefs = prefs {
    _loadHistory(prefs).then((loadedMessages) {
      _messages.addAll(loadedMessages);
    });
  }

  List<ChatMessage> get messages => _messages;

  List<ChatMessage> getLatestMessages(String id) {
    _messages.clear();
    _messages.addAll(getMessagesForPromptChannel(id));
    if (_messages.length < Constants.MAX_MESSAGE_COUNT_FOR_CONVERSTAION) {
      return _messages;
    } else {
      return _messages.sublist(
          _messages.length - Constants.MAX_MESSAGE_COUNT_FOR_CONVERSTAION);
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

  static List<ChatMessage> _loadHistory2(SharedPreferences prefs) {
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

  static Future<List<ChatMessage>> _loadHistory(SharedPreferences prefs) async {
    final String? json = await prefs.getString(Constants.cacheHistoryKey);
    if (json == null) {
      return [];
    }

    final List<dynamic> data = jsonDecode(json);
    final List<ChatMessage> messages =
        data.map((item) => ChatMessage.fromJson(item)).toList(growable: false);

    final List<ChatMessage> newList = [];
    newList.addAll(messages);

    return newList;
  }

  void _saveHistory() {
    final List<Map<String, dynamic>> data =
        _messages.map((message) => message.toJson()).toList(growable: false);
    final String json = jsonEncode(data);
    _prefs.setString(Constants.cacheHistoryKey, json);
  }

  // void _clearHistory() {
  //   _messages.clear();
  //   _saveHistory();
  // }

  // Add a new method to get the chat history for a specific prompt channel.
  List<ChatMessage> getMessagesForPromptChannel(String promptChannel) {
    final String? json = _prefs.getString(promptChannel);
    if (json == null) {
      return [];
    }

    final List<dynamic> data = jsonDecode(json);
    final List<ChatMessage> messages =
        data.map((item) => ChatMessage.fromJson(item)).toList(growable: false);

    return messages;
  }

  // Modify the `addMessage` method to support a specific prompt channel.
  void addMessageWithPromptChannel(ChatMessage message, String promptChannel) {
    LogUtils.info(tag,"addMessageWithPromptChannel:$message");
    _messages.add(message);
    _saveHistoryWithPromptChannel(promptChannel);
  }

  // Modify the `deleteMessage` method to support a specific prompt channel.
  void deleteMessageWithPromptChannel(
      ChatMessage message, String promptChannel) {
    _messages.remove(message);
    _saveHistoryWithPromptChannel(promptChannel);
  }

  // Modify the `deleteMessage` method to support a specific prompt channel.
  void deleteMessageForPromptChannel(String promptChannel) {
    _messages.clear();
    _saveHistoryWithPromptChannel(promptChannel);
  }

  // Modify the `_saveHistory` method to support a specific prompt channel.
  void _saveHistoryWithPromptChannel(String promptChannel) {
    final List<Map<String, dynamic>> data =
        _messages.map((message) => message.toJson()).toList(growable: false);
    final String json = jsonEncode(data);
    _prefs.setString(promptChannel, json);
  }
}
