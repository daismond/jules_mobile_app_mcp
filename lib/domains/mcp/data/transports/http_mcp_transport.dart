import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mcp_dart/mcp_dart.dart';
import 'package:mcp_dart/src/types.dart';

import '../client_transport.dart';

class HttpMcpTransport implements ClientTransport {
  final Uri serverUri;
  final http.Client _httpClient;

  @override
  void Function(JsonRpcMessage message)? onmessage;

  @override
  void Function(Error error)? onerror;

  @override
  Function()? onclose;

  @override
  String? get sessionId => null;

  HttpMcpTransport({required String serverAddress})
      : serverUri = Uri.parse(serverAddress),
        _httpClient = http.Client();

  @override
  Future<void> start() async {
    // No-op for HTTP transport
  }

  @override
  Future<void> close() async {
    _httpClient.close();
    onclose?.call();
  }

  @override
  Future<void> send(JsonRpcMessage message) async {
    try {
      final response = await _httpClient.post(
        serverUri.resolve('/call'), // A standard endpoint for all calls
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message.toJson()),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final replyMessage = JsonRpcMessage.fromJson(responseBody);
        // The mcp_dart Client is waiting for this callback.
        onmessage?.call(replyMessage);
      } else {
        // Create a proper error message and send it back
        final errorContent = 'Server returned error: ${response.statusCode}';
        final errorMessage = JsonRpcResponse(id: 'error-${DateTime.now().millisecondsSinceEpoch}', result: {'error': JsonRpcError(id: 'error-${DateTime.now().millisecondsSinceEpoch}', error: JsonRpcErrorData(code: -32000, message: errorContent))});
        onmessage?.call(errorMessage);
      }
    } catch (e) {
      onerror?.call(e as Error);
    }
  }
}