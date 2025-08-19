/// Represents a message in the Model Context Protocol (MCP)
/// Used for communication between MCP clients and servers
class Message {
  /// The type of message (request, response, notification)
  final String type;

  /// The method name for requests/notifications
  final String? method;

  /// The message ID for requests
  final String? id;

  /// The parameters or result data
  final Map<String, dynamic>? data;

  /// Error information if this is an error response
  final Map<String, dynamic>? error;

  /// Creates a new message
  Message({
    required this.type,
    this.method,
    this.id,
    this.data,
    this.error,
  });

  /// Creates a message from JSON data
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      type: json['type'] ?? 'notification',
      method: json['method'],
      id: json['id'],
      data: json['params'] ?? json['result'],
      error: json['error'],
    );
  }

  /// Converts the message to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
    };

    if (method != null) {
      json['method'] = method;
    }

    if (id != null) {
      json['id'] = id;
    }

    if (data != null) {
      if (type == 'response') {
        json['result'] = data;
      } else {
        json['params'] = data;
      }
    }

    if (error != null) {
      json['error'] = error;
    }

    return json;
  }

  /// Creates a request message
  factory Message.request({
    required String method,
    required String id,
    Map<String, dynamic>? params,
  }) {
    return Message(
      type: 'request',
      method: method,
      id: id,
      data: params,
    );
  }

  /// Creates a response message
  factory Message.response({
    required String id,
    Map<String, dynamic>? result,
  }) {
    return Message(
      type: 'response',
      id: id,
      data: result,
    );
  }

  /// Creates an error response message
  factory Message.error({
    required String id,
    required Map<String, dynamic> error,
  }) {
    return Message(
      type: 'response',
      id: id,
      error: error,
    );
  }

  /// Creates a notification message
  factory Message.notification({
    required String method,
    Map<String, dynamic>? params,
  }) {
    return Message(
      type: 'notification',
      method: method,
      data: params,
    );
  }

  @override
  String toString() {
    return 'Message(type: $type, method: $method, id: $id, data: $data, error: $error)';
  }
}