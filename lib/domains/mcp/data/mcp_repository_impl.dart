import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_chat_desktop/domains/settings/entity/mcp_server_config.dart';
import 'package:mcp_dart/mcp_dart.dart';

import '../entity/mcp_models.dart';
import '../repository/mcp_repository.dart';
import 'mcp_client.dart';
import 'transports/http_mcp_transport.dart';
import 'transports/stdio_mcp_transport.dart';
import 'client_transport.dart';

/// Implémentation de McpRepository.
/// Gère les clients MCP, leur cycle de vie,
/// et traduit les résultats mcp_dart en entités du domaine.
class McpRepositoryImpl implements McpRepository {
  // --- États internes ---
  final Map<String, McpClient> _activeClients = {};
  final Map<String, McpConnectionStatus> _serverStatuses = {};
  final Map<String, List<McpToolDefinition>> _discoveredTools = {};
  final Map<String, String> _serverErrorMessages = {};

  // Stream de diffusion d’état
  final StreamController<McpClientState> _stateController =
      StreamController.broadcast();

  McpRepositoryImpl() {
    _emitState();
  }

  // --- Gestion des états ---
  void _emitState() {
    if (!_stateController.isClosed) {
      final state = McpClientState(
        serverStatuses: Map.unmodifiable(_serverStatuses),
        discoveredTools: Map.unmodifiable(_discoveredTools),
        serverErrorMessages: Map.unmodifiable(_serverErrorMessages),
      );
      _stateController.add(state);
    }
  }

  @override
  Stream<McpClientState> get mcpStateStream => _stateController.stream;

  @override
  McpClientState get currentMcpState => McpClientState(
    serverStatuses: Map.unmodifiable(_serverStatuses),
    discoveredTools: Map.unmodifiable(_discoveredTools),
    serverErrorMessages: Map.unmodifiable(_serverErrorMessages),
  );

  void _updateStatus(
    String serverId,
    McpConnectionStatus status, {
    String? errorMsg,
  }) {
    final currentStatus = _serverStatuses[serverId];

    if (currentStatus == status &&
        (errorMsg == null || _serverErrorMessages[serverId] == errorMsg)) {
      return;
    }

    _serverStatuses[serverId] = status;

    if (errorMsg != null) {
      _serverErrorMessages[serverId] = errorMsg;
    } else if (status != McpConnectionStatus.error) {
      _serverErrorMessages.remove(serverId);
    }

    if (status == McpConnectionStatus.disconnected ||
        status == McpConnectionStatus.error) {
      _activeClients.remove(serverId);
      _discoveredTools.remove(serverId);
    }

    _emitState();
  }

  void _handleClientConnectSuccess(
    String serverId,
    List<McpToolDefinition> tools,
  ) {
    _discoveredTools[serverId] = tools;
    _updateStatus(serverId, McpConnectionStatus.connected);
  }

  void _handleClientClose(String serverId) {
    _updateStatus(serverId, McpConnectionStatus.disconnected);
  }

  void _handleClientError(String serverId, String errorMsg) {
    _updateStatus(serverId, McpConnectionStatus.error, errorMsg: errorMsg);
  }

  // --- Connexion ---
  @override
  Future<void> connectServer({required McpServerConfig config}) async {
    debugPrint("MCP Repo [ [${config.id}]: Starting connection...");

    try {
      final newClientInstance = McpClient(config.id);
      newClientInstance.setupCallbacks(
        onConnectSuccess:
            (serverId, tools) => _handleClientConnectSuccess(serverId, tools),
        onClose: (serverId) => _handleClientClose(serverId),
        onError: (serverId, err) => _handleClientError(serverId, err),
      );

      _activeClients[config.id] = newClientInstance;
      _updateStatus(config.id, McpConnectionStatus.connecting);

      // Création du transport selon le mode
      late final ClientTransport transport;
      if (config.connectionMode == McpConnectionMode.http) {
        if (config.address == null || config.address!.isEmpty) {
          throw Exception(
            'Adresse HTTP manquante pour le serveur ${config.id}',
          );
        }
        transport = HttpMcpTransport(serverAddress: config.address!);
      } else if (config.connectionMode == McpConnectionMode.stdio) {
        if (config.command == null || config.command!.isEmpty) {
          throw Exception(
            'Commande manquante pour le serveur stdio ${config.id}',
          );
        }
        transport = StdioMcpTransport(
          command: config.command!,
          args: config.args,
          workingDirectory: config.workingDirectory,
          environment: config.customEnvironment,
        );
      } else {
        throw Exception(
          'Mode de connexion inconnu pour le serveur ${config.id}',
        );
      }

      await newClientInstance.connectWithTransport(transport);
    } catch (e) {
      debugPrint(
        "MCP Repo [${config.id}]: Connection failed during setup/initiation: $e",
      );
      _activeClients.remove(config.id);
      _updateStatus(
        config.id,
        McpConnectionStatus.error,
        errorMsg: "Connection failed: $e",
      );
    }
  }

  // --- Déconnexion ---
  @override
  Future<void> disconnectServer(String serverId) async {
    final client = _activeClients[serverId];
    if (client == null) {
      if (_serverStatuses[serverId] != McpConnectionStatus.disconnected) {
        _updateStatus(serverId, McpConnectionStatus.disconnected);
      }
      return;
    }
    debugPrint("MCP Repo [$serverId]: Disconnecting...");
    await client.cleanup();
    debugPrint(
      "MCP Repo [$serverId]: Disconnect process initiated for $serverId.",
    );
  }

  @override
  Future<void> disconnectAllServers() async {
    debugPrint("MCP Repo: Disconnecting all servers...");
    final serverIds = List<String>.from(_activeClients.keys);
    final futures = serverIds.map((id) => disconnectServer(id)).toList();
    try {
      await Future.wait(futures);
    } catch (e) {
      debugPrint("MCP Repo: Error during disconnectAll: $e");
    }
    debugPrint("MCP Repo: Disconnect all process complete.");
  }

  // --- Exécution d’outil ---
  @override
  Future<List<McpContent>> executeTool({
    required String serverId,
    required String toolName,
    required Map<String, dynamic> arguments,
  }) async {
    final client = _activeClients[serverId];
    if (client == null || !client.isConnected) {
      throw StateError("MCP Server [$serverId] is not connected or not found.");
    }

    try {
      final CallToolResult mcpDartResult = await client.callTool(
        toolName,
        arguments,
      );

      final List<McpContent> parsedContent = [];
      for (final mcpDartContent in mcpDartResult.content) {
        try {
          final jsonMap = mcpDartContent.toJson();
          parsedContent.add(McpContent.fromJson(jsonMap));
        } catch (e, stackTrace) {
          debugPrint(
            "Error translating content part for tool '$toolName' [$serverId]: $e\n$stackTrace\nRaw Content Part: $mcpDartContent",
          );
          parsedContent.add(
            McpUnknownContent(
              type: 'content_translate_error',
              additionalProperties: {
                'error': e.toString(),
                'raw_content': mcpDartContent.toJson(),
              },
            ),
          );
        }
      }
      return parsedContent;
    } catch (e) {
      debugPrint("MCP Repo [$serverId]: Error executing tool '$toolName': $e");
      rethrow;
    }
  }

  void dispose() {
    debugPrint("MCP Repo: Disposing...");
    disconnectAllServers();
    _stateController.close();
    _activeClients.clear();
    _serverStatuses.clear();
    _discoveredTools.clear();
    _serverErrorMessages.clear();
    debugPrint("MCP Repo: Disposed.");
  }
}
