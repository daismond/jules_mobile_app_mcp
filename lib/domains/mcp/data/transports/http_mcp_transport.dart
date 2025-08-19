import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../message.dart';

import '../client_transport.dart';

class HttpMcpTransport implements ClientTransport {
  final Uri serverUri;
  final http.Client _httpClient;

  @override
  Function(Message)? onmessage;

  @override
  Function(dynamic)? onerror;

  @override
  Function()? onclose;

  HttpMcpTransport({required String serverAddress})
      : serverUri = Uri.parse(serverAddress),
        _httpClient = http.Client();

  @override
  Future<void> connect() async {
    try {
      // A simple GET request to a health check endpoint to see if server is up.
      final response = await _httpClient.get(serverUri.resolve('/health'));
      if (response.statusCode != 200) {
        throw Exception('Server health check failed: [31m[0m');
      }
    } catch (e) {
      onerror?.call(e);
      rethrow;
    }
  }

  @override
  Future<void> close() async {
    _httpClient.close();
    onclose?.call();
  }

  @override
  Future<void> send(Message message) async {
    try {
      final response = await _httpClient.post(
        serverUri.resolve('/call'), // A standard endpoint for all calls
        headers: {'Content-Type': 'application/json'},
        body: json.encode(message.toJson()),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final replyMessage = Message.fromJson(responseBody);
        // The mcp_dart Client is waiting for this callback.
        onmessage?.call(replyMessage);
      } else {
        // Create a proper error message and send it back
        final errorContent = 'Server returned error: [31m[0m';
        final errorMessage = Message(
          id: 'error-${DateTime.now().millisecondsSinceEpoch}',
          type: 'response',
          error: {'message': errorContent},
        );
        onmessage?.call(errorMessage);
      }
    } catch (e) {
      onerror?.call(e);
    }
  }
}