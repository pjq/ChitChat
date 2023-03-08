import 'dart:convert';
import 'package:chatgpt_flutter/LogUtils.dart';
import 'package:chatgpt_flutter/models/chat_message.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final String apiKey;

  ChatService({required this.apiKey});

  Future<Map<String, dynamic>> getCompletion(
      String content,
      String prompt,
      double temperatureValue,
      List<ChatMessage>? latestChat,
      ) async {
    LogUtils.info("getCompletion");

    // Build the list of chat messages to include in the request body
    final chatMessages = latestChat?.map((message) {
      return {"role": message.isUser ? "user" : "assistant", "content": message.content};
    }).toList() ?? [];

    // Add the user's message to the list of chat messages
    chatMessages.add({"role": "user", "content": content});

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(
        {
          "model": "gpt-3.5-turbo",
          "temperatureValue": temperatureValue,
          "messages": chatMessages,
        },
      ),
    );

    LogUtils.info(response.body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load response');
    }
  }

}
