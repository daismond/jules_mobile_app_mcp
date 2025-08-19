import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:mcp_dart/src/types.dart';

import '../client_transport.dart';

/// An MCP transport that communicates with a local process over stdio.
class StdioMcpTransport implements ClientTransport {
  final String command;
  final String? args;
  final String? workingDirectory;
  final Map<String, String> environment;

  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  Completer<void>? _exitCodeCompleter;

  @override
  void Function(JsonRpcMessage message)? onmessage;

  @override
  void Function(Error error)? onerror;

  @override
  Function()? onclose;

  @override
  String? get sessionId => _process?.pid.toString();

  StdioMcpTransport({
    required this.command,
    this.args,
    this.workingDirectory,
    this.environment = const {},
  });

  @override
  Future<void> start() async {
    if (_process == null) {
      await _startProcess();
    }
  }

  Future<void> _startProcess() async {
    debugPrint(
      'StdioTransport: Starting process: $command ${args ?? ''}',
    );
    try {
      final arguments = args?.split(' ').where((s) => s.isNotEmpty).toList() ?? [];
      _process = await Process.start(
        command,
        arguments,
        workingDirectory: workingDirectory,
        environment: environment,
        runInShell: true, // Often needed for correct path resolution
      );

      // Handle process exit
      _exitCodeCompleter = Completer<void>();
      _process!.exitCode.then((code) {
        debugPrint('StdioTransport: Process exited with code $code');
        if (!_exitCodeCompleter!.isCompleted) {
          _exitCodeCompleter!.complete();
        }
        close(); // Trigger cleanup and onclose callback
      });

      // Handle stderr
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        debugPrint('StdioTransport [stderr]: $line');
        onerror?.call(ArgumentError(line));
      });

      // Handle stdout
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          try {
            if (line.trim().isEmpty) return;
            debugPrint('StdioTransport [stdout]: Received line: $line');
            final json = jsonDecode(line);
            final message = JsonRpcMessage.fromJson(json);
            onmessage?.call(message);
          } catch (e) {
            final errorMsg = 'StdioTransport: Error parsing message: $e';
            debugPrint(errorMsg);
            onerror?.call(ArgumentError(errorMsg));
          }
        },
        onError: (error) {
          final errorMsg = 'StdioTransport: Error on stdout stream: $error';
          debugPrint(errorMsg);
          onerror?.call(ArgumentError(errorMsg));
        },
        onDone: () {
          debugPrint('StdioTransport: stdout stream closed.');
          close();
        },
      );

      debugPrint('StdioTransport: Process started successfully.');
    } catch (e) {
      final errorMsg = 'StdioTransport: Failed to start process: $e';
      debugPrint(errorMsg);
      onerror?.call(ArgumentError(errorMsg));
      // Ensure we close/cleanup if start fails
      await close();
    }
  }

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_process == null) {
      final errorMsg = 'StdioTransport: Cannot send message, process not running.';
      debugPrint(errorMsg);
      onerror?.call(ArgumentError(errorMsg));
      return;
    }
    try {
      final jsonString = jsonEncode(message.toJson());
      debugPrint('StdioTransport [stdin]: Sending: $jsonString');
      _process!.stdin.writeln(jsonString);
      await _process!.stdin.flush();
    } catch (e) {
      final errorMsg = 'StdioTransport: Failed to write to stdin: $e';
      debugPrint(errorMsg);
      onerror?.call(ArgumentError(errorMsg));
    }
  }

  @override
  Future<void> close() async {
    debugPrint('StdioTransport: Closing...');
    // Cancel subscriptions to prevent further events
    await _stdoutSubscription?.cancel();
    await _stderrSubscription?.cancel();
    _stdoutSubscription = null;
    _stderrSubscription = null;

    // Kill the process if it's still running
    if (_process != null) {
      // Check if exit code has completed. If not, the process is likely running.
      if (_exitCodeCompleter == null || !_exitCodeCompleter!.isCompleted) {
        debugPrint('StdioTransport: Killing process...');
        _process!.kill(ProcessSignal.sigterm);
      }
      _process = null;
    }

    // Fire the onclose callback if it hasn't been fired yet.
    // This is the primary notification mechanism.
    if (onclose != null) {
      final callback = onclose;
      onclose = null; // Set to null to prevent re-firing
      callback?.call();
    }
    debugPrint('StdioTransport: Closed.');
  }
}
