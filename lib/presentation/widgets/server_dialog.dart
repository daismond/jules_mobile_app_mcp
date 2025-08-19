import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../domains/settings/entity/mcp_server_config.dart';

const _uuid = Uuid();

/// Helper class for managing Key-Value pairs in the dialog state
class _EnvVarPair {
  final String id;
  final TextEditingController keyController;
  final TextEditingController valueController;

  _EnvVarPair()
      : id = _uuid.v4(),
        keyController = TextEditingController(),
        valueController = TextEditingController();

  _EnvVarPair.fromMapEntry(MapEntry<String, String> entry)
      : id = _uuid.v4(),
        keyController = TextEditingController(text: entry.key),
        valueController = TextEditingController(text: entry.value);

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class ServerDialog extends StatefulWidget {
  final McpServerConfig? serverToEdit;
  final Function(McpServerConfig newServer) onAddServer;
  final Function(McpServerConfig updatedServer) onUpdateServer;
  final Function(String) onError;

  const ServerDialog({
    super.key,
    this.serverToEdit,
    required this.onAddServer,
    required this.onUpdateServer,
    required this.onError,
  });

  @override
  State<ServerDialog> createState() => _ServerDialogState();
}

class _ServerDialogState extends State<ServerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _commandController;
  late final TextEditingController _argsController;
  late final TextEditingController _addressController;
  late McpConnectionMode _connectionMode;
  late bool _isActive;
  late List<_EnvVarPair> _envVars;
  final List<TextEditingController> _allControllers = [];
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.serverToEdit != null;

  @override
  void initState() {
    super.initState();
    _connectionMode =
        widget.serverToEdit?.connectionMode ?? McpConnectionMode.stdio;

    _nameController = TextEditingController(
      text: widget.serverToEdit?.name ?? '',
    );
    _commandController = TextEditingController(
      text: widget.serverToEdit?.command ?? '',
    );
    _argsController = TextEditingController(
      text: widget.serverToEdit?.args ?? '',
    );
    _addressController = TextEditingController(
      text: widget.serverToEdit?.address ?? '',
    );
    _isActive = widget.serverToEdit?.isActive ?? false;

    _envVars = widget.serverToEdit?.customEnvironment.entries
            .map((e) => _EnvVarPair.fromMapEntry(e))
            .toList() ??
        [];

    _registerControllers();
  }

  void _registerControllers() {
    _allControllers.addAll([
      _nameController,
      _commandController,
      _argsController,
      _addressController,
    ]);

    for (var pair in _envVars) {
      _allControllers.add(pair.keyController);
      _allControllers.add(pair.valueController);
    }
  }

