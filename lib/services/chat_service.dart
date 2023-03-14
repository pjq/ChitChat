import 'dart:async';
import 'dart:convert';
import 'package:chitchat/LogUtils.dart';
import 'package:chitchat/constants.dart';
import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/settings.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class ChatService {
  final String apiKey;
  final StreamController<ChatMessage> messageController;

  ChatService(this.apiKey, this.messageController);

  Future<String> getTranslation(
    String content,
    String translationPrompt,
    Settings? _settings,
  ) async {
    final response = await getCompletionRaw(
      translationPrompt + content,
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

    bool useStream = false;

    final body = jsonEncode({
      "model": "gpt-3.5-turbo",
      "temperature": temperatureValue,
      "messages": chatMessages,
      "stream": useStream
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

    if (useStream) {
      handleStream(response);
    }

    if (response.statusCode == HttpStatus.ok) {
      final String responseString =
          await response.transform(utf8.decoder).join();
      return jsonDecode(responseString);
    } else {
      throw Exception('Failed to load response');
    }
  }

  void handleStream(HttpClientResponse response) {
    LogUtils.info("handleStream");
    String lastTruncatedMessage = "";
    response.transform(utf8.decoder).listen((event) {
      //{"id":"chatcmpl-6ttclp0wSdVFsT9Usl0yvuwNkvLzJ","object":"chat.completion.chunk","created":1678779879,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" today"},"index":0,"finish_reason":null}]}
      event = lastTruncatedMessage + event;
      event.split("\n\n").forEach((element) {
        if (element.contains("[DONE]")) {
          return;
        }

        final item = element.replaceAll("data:", "");
        List<String> itemList = item.split("]}");
        lastTruncatedMessage = itemList.last;
        itemList.sublist(0, itemList.length - 1).forEach((jsonItem) {
          String formatedJson = "${jsonItem}]}";
          final decodeEvent = jsonDecode(formatedJson);
          final content = decodeEvent["choices"][0]["delta"]["content"];
          if (null != content) {
            // The chunk message will be here
            LogUtils.info("${content}");
            messageController.sink.add(ChatMessage(role: "assistant", content: content));
          }
        });
      });
    });
  }
}
