import 'dart:async';
import 'dart:convert';
import 'package:chitchat/utils/log_utils.dart';
import 'package:chitchat/models/constants.dart';
import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:chitchat/models/settings.dart';
import 'dart:io';

class ChatService {
  late String? apiKey;
  final StreamController<ChatMessage> messageController;
  final HttpClient client = HttpClient();

  ChatService(this.messageController);

  Future<String> getTranslation(
    String translationPrompt,
    Settings settings,
  ) async {
    apiKey = settings.openaiApiKey;
    final response = await getCompletionRaw(
      "",
      translationPrompt,
      settings.temperatureValue,
      [],
      settings.proxyUrl,
      settings.baseUrl,
      settings.selectedModel,
      settings.streamModeEnable,
    );
    // final completion = response['choices'][0]['message']['content'];
    LogUtils.info(response);

    return response;
  }

  Future<String> getCompletion(String content, List<ChatMessage>? latestChat,
      Settings? settings, PromptStorage? promptStorage) async {
    apiKey = settings?.openaiApiKey;
    final response = await getCompletionRaw(
      content,
      promptStorage?.getSelectedPrompt().content ?? settings!.promptString,
      settings!.temperatureValue,
      latestChat,
      settings.proxyUrl,
      settings.baseUrl,
      settings.selectedModel,
      settings.streamModeEnable,
    );
    LogUtils.info(response);

    return response;
  }

  Future<String> getCompletionRaw(
    String content,
    String prompt,
    double temperatureValue,
    List<ChatMessage>? latestChat,
    String proxy,
    String baseUrl,
      String aiModel,
      bool useStream,
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

    //add the prompt set as system role
    if (prompt.isNotEmpty) {
      chatMessages.insert(0, {"role": "system", "content": prompt});
    }
    // Add the user's message to the list of chat messages
    if (content.isNotEmpty) {
      chatMessages.add({"role": "user", "content": content});
    }

    if (baseUrl.contains("localhost")) {
      // useStream = false;
    }

    final body = jsonEncode({
      "model": aiModel,
      // "model": "gpt-4",
      "temperature": temperatureValue,
      "messages": chatMessages,
      "stream": useStream
    });
    LogUtils.info(body);

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

    client.connectionTimeout = const Duration(seconds:60);
    final request = await client.postUrl(Uri.parse('$url/v1/chat/completions'));
    request.headers.contentType = ContentType.json;
    request.headers.set('Authorization', 'Bearer $apiKey');
    request.write(body);
    final response = await request.close();

    if (response.statusCode == HttpStatus.ok) {
      if (useStream) {
        return await handleStream(response);
      } else {
        final String responseString =
            await response.transform(utf8.decoder).join();
        final completion =
            jsonDecode(responseString)['choices'][0]['message']['content'];
        // return jsonDecode(responseString);
        return completion;
      }
    } else {
      throw Exception('Failed to load response');
    }
  }

  Future<String> handleStream(HttpClientResponse response) async {
    LogUtils.info("handleStream");
    String lastTruncatedMessage = "";
    ChatMessage chatMessage = ChatMessage(role: "assistant", content: "");
    response.transform(utf8.decoder).listen((event) {
      //{"id":"chatcmpl-6ttclp0wSdVFsT9Usl0yvuwNkvLzJ","object":"chat.completion.chunk","created":1678779879,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" today"},"index":0,"finish_reason":null}]}
      // LogUtils.info("${event}");
      event = lastTruncatedMessage + event;
      List<String> itemList = event.split("]}");
      lastTruncatedMessage = itemList.last;
      itemList.sublist(0, itemList.length - 1).forEach((jsonItem) {
        jsonItem = jsonItem.replaceAll("data:", "");
        String formatedJson = "$jsonItem]}";
        final decodeEvent = jsonDecode(formatedJson);

        final content = decodeEvent["choices"][0]["delta"]["content"];
        final role = decodeEvent["choices"][0]["delta"]["role"];
        final finishReason = decodeEvent["choices"][0]["finish_reason"];
        // LogUtils.info("content: ${content}, role: ${role}");
        // data: {"id":"chatcmpl-6u0BWt3AaTJefyeglqZ7aYihqbZbL","object":"chat.completion.chunk","created":1678805098,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{},"index":0,"finish_reason":"stop"}]}
        if (ChatMessage.STOP == finishReason) {
          // reach the stop item
          chatMessage = ChatMessage(
              role: ChatMessage.ROLE_ASSISTANT, content: ChatMessage.STOP);
          messageController.add(chatMessage);
          return;
        }
        if (ChatMessage.ROLE_ASSISTANT == role) {
          // it's the first data.
          // LogUtils.info("role is assistant");
        } else {
          if (null != content) {
            // The chunk message will be here
            // chatMessage.content = content;
            chatMessage =
                ChatMessage(role: ChatMessage.ROLE_ASSISTANT, content: content);
            messageController.add(chatMessage);
          }
        }
      });
    });

    LogUtils.info("handleStream, END");
    return "";
  }
}
