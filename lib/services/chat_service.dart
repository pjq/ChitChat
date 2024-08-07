import 'dart:async';
import 'dart:convert';
import 'package:chitchat/utils/log_utils.dart';
import 'package:chitchat/models/chat_message.dart';
import 'package:chitchat/models/prompt.dart';
import 'package:chitchat/models/settings.dart';
import 'package:chitchat/services/btp_service.dart';
import 'dart:io';

import 'package:dart_openai/dart_openai.dart';

import '../models/constants.dart';

class ChatService {
  static const String tag = 'ChatService';
  late String? apiKey;
  final StreamController<ChatMessage> messageController;
  bool useBTP = false;
  bool useOpenaiSDK = true;
  ChatService(this.messageController);

  Future<String> getTranslation(
    String translationPrompt,
    Settings settings,
  ) async {
    apiKey = settings.openaiApiKey;
    useBTP = settings.useBTP;
    if (useBTP) {
      useOpenaiSDK = false;
    }

    LogUtils.info(tag,"useBTP:$useBTP useOpenaiSDK:$useOpenaiSDK");

    if (useOpenaiSDK) {
      final response = await getCompletionRawWithOpenAISDK(
        "",
        translationPrompt,
        settings.temperatureValue,
        [],
        settings.proxyUrl,
        settings.baseUrl,
        settings.selectedModel,
        settings.streamModeEnable,
      );

      LogUtils.info(tag,response);
      return response;
    } else {
      final response = await getCompletionRaw(
        "",
        translationPrompt,
        settings!.temperatureValue,
        [],
        settings.proxyUrl,
        settings.baseUrl,
        settings.selectedModel,
        settings.streamModeEnable,
      );

      LogUtils.info(tag,response);
      return response;
    }
  }

  Future<String> getCompletion(String content, List<ChatMessage>? latestChat,
      Settings? settings, PromptStorage? promptStorage) async {
    apiKey = settings?.openaiApiKey;

    useBTP = settings!.useBTP!;
    if (useBTP) {
      useOpenaiSDK = false;
    }

    LogUtils.info(tag,"useBTP:$useBTP useOpenaiSDK:$useOpenaiSDK");
    if (useOpenaiSDK) {
      final response = await getCompletionRawWithOpenAISDK(
        content,
        promptStorage?.getSelectedPrompt().content ?? settings!.promptString,
        settings!.temperatureValue,
        latestChat,
        settings.proxyUrl,
        settings.baseUrl,
        settings.selectedModel,
        settings.streamModeEnable,
      );
      LogUtils.info(tag,response);

      return response;
    } else {
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
      LogUtils.info(tag,response);

      return response;
    }
  }

  Future<String> getCompletionRawWithOpenAISDK(
    String content,
    String prompt,
    double temperatureValue,
    List<ChatMessage>? latestChat,
    String proxy,
    String baseUrl,
    String aiModel,
    bool useStream,
  ) async {
    LogUtils.info(tag,"getCompletionRawWithOpenAISDK");
    OpenAI.apiKey = apiKey!;
    if (baseUrl != null && baseUrl.isNotEmpty) {
      OpenAI.baseUrl = baseUrl;
    } else {
      OpenAI.baseUrl = Constants.baseUrl;
    }
    // OpenAI.showLogs = true;
    // OpenAI.showResponsesLogs = true;

    // Build the list of chat messages to include in the request body
    final chatMessages = latestChat?.map((message) {
          return OpenAIChatCompletionChoiceMessageModel(
              role: message.isUser
                  ? OpenAIChatMessageRole.user
                  : OpenAIChatMessageRole.assistant,
              content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(message.content)]);
        }).toList() ??
        [];

