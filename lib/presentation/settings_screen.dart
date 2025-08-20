import 'package:flutter/material.dart';
import 'package:flutter_chat_desktop/domains/ai/entity/ai_provider_type.dart';
import 'package:flutter_chat_desktop/domains/settings/entity/ai_config.dart';
import 'package:flutter_chat_desktop/providers/mcp_providers.dart';
import 'package:flutter_chat_desktop/providers/settings_providers.dart';
import 'package:flutter_chat_desktop/domains/mcp/entity/mcp_models.dart';
import 'package:flutter_chat_desktop/domains/settings/entity/mcp_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import reusable widgets
import 'widgets/api_key_section.dart';
import 'widgets/mcp_server_list_item.dart';
import 'widgets/server_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late AIConfig _localAIConfig;

  @override
  void initState() {
    super.initState();
    // Initialize local state from the provider
    _localAIConfig = ref.read(aiConfigProvider);
    _apiKeyController = TextEditingController(text: _localAIConfig.currentApiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _updateLocalApiKey() {
    final currentKey = _apiKeyController.text.trim();
    final currentProvider = _localAIConfig.selectedProvider;

    setState(() {
      final newApiKeys = Map<AIProviderType, String>.from(_localAIConfig.apiKeys);
      newApiKeys[currentProvider] = currentKey;
      _localAIConfig = _localAIConfig.copyWith(apiKeys: newApiKeys);
    });
  }

  void _handleProviderChange(AIProviderType? newProvider) {
    if (newProvider == null || newProvider == _localAIConfig.selectedProvider) {
      return;
    }

    // Save the current text before switching
    _updateLocalApiKey();

    setState(() {
      _localAIConfig = _localAIConfig.copyWith(selectedProvider: newProvider);
      // Update the text field with the new provider's key
      _apiKeyController.text = _localAIConfig.currentApiKey ?? '';
    });
  }

  void _saveAIConfig() {
    // Update the local state with the current text field value first
    _updateLocalApiKey();

    // Use the callback to wait for the state to be updated before saving
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(settingsServiceProvider)
          .saveAIConfig(_localAIConfig)
          .then((_) => _showSnackbar('Settings Saved!'))
          .catchError((e) => _showSnackbar('Error saving settings: $e'));
      FocusScope.of(context).unfocus();
    });
  }

  void _clearApiKey() {
    final currentProvider = _localAIConfig.selectedProvider;
    setState(() {
      final newApiKeys = Map<AIProviderType, String>.from(_localAIConfig.apiKeys);
      newApiKeys.remove(currentProvider);
      _localAIConfig = _localAIConfig.copyWith(apiKeys: newApiKeys);
      _apiKeyController.clear();
    });

    // Use the callback to wait for the state to be updated before saving
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveAIConfig();
      _showSnackbar('${_getProviderName(currentProvider)} API Key Cleared!');
    });
  }

  String _getProviderName(AIProviderType provider) {
    switch (provider) {
      case AIProviderType.gemini:
        return 'Gemini';
      case AIProviderType.openAI:
        return 'OpenAI';
    }
  }


  void _toggleServerActive(String serverId, bool isActive) {
    ref
        .read(settingsServiceProvider)
        .toggleMcpServerActive(serverId, isActive)
        .catchError(
          (e) => _showSnackbar('Error updating server active state: $e'),
        );
  }

  void _deleteServer(McpServerConfig server) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Server?'),
          content: Text(
            'Are you sure you want to delete the server "${server.name}"?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ref
                    .read(settingsServiceProvider)
                    .deleteMcpServer(server.id)
                    .then(
                      (_) => _showSnackbar('Server "${server.name}" deleted.'),
                    )
                    .catchError(
                      (e) => _showSnackbar('Error deleting server: $e'),
                    );
              },
            ),
          ],
        );
      },
    );
  }

  void _openServerDialog({McpServerConfig? serverToEdit}) {
    showServerDialog(
      context: context,
      serverToEdit: serverToEdit,
      onAddServer: (newServer) {
        ref
            .read(settingsServiceProvider)
            .addMcpServer(newServer)
            .then((_) => _showSnackbar('Server "${newServer.name}" added.'))
            .catchError((e) => _showSnackbar('Error saving server: $e'));
      },
      onUpdateServer: (updatedServer) {
        ref
            .read(settingsServiceProvider)
            .updateMcpServer(updatedServer)
            .then(
              (_) => _showSnackbar('Server "${updatedServer.name}" updated.'),
            )
            .catchError((e) => _showSnackbar('Error updating server: $e'));
      },
      onError: _showSnackbar,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch the global provider to rebuild if it changes from elsewhere
    ref.watch(aiConfigProvider);
    final serverList = ref.watch(mcpServerListProvider);
    final mcpState = ref.watch(mcpClientProvider);

    final serverStatuses = mcpState.serverStatuses;
    final serverErrors = mcpState.serverErrorMessages;
    final connectedCount = mcpState.connectedServerCount;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- API Key Section ---
          ApiKeySection(
            config: _localAIConfig,
            apiKeyController: _apiKeyController,
            onProviderChanged: _handleProviderChange,
            onSave: _saveAIConfig,
            onClear: _clearApiKey,
          ),
          const Divider(height: 24.0),

          // --- MCP Server Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'MCP Servers',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Add New MCP Server',
                onPressed: () => _openServerDialog(),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            '$connectedCount server(s) connected. Changes are applied automatically.',
            style: const TextStyle(fontSize: 12.0, color: Colors.grey),
          ),
          const SizedBox(height: 12.0),

          // Server List Display
          serverList.isEmpty
              ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    "No MCP servers configured. Click '+' to add.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: serverList.length,
                itemBuilder: (context, index) {
                  final server = serverList[index];
                  final status =
                      serverStatuses[server.id] ??
                      McpConnectionStatus.disconnected;
                  final error = serverErrors[server.id];

                  return McpServerListItem(
                    server: server,
                    status: status,
                    errorMessage: error,
                    onToggleActive: _toggleServerActive,
                    onEdit: (server) => _openServerDialog(serverToEdit: server),
                    onDelete: _deleteServer,
                  );
                },
              ),
          const SizedBox(height: 12.0),
        ],
      ),
    );
  }
}
