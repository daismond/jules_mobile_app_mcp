import '../entity/ai_config.dart';
import '../entity/mcp_server_config.dart';

/// Abstract repository for managing application settings.
abstract class SettingsRepository {
  // AI Configuration
  Future<AIConfig> getAIConfig();
  Future<void> saveAIConfig(AIConfig config);

  // MCP Server List
  Future<List<McpServerConfig>> getMcpServerList();
  Future<void> saveMcpServerList(List<McpServerConfig> servers);
}
