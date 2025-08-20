import 'dart:async';

import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_desktop/domains/ai/entity/ai_entities.dart';

import 'ai_client.dart';

class OpenAiClient implements AiClient {
  final String _apiKey;
  bool _isInitialized = false;
  String? _initializationError;

  @override
  bool get isInitialized => _isInitialized;

  @override
  String? get initializationError => _initializationError;

  OpenAiClient(this._apiKey) {
    initialize();
  }

  @override
  bool initialize() {
    if (_apiKey.isEmpty) {
      _initializationError = 'OpenAI API key is missing.';
      _isInitialized = false;
      return false;
    }
    try {
      OpenAI.apiKey = _apiKey;
      _isInitialized = true;
      return true;
    } catch (e) {
      _initializationError = "Failed to initialize OpenAI client: ${e.toString()}";
      _isInitialized = false;
      return false;
    }
  }

  List<OpenAIChatCompletionChoiceMessageModel> _convertHistoryToOpenAIMessages(
    List<AiContent> history,
  ) {
    return history.map((content) {
      final role = content.role == 'user'
          ? OpenAIChatMessageRole.user
          : OpenAIChatMessageRole.assistant;

      final textContent =
          content.parts.whereType<AiTextPart>().map((p) => p.text).join();

      return OpenAIChatCompletionChoiceMessageModel(
        role: role,
        content: [
          OpenAIChatCompletionChoiceMessageContentItemModel.text(textContent),
        ],
      );
    }).toList();
  }

  @override
  Stream<AiStreamChunk> getResponseStream(List<AiContent> content) {
    if (!isInitialized) {
      return Stream.error(Exception("OpenAI client not initialized. $_initializationError"));
    }

    final openAiMessages = _convertHistoryToOpenAIMessages(content);

    try {
      final stream = OpenAI.instance.chat.createStream(
        model: "gpt-4-turbo",
        messages: openAiMessages,
      );

      return stream.map((streamChatCompletion) {
        final text = streamChatCompletion.choices.first.delta.content ?? '';
        final isFinish = streamChatCompletion.choices.first.finishReason != null;
        return AiStreamChunk(text: text, isFinish: isFinish);
      }).transform(StreamTransformer.fromHandlers(
        handleError: (error, stackTrace, sink) {
          debugPrint("Error in OpenAI stream: $error");
          sink.addError(Exception("Failed to get response from OpenAI: $error"));
        },
      ));
    } catch (e) {
      debugPrint("Error creating OpenAI stream: $e");
      return Stream.error(Exception("Failed to create stream with OpenAI: $e"));
    }
  }

  @override
  Future<AiResponse> getResponse(
    List<AiContent> content, {
    List<AiTool>? tools,
  }) async {
     if (!isInitialized) {
      throw Exception("OpenAI client not initialized. $_initializationError");
    }

    if (tools != null && tools.isNotEmpty) {
      throw UnimplementedError("Tool usage is not implemented for the OpenAI client yet.");
    }

    final openAiMessages = _convertHistoryToOpenAIMessages(content);

    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: "gpt-4-turbo",
        messages: openAiMessages,
      );

      final message = chatCompletion.choices.first.message;
      final textResponse = message.content?.map((p) => p.text).join() ?? '';

      final candidate = AiCandidate(
        content: AiContent.model(textResponse),
        finishReason: _mapFinishReason(chatCompletion.choices.first.finishReason),
      );

      return AiResponse(candidates: [candidate]);

    } catch (e) {
      debugPrint("Error getting OpenAI response: $e");
      throw Exception("Failed to get response from OpenAI: $e");
    }
  }

  FinishReason _mapFinishReason(String? reason) {
    switch (reason) {
      case 'stop':
        return FinishReason.stop;
      case 'length':
        return FinishReason.maxTokens;
      case 'tool_calls':
        return FinishReason.recitation; // Or a more appropriate mapping
      case 'content_filter':
        return FinishReason.safety;
      default:
        return FinishReason.other;
    }
  }
}