  @override
  void dispose() {
    for (var controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addEnvVar() {
    setState(() {
      final newPair = _EnvVarPair();
      _envVars.add(newPair);
      _allControllers.add(newPair.keyController);
      _allControllers.add(newPair.valueController);
    });
  }

  void _removeEnvVar(String id) {
    setState(() {
      final pairIndex = _envVars.indexWhere((p) => p.id == id);
      if (pairIndex != -1) {
        final pairToRemove = _envVars[pairIndex];
        _allControllers.remove(pairToRemove.keyController);
        _allControllers.remove(pairToRemove.valueController);
        pairToRemove.dispose();
        _envVars.removeAt(pairIndex);
      }
    });
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final command = _commandController.text.trim();
      final args = _argsController.text.trim();
      final address = _addressController.text.trim();
      final Map<String, String> customEnvMap = {};
      bool envVarError = false;

      for (var pair in _envVars) {
        final key = pair.keyController.text.trim();
        final value = pair.valueController.text;
        if (key.isNotEmpty) {
          if (customEnvMap.containsKey(key)) {
            widget.onError('Error: Duplicate environment key "$key"');
            envVarError = true;
            break;
          }
          customEnvMap[key] = value;
        } else if (value.isNotEmpty) {
          debugPrint("Ignoring env var with empty key and non-empty value.");
        }
      }

      if (envVarError) {
        return;
      }

      Navigator.of(context).pop();

      if (_isEditing) {
        final updatedServer = widget.serverToEdit!.copyWith(
          name: name,
          connectionMode: _connectionMode,
          command: _connectionMode == McpConnectionMode.stdio ? command : null,
          args: _connectionMode == McpConnectionMode.stdio ? args : null,
          address: _connectionMode == McpConnectionMode.http ? address : null,
          isActive: _isActive,
          customEnvironment: customEnvMap,
        );
        widget.onUpdateServer(updatedServer);
      } else {
        final newServer = McpServerConfig(
          id: _uuid.v4(),
          name: name,
          connectionMode: _connectionMode,
          command: _connectionMode == McpConnectionMode.stdio ? command : null,
          args: _connectionMode == McpConnectionMode.stdio ? args : null,
          address: _connectionMode == McpConnectionMode.http ? address : null,
          isActive: _isActive,
          customEnvironment: customEnvMap,
        );
        widget.onAddServer(newServer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Server' : 'Add New Server'),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Server Name*'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              SegmentedButton<McpConnectionMode>(
                segments: const <ButtonSegment<McpConnectionMode>>[
                  ButtonSegment<McpConnectionMode>(
                    value: McpConnectionMode.stdio,
                    label: Text('Local Process'),
                    icon: Icon(Icons.terminal),
                  ),
                  ButtonSegment<McpConnectionMode>(
                    value: McpConnectionMode.http,
                    label: Text('Remote Server'),
                    icon: Icon(Icons.http),
                  ),
                ],
                selected: {_connectionMode},
                onSelectionChanged: (Set<McpConnectionMode> newSelection) {
                  setState(() {
                    _connectionMode = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_connectionMode == McpConnectionMode.stdio)
                Column(
                  children: [
                    TextFormField(
                      controller: _commandController,
                      decoration: const InputDecoration(
                        labelText: 'Server Command*',
                        hintText: r'/path/to/server or server.exe',
                      ),
                      validator: (v) => (_connectionMode ==
                                  McpConnectionMode.stdio &&
                              (v == null || v.trim().isEmpty))
                          ? 'Command cannot be empty'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _argsController,
                      decoration: const InputDecoration(
                        labelText: 'Server Arguments',
                        hintText: r'--port 1234 --verbose',
                      ),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Server Address*',
                    hintText: r'http://localhost:8080',
                  ),
                  validator: (v) =>
                      (_connectionMode == McpConnectionMode.http &&
                              (v == null || v.trim().isEmpty))
                          ? 'Address cannot be empty'
                          : null,
                ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Connect Automatically'),
                subtitle: const Text('Applies when settings change'),
                value: _isActive,
                onChanged: (bool value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Custom Environment Variables',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Variable',
                    onPressed: _addEnvVar,
                  ),
                ],
              ),
              const Text(
                'Overrides system variables.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              if (_envVars.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'No custom variables defined.',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                ...List.generate(_envVars.length, (index) {
                  final pair = _envVars[index];
                  return Padding(
                    key: ValueKey(pair.id),
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: pair.keyController,
                            decoration: const InputDecoration(
                              labelText: 'Key',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: pair.valueController,
                            decoration: const InputDecoration(
                              labelText: 'Value',
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          tooltip: 'Remove Variable',
                          onPressed: () => _removeEnvVar(pair.id),
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed: _handleSubmit,
          child: Text(_isEditing ? 'Save Changes' : 'Add Server'),
        ),
      ],
    );
  }
}

/// Shows the server dialog and handles the result
Future<void> showServerDialog({
  required BuildContext context,
  McpServerConfig? serverToEdit,
  required Function(McpServerConfig newServer) onAddServer,
  required Function(McpServerConfig updatedServer) onUpdateServer,
  required Function(String) onError,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return ServerDialog(
        serverToEdit: serverToEdit,
        onAddServer: onAddServer,
        onUpdateServer: onUpdateServer,
        onError: onError,
      );
    },
  );
}
