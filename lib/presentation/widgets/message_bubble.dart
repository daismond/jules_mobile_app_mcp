import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:collection/collection.dart';

import '../../domains/chat/entity/chat_message.dart';
import '../../domains/settings/entity/mcp_server_config.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final List<McpServerConfig> serverConfigs;

  const MessageBubble({
    super.key,
    required this.message,
    required this.serverConfigs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    // --- Markdown Style ---
    final markdownStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
      code: theme.textTheme.bodyMedium!.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
        fontSize: 14,
      ),
      codeblockDecoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: theme.dividerColor),
      ),
      p: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
      blockquoteDecoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        border: Border(left: BorderSide(color: theme.dividerColor, width: 4)),
        borderRadius: BorderRadius.circular(4),
      ),
      blockquotePadding: const EdgeInsets.all(12),
    );

    // --- Bubble Decoration ---
    final bubbleDecoration = BoxDecoration(
      color: isUser
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.secondaryContainer,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(20),
        topRight: const Radius.circular(20),
        bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
        bottomRight: isUser ? Radius.zero : const Radius.circular(20),
      ),
    );

    // --- Message Content ---
    Widget messageContent;
    if (isUser) {
      messageContent = SelectableText(message.text, style: const TextStyle(fontSize: 15));
    } else {
      try {
        messageContent = MarkdownBody(
          data: message.text.isEmpty ? "..." : message.text,
          selectable: true,
          styleSheet: markdownStyle,
        );
      } catch (e) {
        debugPrint("Markdown rendering error: $e");
        messageContent = SelectableText(
          "Error rendering message content.\n\n${message.text}",
        );
      }
    }

    // --- Tool Info Chip ---
    Widget? toolInfoChip;
    if (!isUser && message.toolName != null) {
      String serverDisplayName = message.sourceServerName ??
          serverConfigs
              .firstWhereOrNull((s) => s.id == message.sourceServerId)
              ?.name ??
          (message.sourceServerId != null
              ? 'Server ${message.sourceServerId!.substring(0, 6)}...'
              : 'Unknown Server');

      toolInfoChip = Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.tertiaryContainer,
            width: 1,
          ),
        ),
        child: Text(
          "Tool Called: ${message.toolName} on $serverDisplayName",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onTertiaryContainer,
          ),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: bubbleDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              messageContent,
              if (toolInfoChip != null) toolInfoChip,
            ],
          ),
        ),
      ),
    );
  }
}
