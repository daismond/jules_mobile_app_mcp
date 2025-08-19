import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_desktop/domains/ai/entity/ai_entities.dart';
import 'package:flutter_chat_desktop/domains/chat/entity/chat_message.dart';

@immutable
class ChatState {
  final List<ChatMessage> displayMessages;
  final List<AiContent> chatHistory;
  final bool isLoading;
  final bool isApiKeySet;
  final Uint8List? pendingImageBytes;

  const ChatState({
    this.displayMessages = const [],
    this.chatHistory = const [],
    this.isLoading = false,
    this.isApiKeySet = false,
    this.pendingImageBytes,
  });

  ChatState copyWith({
    List<ChatMessage>? displayMessages,
    List<AiContent>? chatHistory,
    bool? isLoading,
    bool? isApiKeySet,
    // Use ValueGetter to allow explicitly setting null
    ValueGetter<Uint8List?>? pendingImageBytes,
  }) {
    return ChatState(
      displayMessages: displayMessages ?? this.displayMessages,
      chatHistory: chatHistory ?? this.chatHistory,
      isLoading: isLoading ?? this.isLoading,
      isApiKeySet: isApiKeySet ?? this.isApiKeySet,
      pendingImageBytes:
          pendingImageBytes != null ? pendingImageBytes() : this.pendingImageBytes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          runtimeType == other.runtimeType &&
          const ListEquality().equals(displayMessages, other.displayMessages) &&
          const ListEquality().equals(chatHistory, other.chatHistory) &&
          isLoading == other.isLoading &&
          isApiKeySet == other.isApiKeySet &&
          pendingImageBytes == other.pendingImageBytes;

  @override
  int get hashCode =>
      const ListEquality().hash(displayMessages) ^
      const ListEquality().hash(chatHistory) ^
      isLoading.hashCode ^
      isApiKeySet.hashCode ^
      pendingImageBytes.hashCode;
}