    //add the prompt set as system role
    if (prompt.isNotEmpty) {
      chatMessages.insert(
          0,
          OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system, content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt)]));
    }
    // Add the user's message to the list of chat messages
    if (content.isNotEmpty) {
      chatMessages.add(OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user, content:  [OpenAIChatCompletionChoiceMessageContentItemModel.text(content)]));
    }

    // print(chatMessages);

    LogUtils.info(tag,"useStream:$useStream");
    if (useStream) {
      try {
        LogUtils.info(tag,"createStream");
        Stream<OpenAIStreamChatCompletionModel> chatStream =
            OpenAI.instance.chat.createStream(
          model: aiModel,
          temperature: temperatureValue,
          messages: chatMessages,
        );
        LogUtils.info(tag,"createStream End");
        chatStream.listen((chatStreamEvent) {
          LogUtils.info(tag,"listen:" + chatStreamEvent.toString()); // ...
          final finishReason = chatStreamEvent.choices.last.finishReason;
          final role = chatStreamEvent.choices.last.delta.role;
          final returnContent = chatStreamEvent.choices.last.delta.content;
          ChatMessage chatMessage;
          if (ChatMessage.STOP == finishReason) {
            // reach the stop item
            chatMessage = ChatMessage(
                role: ChatMessage.ROLE_ASSISTANT, content: ChatMessage.STOP);
            messageController.add(chatMessage);
            return;
          }
          if (ChatMessage.ROLE_ASSISTANT == role) {
            // it's the first data.
            // LogUtils.info(tag,"role is assistant");
          } else {
            if (null != content) {
              // The chunk message will be here
              // chatMessage.content = content;
              chatMessage = ChatMessage(
                  role: ChatMessage.ROLE_ASSISTANT, content: returnContent!.first!.text!);
              messageController.add(chatMessage);
            }
          }
        }, onError: (error) {
          // Handle the error here
          LogUtils.info(tag,'An error occurred: $error');
          var chatMessage = ChatMessage(
              role: ChatMessage.ERROR, content: 'An error occurred: $error');
          messageController.add(chatMessage);
        }, onDone: () {
          LogUtils.info(tag,'The stream is done');
          var chatMessage = ChatMessage(
              role: ChatMessage.ROLE_ASSISTANT, content: ChatMessage.STOP);
          messageController.add(chatMessage);
        });
      } catch (error) {
        LogUtils.info(tag,'An error occurred while creating the stream: $error');
        var chatMessage = ChatMessage(
            role: ChatMessage.ERROR, content: error.toString());
        messageController.add(chatMessage);
      }
    } else {
      try {
        OpenAIChatCompletionModel chatStream = await OpenAI.instance.chat.create(
          model: aiModel,
          temperature: temperatureValue,
          messages: chatMessages,
        );
        //
        var msg = chatStream.choices[0].message.content?.last?.text;
        if (null == msg) {
          return "";
        } else {
          return msg;
        }
      } catch (error) {
        return error.toString();
      }
    }
    return "";
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
    if (useOpenaiSDK) {
      return getCompletionRawWithOpenAISDK(content, prompt, temperatureValue,
          latestChat, proxy, baseUrl, aiModel, useStream);
    }

    LogUtils.info(tag,"getCompletionRaw");

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
    LogUtils.info(tag,body);

    LogUtils.info(tag,proxy);
    final HttpClient client = HttpClient();
    if (proxy.isNotEmpty) {
      client.findProxy = (url) {
        return HttpClient.findProxyFromEnvironment(url,
            environment: {"http_proxy": proxy, "https_proxy": proxy});
      };
    }

    if (useBTP) {
      Map<String, dynamic> data = {
        'deployment_id': aiModel.replaceAll(".", ""),
        'messages': chatMessages,
      };
      LogUtils.info(tag,data.toString());
      BTPService service = new BTPService();

      return service.getCompletionRawByBTP(data);
    } else {
      //probably this code is not used any more.
      String url = Constants.baseUrl;
      if (baseUrl.isNotEmpty) {
        url = baseUrl;
      }
      LogUtils.info(tag,url);

      client.connectionTimeout = const Duration(seconds: 60);
      final request =
          await client.postUrl(Uri.parse('$url/v1/chat/completions'));
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
  }

  Future<String> handleStream(HttpClientResponse response) async {
    LogUtils.info(tag,"handleStream");
    String lastTruncatedMessage = "";
    ChatMessage chatMessage = ChatMessage(role: "assistant", content: "");
    response.transform(utf8.decoder).listen((event) {
      //{"id":"chatcmpl-6ttclp0wSdVFsT9Usl0yvuwNkvLzJ","object":"chat.completion.chunk","created":1678779879,"model":"gpt-3.5-turbo-0301","choices":[{"delta":{"content":" today"},"index":0,"finish_reason":null}]}
      // LogUtils.info(tag,"${event}");
      //fix the azure openai proxy convert format error, it include: ,"usage":null
      //data: {"id":"chatcmpl-7M6BzWVFvzBP1l80lRbaysWNUfBvS","object":"chat.completion.chunk","created":1685501375,"model":"gpt-35-turbo","choices":[{"index":0,"finish_reason":null,"delta":{"content":" with"}}],"usage":null}
      event = event.replaceAll(",\"usage\":null", "");
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
        // LogUtils.info(tag,"content: ${content}, role: ${role}");
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
          // LogUtils.info(tag,"role is assistant");
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

    LogUtils.info(tag,"handleStream, END");
    return "";
  }
}
