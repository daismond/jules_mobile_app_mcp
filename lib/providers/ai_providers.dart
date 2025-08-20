import 'package:flutter_chat_desktop/domains/ai/data/ai_repository_impl.dart';
import 'package:flutter_chat_desktop/domains/ai/data/client/ai_client.dart';
import 'package:flutter_chat_desktop/domains/ai/data/client/google_generative_ai_client.dart';
import 'package:flutter_chat_desktop/domains/ai/data/client/openai_client.dart';
import 'package:flutter_chat_desktop/domains/ai/entity/ai_provider_type.dart';
import 'package:flutter_chat_desktop/domains/ai/repository/ai_repository.dart';
import 'package:flutter_chat_desktop/providers/settings_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the AI Repository.
/// This provider is responsible for creating the correct AI client based on
/// the user's settings and providing it to the AI repository.
final aiRepositoryProvider = Provider<AiRepository?>((ref) {
  // Watch the AI configuration from the settings
  final aiConfig = ref.watch(aiConfigProvider);

  // Get the API key for the currently selected provider
  final apiKey = aiConfig.currentApiKey;

  // If there's no API key for the selected provider, return null
  if (apiKey == null || apiKey.isEmpty) {
    return null;
  }

  // Create the appropriate client based on the selected provider
  AiClient client;
  switch (aiConfig.selectedProvider) {
    case AIProviderType.gemini:
      client = GoogleGenerativeAiClient(apiKey);
      break;
    case AIProviderType.openAI:
      client = OpenAiClient(apiKey);
      break;
    // Default case to ensure we always have a client if a new provider is added
    default:
      // Or return null if you want to disable AI features for unsupported providers
      throw Exception('Unsupported AI provider: ${aiConfig.selectedProvider}');
  }

  // Return the repository implementation with the selected client
  return AiRepositoryImpl(client);
});
