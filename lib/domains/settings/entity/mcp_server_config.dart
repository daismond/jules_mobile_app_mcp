import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart'; // For MapEquality

enum McpConnectionMode {
  stdio,
  http;

  String toJson() => name;
  static McpConnectionMode fromJson(String json) => values.byName(json);
}

/// Configuration for a single MCP server.
@immutable
class McpServerConfig {
  final String id; // Unique ID
  final String name;
  final bool isActive; // User's desired state (connect on apply)
  final McpConnectionMode connectionMode;

  // Stdio-specific fields
  final String? command;
  final String? args;
  final Map<String, String> customEnvironment;

  // HTTP-specific fields
  final String? address;

  const McpServerConfig({
    required this.id,
    required this.name,
    this.isActive = false,
    this.connectionMode = McpConnectionMode.stdio,
    this.command,
    this.args,
    this.customEnvironment = const {},
    this.address,
  }) : assert(
         (connectionMode == McpConnectionMode.stdio && command != null) ||
             (connectionMode == McpConnectionMode.http && address != null),
         'For stdio, command is required. For http, address is required.',
       );

  McpServerConfig copyWith({
    String? id,
    String? name,
    bool? isActive,
    McpConnectionMode? connectionMode,
    String? command,
    String? args,
    Map<String, String>? customEnvironment,
    String? address,
  }) {
    return McpServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      connectionMode: connectionMode ?? this.connectionMode,
      command: command ?? this.command,
      args: args ?? this.args,
      customEnvironment: customEnvironment ?? this.customEnvironment,
      address: address ?? this.address,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'isActive': isActive,
    'connectionMode': connectionMode.toJson(),
    'command': command,
    'args': args,
    'customEnvironment': customEnvironment,
    'address': address,
  };

  factory McpServerConfig.fromJson(Map<String, dynamic> json) {
    Map<String, String> environment = {};
    if (json['customEnvironment'] is Map) {
      try {
        environment = Map<String, String>.from(
          (json['customEnvironment'] as Map).map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ),
        );
      } catch (e) {
        debugPrint(
          "Error parsing customEnvironment for server ${json['id']}: $e",
        );
      }
    }

    return McpServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      isActive: json['isActive'] as bool? ?? false,
      connectionMode:
          json['connectionMode'] != null
              ? McpConnectionMode.fromJson(json['connectionMode'])
              : McpConnectionMode.stdio,
      command: json['command'] as String?,
      args: json['args'] as String?,
      customEnvironment: environment,
      address: json['address'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is McpServerConfig &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isActive == other.isActive &&
          connectionMode == other.connectionMode &&
          command == other.command &&
          args == other.args &&
          address == other.address &&
          const MapEquality().equals(
            customEnvironment,
            other.customEnvironment,
          );

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      isActive.hashCode ^
      connectionMode.hashCode ^
      command.hashCode ^
      args.hashCode ^
      address.hashCode ^
      const MapEquality().hash(customEnvironment);
}
