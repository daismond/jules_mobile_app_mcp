import 'package:flutter/material.dart';

class ChatInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool isLoading;
  final bool isApiKeySet;
  final VoidCallback onSend;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.isLoading,
    required this.isApiKeySet,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 8.0),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    focusNode: focusNode,
                    controller: controller,
                    enabled: enabled,
                    decoration: InputDecoration(
                      hintText: isApiKeySet
                          ? (isLoading
                              ? 'Waiting for response...'
                              : 'Enter your message...')
                          : 'Set API Key in Settings...',
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 14.0,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: enabled ? (_) => onSend() : null,
                    minLines: 1,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12.0),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FilledButton(
                    onPressed: enabled ? onSend : null,
                    style: FilledButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.zero,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Icon(Icons.send, size: 24),
                  ),
                ),
              ],
            ),
            if (!isApiKeySet)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Text(
                  'Please set your API Key in the Settings menu (⚙️) to start chatting.',
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
