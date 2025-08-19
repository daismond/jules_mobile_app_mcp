import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entity/mcp_server_config.dart';
import '../repository/settings_repository.dart';

// Storage keys are implementation details of the data layer.
const String _apiKeyStorageKey = 'geminiApiKey';
const String mcpServerListKey = 'mcpServerList';

/// Implementation of SettingsRepository using SharedPreferences and FlutterSecureStorage.
class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;
  // Use const constructor for secure storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  SettingsRepositoryImpl(this._prefs);

  // --- API Key (using FlutterSecureStorage) ---
  @override
  Future<String?> getApiKey() async {
    try {
      return await _secureStorage.read(key: _apiKeyStorageKey);
    } catch (e) {
      debugPrint("Error reading API key from secure storage: $e");
      // Optionally handle specific errors, e.g., platform exceptions
      return null;
    }
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _apiKeyStorageKey, value: apiKey);
    } catch (e) {
      debugPrint("Error saving API key to secure storage: $e");
      rethrow; // Rethrow to allow service layer to handle UI feedback
    }
  }

  @override
  Future<void> clearApiKey() async {
    try {
      await _secureStorage.delete(key: _apiKeyStorageKey);
    } catch (e) {
      debugPrint("Error clearing API key from secure storage: $e");
      rethrow;
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
