import 'package:flutter/material.dart';
import 'package:flutter_chat_desktop/domains/ai/entity/ai_provider_type.dart';
import 'package:flutter_chat_desktop/domains/settings/entity/ai_config.dart';

class ApiKeySection extends StatelessWidget {
  final AIConfig config;
  final TextEditingController apiKeyController;
  final ValueChanged<AIProviderType?> onProviderChanged;
  final Function() onSave;
  final Function() onClear;

  const ApiKeySection({
    super.key,
    required this.config,
    required this.apiKeyController,
    required this.onProviderChanged,
    required this.onSave,
    required this.onClear,
  });

  String _getProviderName(AIProviderType provider) {
    switch (provider) {
      case AIProviderType.gemini:
        return 'Gemini';
      case AIProviderType.openAI:
        return 'OpenAI';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerName = _getProviderName(config.selectedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Provider',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8.0),
        // Dropdown for selecting the AI provider
        DropdownButtonFormField<AIProviderType>(
          value: config.selectedProvider,
          items: AIProviderType.values.map((provider) {
            return DropdownMenuItem<AIProviderType>(
              value: provider,
              child: Text(_getProviderName(provider)),
            );
          }).toList(),
          onChanged: onProviderChanged,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          ),
        ),
        const SizedBox(height: 16.0),
        Text(
          '$providerName API Key',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: apiKeyController,
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'Enter your $providerName API Key',
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.vpn_key),
          ),
          onSubmitted: (_) => onSave(),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Key'),
              onPressed: onSave,
            ),
            if (config.currentApiKey != null && config.currentApiKey!.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Clear Key'),
                onPressed: onClear,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4.0),
        const Text(
          'Stored securely on your device.',
          style: TextStyle(
            fontSize: 12.0,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
