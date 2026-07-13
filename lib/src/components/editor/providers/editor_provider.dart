import '../../storage/project_storage.dart';
import '../models/schema_model.dart';
import './commands_provider.dart';

class EditorProvider {
  EditorProvider({
    required SchemaState schemaState,
    required String projectName,
    required ProjectStorage projectStorage,
    CommandsProvider? commandsProvider,
  }) : _schemaState = schemaState,
       _projectName = projectName,
       _projectStorage = projectStorage,
       _commandsProvider = commandsProvider ?? CommandsProvider();

  final SchemaState _schemaState;
  final String _projectName;
  final ProjectStorage _projectStorage;
  final CommandsProvider _commandsProvider;
  final List<String> _commandHistory = [];

  String _lastFeedback = 'Digite um comando para alterar o schema.';
  bool _lastCommandFailed = false;

  SchemaState get schemaState => _schemaState;
  String get lastFeedback => _lastFeedback;
  bool get lastCommandFailed => _lastCommandFailed;
  List<String> get commandHistory => List.unmodifiable(_commandHistory);

  void submitCommand(String rawCommand) {
    final command = rawCommand.trim();
    if (command.isEmpty) {
      _lastCommandFailed = true;
      _lastFeedback = 'Comando vazio. Exemplo: create table users';
      return;
    }

    if (command.toLowerCase() == 'history') {
      _lastCommandFailed = false;
      if (_commandHistory.isEmpty) {
        _lastFeedback = 'Ainda não há comandos no histórico.';
        return;
      }
      final start = _commandHistory.length > 15
          ? _commandHistory.length - 15
          : 0;
      final items = <String>[];
      for (var i = start; i < _commandHistory.length; i++) {
        items.add('${i + 1}. ${_commandHistory[i]}');
      }
      _lastFeedback = items.join(' | ');
      return;
    }

    _commandHistory.add(command);
    final parts = _splitChainedCommands(command);
    if (parts.isEmpty) {
      _lastCommandFailed = true;
      _lastFeedback =
          'Comando inválido. Use "help" para ver os formatos suportados.';
      return;
    }

    final feedbackParts = <String>[];
    var shouldPersist = false;

    for (final part in parts) {
      final result = _commandsProvider.handle(
        part,
        _schemaState,
        projectName: _projectName,
        projectStorage: _projectStorage,
      );

      feedbackParts.add(result.message);

      if (!result.success) {
        _lastCommandFailed = true;
        _lastFeedback = feedbackParts.join(' | ');
        return;
      }

      if (result.shouldPersist) {
        shouldPersist = true;
      }
    }

    if (shouldPersist) {
      try {
        _projectStorage.saveProject(_projectName, _schemaState);
      } catch (error) {
        _lastCommandFailed = true;
        _lastFeedback =
            'Comandos aplicados, mas falhou ao salvar projeto: $error';
        return;
      }
    }

    _lastCommandFailed = false;
    _lastFeedback = feedbackParts.join(' | ');
  }

  List<String> _splitChainedCommands(String command) {
    final parts = <String>[];
    var depth = 0;
    var start = 0;
    var i = 0;

    while (i < command.length) {
      final char = command[i];
      if (char == '(') {
        depth += 1;
        i += 1;
        continue;
      }
      if (char == ')' && depth > 0) {
        depth -= 1;
        i += 1;
        continue;
      }

      if (depth == 0 &&
          i + 2 < command.length &&
          command[i] == ' ' &&
          command[i + 1] == '-' &&
          command[i + 2] == ' ') {
        final chunk = command.substring(start, i).trim();
        if (chunk.isNotEmpty) {
          parts.add(chunk);
        }
        start = i + 3;
        i += 3;
        continue;
      }
      i += 1;
    }

    final tail = command.substring(start).trim();
    if (tail.isNotEmpty) {
      parts.add(tail);
    }
    return parts;
  }
}
