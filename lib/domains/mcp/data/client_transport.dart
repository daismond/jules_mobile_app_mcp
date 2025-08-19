import 'message.dart';

/// Interface for MCP client transport implementations.
/// This interface defines the contract that all MCP transport
/// implementations must follow to communicate with MCP servers.
abstract class ClientTransport {
  /// Callback fired when a message is received from the server
  Function(Message)? onmessage;

  /// Callback fired when an error occurs during transport
  Function(dynamic)? onerror;

  /// Callback fired when the transport connection is closed
  Function()? onclose;

  /// Sends a message to the MCP server
  Future<void> send(Message message);

  /// Closes the transport connection
  Future<void> close();
}