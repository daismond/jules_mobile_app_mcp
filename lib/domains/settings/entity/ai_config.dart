import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_desktop/domains/ai/entity/ai_provider_type.dart';

@immutable
class AIConfig {
  final AIProviderType selectedProvider;
  final Map<AIProviderType, String> apiKeys;

  const AIConfig({
    this.selectedProvider = AIProviderType.gemini,
    this.apiKeys = const {},
  });

  String? get currentApiKey => apiKeys[selectedProvider];

  AIConfig copyWith({
    AIProviderType? selectedProvider,
    Map<AIProviderType, String>? apiKeys,
  }) {
    return AIConfig(
      selectedProvider: selectedProvider ?? this.selectedProvider,
      apiKeys: apiKeys ?? this.apiKeys,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedProvider': selectedProvider.name,
      'apiKeys': apiKeys.map((key, value) => MapEntry(key.name, value)),
    };
  }

  factory AIConfig.fromMap(Map<String, dynamic> map) {
    return AIConfig(
      selectedProvider: AIProviderType.values.firstWhere(
        (e) => e.name == map['selectedProvider'],
        orElse: () => AIProviderType.gemini,
      ),
      apiKeys: Map<AIProviderType, String>.from(
        (map['apiKeys'] as Map<String, dynamic>).map(
          (key, value) => MapEntry(
            AIProviderType.values.firstWhere((e) => e.name == key),
            value as String,
          ),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory AIConfig.fromJson(String source) => AIConfig.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AIConfig &&
        other.selectedProvider == selectedProvider &&
        mapEquals(other.apiKeys, apiKeys);
  }

  @override
  int get hashCode => selectedProvider.hashCode ^ apiKeys.hashCode;
}
