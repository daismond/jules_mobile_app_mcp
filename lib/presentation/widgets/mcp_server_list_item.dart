import 'package:flutter/material.dart';
import '../../domains/settings/entity/mcp_server_config.dart';
import '../../domains/mcp/entity/mcp_models.dart';
import 'mcp_connection_status_indicator.dart';

class McpServerListItem extends StatelessWidget {
  final McpServerConfig server;
  final McpConnectionStatus status;
  final String? errorMessage;
  final Function(String, bool) onToggleActive;
  final Function(McpServerConfig) onEdit;
  final Function(McpServerConfig) onDelete;

  const McpServerListItem({
    super.key,
    required this.server,
    required this.status,
    this.errorMessage,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isEnabled = server.isActive;
    final bool hasError = errorMessage != null;

    String getSubtitle() {
      final details = server.connectionMode == McpConnectionMode.stdio
          ? server.command ?? 'N/A'
          : server.address ?? 'N/A';
      final envCount = server.customEnvironment.length;
      if (envCount > 0) {
        return '$details • $envCount env var(s)';
      }
      return details;
    }

    return Card(
      elevation: isEnabled ? 2.0 : 0.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: hasError
            ? BorderSide(color: theme.colorScheme.error, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: ListTile(
          leading: McpConnectionStatusIndicator(status: status),
          title: Text(
            server.name,
            style: TextStyle(
              fontWeight: isEnabled ? FontWeight.bold : FontWeight.normal,
              color: isEnabled ? theme.textTheme.bodyLarge?.color : Colors.grey,
            ),
          ),
          subtitle: Text(
            getSubtitle(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isEnabled,
                onChanged: (bool value) => onToggleActive(server.id, value),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Server',
                onPressed: () => onEdit(server),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: theme.colorScheme.error,
                ),
                tooltip: 'Delete Server',
                onPressed: () => onDelete(server),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
