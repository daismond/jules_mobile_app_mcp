import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_chat_desktop/domains/settings/entity/ai_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entity/mcp_server_config.dart';
import '../repository/settings_repository.dart';

// Storage keys are implementation details of the data layer.
const String _aiConfigKey = 'aiConfig';
const String mcpServerListKey = 'mcpServerList';

/// Implementation of SettingsRepository using SharedPreferences and FlutterSecureStorage.
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;
  // Use const constructor for secure storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  SettingsRepositoryImpl(this._prefs);

  // --- AI Configuration (using FlutterSecureStorage) ---
  @override
  Future<AIConfig> getAIConfig() async {
    try {
      final jsonString = await _secureStorage.read(key: _aiConfigKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        return AIConfig.fromJson(jsonString);
      }
    } catch (e) {
      debugPrint("Error reading AI config from secure storage: $e");
      // Fallback to default config on error
    }
    return const AIConfig(); // Return default config if not found or on error
  }

  @override
  Future<void> saveAIConfig(AIConfig config) async {
    try {
      final jsonString = config.toJson();
      await _secureStorage.write(key: _aiConfigKey, value: jsonString);
    } catch (e) {
      debugPrint("Error saving AI config to secure storage: $e");
      rethrow; // Rethrow to allow service layer to handle UI feedback
    }
  }


  // --- MCP Server List (using SharedPreferences) ---
  @override
  Future<List<McpServerConfig>> getMcpServerList() async {
    try {
      final serverListJson = _prefs.getString(mcpServerListKey);
      if (serverListJson != null && serverListJson.isNotEmpty) {
        final decodedList = jsonDecode(serverListJson) as List;
        final configList =
            decodedList
                .map(
                  (item) =>
                      McpServerConfig.fromJson(item as Map<String, dynamic>),
                )
                .toList();
        return configList;
      }
      return [];
    } catch (e) {
      debugPrint("Error loading/parsing server list in repository: $e");
      return []; // Return empty list on error
    }
  }

  @override
  Future<void> saveMcpServerList(List<McpServerConfig> servers) async {
    try {
      final serverListJson = jsonEncode(
        servers.map((s) => s.toJson()).toList(),
      );
      await _prefs.setString(mcpServerListKey, serverListJson);
    } catch (e) {
      debugPrint("Error saving MCP server list in repository: $e");
      rethrow;
    }
  }
}
