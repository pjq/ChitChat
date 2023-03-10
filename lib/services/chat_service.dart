import 'dart:convert';
import 'package:chitchat/LogUtils.dart';
import 'package:chitchat/constants.dart';
import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ChatService {
  final String apiKey;

  ChatService({required this.apiKey});

  Future<String> getTranslation(
    String content,
    Settings? _settings,
  ) async {
    final response = await getCompletionRaw(
      Constants.translationPrompt + content,
      _settings!.promptString,
      _settings!.temperatureValue,
      [],
      _settings!.proxyUrl,
      _settings!.baseUrl,
    );
    final completion = response['choices'][0]['message']['content'];
    LogUtils.info(completion);

    return completion;
  }

  Future<String> getCompletion(
    String content,
    List<ChatMessage>? latestChat,
    Settings? _settings,
  ) async {
    final response = await getCompletionRaw(
      content,
      _settings!.promptString,
      _settings!.temperatureValue,
      latestChat,
      _settings!.proxyUrl,
      _settings!.baseUrl,
    );
    final completion = response['choices'][0]['message']['content'];
    LogUtils.info(completion);

    return completion;
  }

  Future<Map<String, dynamic>> getCompletionRaw(
    String content,
    String prompt,
    double temperatureValue,
    List<ChatMessage>? latestChat,
    String proxy,
    String baseUrl,
  ) async {
    LogUtils.info("getCompletion");

    // Build the list of chat messages to include in the request body
    final chatMessages = latestChat?.map((message) {
          return {
            "role": message.isUser ? "user" : "assistant",
            "content": message.content
          };
        }).toList() ??
        [];

    // Add the user's message to the list of chat messages
    chatMessages.add({"role": "user", "content": content});

    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "temperature": temperatureValue,
      "messages": chatMessages,
    });
    LogUtils.info(body);

    HttpClient client = HttpClient();
    LogUtils.info(proxy);
    if (proxy.isNotEmpty) {
      client.findProxy = (url) {
        return HttpClient.findProxyFromEnvironment(url,
            environment: {"http_proxy": proxy, "https_proxy": proxy});
      };
    }

    String url = "https://api.openai.com";
    if (baseUrl.isNotEmpty) {
      url = baseUrl;
    }
    LogUtils.info(url);

    final request = await client.postUrl(Uri.parse('$url/v1/chat/completions'));
    request.headers.contentType = ContentType.json;
    request.headers.set('Authorization', 'Bearer $apiKey');
    request.write(body);
    final response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      final String responseString =
          await response.transform(utf8.decoder).join();
      return jsonDecode(responseString);
    } else {
      throw Exception('Failed to load response');
    }
  }
}
