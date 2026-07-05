import '../../model/schema_state.dart';

class EditorProvider {
  EditorProvider({SchemaState? schemaState, CommandsProvider? commandsProvider})
    : _schemaState = schemaState ?? SchemaState(),
      _commandsProvider = commandsProvider ?? CommandsProvider();

  final SchemaState _schemaState;
  final CommandsProvider _commandsProvider;
  final List<String> _commandHistory = [];

  String _lastFeedback = 'Digite um comando para alterar o schema.';
  bool _lastCommandFailed = false;

  SchemaState get schemaState => _schemaState;
  String get lastFeedback => _lastFeedback;
  bool get lastCommandFailed => _lastCommandFailed;
  List<String> get commandHistory => List.unmodifiable(_commandHistory);

  void initializeEditorSchema() {
    if (_schemaState.tables.isNotEmpty) return;
    _schemaState.addTable('subjects');
    _schemaState.addColumn('subjects', 'id', 'serial');
    _schemaState.addColumn('subjects', 'name', 'varchar');
    _schemaState.setPrimaryKey('subjects', 'id');
  }

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
      final start = _commandHistory.length > 15 ? _commandHistory.length - 15 : 0;
      final items = <String>[];
      for (var i = start; i < _commandHistory.length; i++) {
        items.add('${i + 1}. ${_commandHistory[i]}');
      }
      _lastFeedback = items.join(' | ');
      return;
    }

    _commandHistory.add(command);
    final result = _commandsProvider.handle(command, _schemaState);
    _lastCommandFailed = !result.success;
    _lastFeedback = result.message;
  }
}

class CommandsProvider {
  static const String _identifier = r'([a-zA-Z_][a-zA-Z0-9_]*)';
  static const String _typeToken =
      r'([a-zA-Z_][a-zA-Z0-9_]*(?:\([0-9,\s]+\))?)';

  static final RegExp _createTablePattern = RegExp(
    '^create\\s+table\\s+$_identifier(?:\\s+(--autoincrement))?\$',
    caseSensitive: false,
  );
  static final RegExp _addColumnsPattern = RegExp(
    '^add\\s+columns?\\s+$_identifier\\s+(.+)\$',
    caseSensitive: false,
  );
  static final RegExp _addColumnVerbosePattern = RegExp(
    '^add\\s+column\\s+$_identifier\\s+type\\s+$_typeToken\\s+to\\s+$_identifier(?:\\s+options\\(([^)]*)\\))?(?:\\s+description\\(([^)]*)\\))?\$',
    caseSensitive: false,
  );
  static final RegExp _setPrimaryKeyPattern = RegExp(
    '^set\\s+pk\\s+$_identifier\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _addForeignKeyPattern = RegExp(
    '^add\\s+fk\\s+$_identifier\\s+$_identifier\\s+references\\s+$_identifier\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _setDatabasePattern = RegExp(
    r'^set\s+database\s+(postgres|mysql|sqlite)$',
    caseSensitive: false,
  );
  static final RegExp _renameTablePattern = RegExp(
    '^rename\\s+table\\s+$_identifier\\s+to\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _changeTablePattern = RegExp(
    '^change\\s+table\\s+$_identifier\\s+to\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _renameColumnPattern = RegExp(
    '^rename\\s+column\\s+$_identifier\\s+$_identifier\\s+to\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _changeColumnPattern = RegExp(
    '^change\\s+column\\s+$_identifier\\s+$_identifier\\s+to\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _alterColumnTypePattern = RegExp(
    '^alter\\s+column\\s+$_identifier\\s+$_identifier\\s+type\\s+$_typeToken(?:\\s+options\\(([^)]*)\\))?\$',
    caseSensitive: false,
  );
  static final RegExp _changeColumnTypePattern = RegExp(
    '^change\\s+column\\s+$_identifier\\s+$_identifier\\s+type\\s+$_typeToken(?:\\s+options\\(([^)]*)\\))?\$',
    caseSensitive: false,
  );
  static final RegExp _columnSpecPattern = RegExp(
    '^$_identifier\\s+$_typeToken(?:\\s+options\\(([^)]*)\\))?(?:\\s+description\\(([^)]*)\\))?\$',
    caseSensitive: false,
  );

  EditorCommandResult handle(String command, SchemaState schemaState) {
    final lower = command.toLowerCase();

    if (lower == 'help') {
      return EditorCommandResult.success(_buildHelpMessage(schemaState.databaseEngine));
    }

    if (lower == 'show tables') {
      if (schemaState.tables.isEmpty) {
        return const EditorCommandResult.success('Nenhuma tabela criada ainda.');
      }
      final names = schemaState.tables.map((t) => t.name).join(', ');
      return EditorCommandResult.success('Tabelas: $names');
    }

    if (lower == 'show database') {
      return EditorCommandResult.success(
        'Database atual: ${schemaState.databaseEngine.name}',
      );
    }

    if (lower == 'show types') {
      final allowed = schemaState.getAllowedTypes().toList()..sort();
      return EditorCommandResult.success(
        'Tipos ${schemaState.databaseEngine.name}: ${allowed.join(', ')}',
      );
    }

    final createTableMatch = _createTablePattern.firstMatch(command);
    if (createTableMatch != null) {
      final tableName = createTableMatch.group(1)!;
      final autoIncrement = createTableMatch.group(2) != null;
      return _handleCreateTable(tableName, schemaState, autoIncrement: autoIncrement);
    }

    final addColumnVerboseMatch = _addColumnVerbosePattern.firstMatch(command);
    if (addColumnVerboseMatch != null) {
      final columnName = addColumnVerboseMatch.group(1)!;
      final type = addColumnVerboseMatch.group(2)!;
      final tableName = addColumnVerboseMatch.group(3)!;
      final optionsResult = _parseEnumOptions(addColumnVerboseMatch.group(4));
      if (!optionsResult.success) {
        return EditorCommandResult.failure(optionsResult.message);
      }
      return _handleAddColumns(
        tableName,
        [
          _ColumnInputSpec(
            name: columnName,
            type: type,
            enumOptions: optionsResult.options,
            description: _cleanDescription(addColumnVerboseMatch.group(5)),
          ),
        ],
        schemaState,
      );
    }

    final addColumnsMatch = _addColumnsPattern.firstMatch(command);
    if (addColumnsMatch != null) {
      final tableName = addColumnsMatch.group(1)!;
      final payload = addColumnsMatch.group(2)!;
      final specsResult = _parseColumnSpecs(payload);
      if (!specsResult.success) {
        return EditorCommandResult.failure(specsResult.message);
      }
      return _handleAddColumns(tableName, specsResult.specs, schemaState);
    }

    final setPrimaryKeyMatch = _setPrimaryKeyPattern.firstMatch(command);
    if (setPrimaryKeyMatch != null) {
      final tableName = setPrimaryKeyMatch.group(1)!;
      final columnName = setPrimaryKeyMatch.group(2)!;
      return _handleSetPrimaryKey(tableName, columnName, schemaState);
    }

    final addForeignKeyMatch = _addForeignKeyPattern.firstMatch(command);
    if (addForeignKeyMatch != null) {
      final tableName = addForeignKeyMatch.group(1)!;
      final columnName = addForeignKeyMatch.group(2)!;
      final referenceTableName = addForeignKeyMatch.group(3)!;
      final referenceColumnName = addForeignKeyMatch.group(4)!;
      return _handleAddForeignKey(
        tableName,
        columnName,
        referenceTableName,
        referenceColumnName,
        schemaState,
      );
    }

    final setDatabaseMatch = _setDatabasePattern.firstMatch(command);
    if (setDatabaseMatch != null) {
      final database = setDatabaseMatch.group(1)!.toLowerCase();
      return _handleSetDatabase(database, schemaState);
    }

    final renameTableMatch =
        _renameTablePattern.firstMatch(command) ??
        _changeTablePattern.firstMatch(command);
    if (renameTableMatch != null) {
      final oldName = renameTableMatch.group(1)!;
      final newName = renameTableMatch.group(2)!;
      return _handleRenameTable(oldName, newName, schemaState);
    }

    final renameColumnMatch =
        _renameColumnPattern.firstMatch(command) ??
        _changeColumnPattern.firstMatch(command);
    if (renameColumnMatch != null) {
      final tableName = renameColumnMatch.group(1)!;
      final oldName = renameColumnMatch.group(2)!;
      final newName = renameColumnMatch.group(3)!;
      return _handleRenameColumn(tableName, oldName, newName, schemaState);
    }

    final alterColumnTypeMatch =
        _alterColumnTypePattern.firstMatch(command) ??
        _changeColumnTypePattern.firstMatch(command);
    if (alterColumnTypeMatch != null) {
      final tableName = alterColumnTypeMatch.group(1)!;
      final columnName = alterColumnTypeMatch.group(2)!;
      final newType = alterColumnTypeMatch.group(3)!;
      final optionsResult = _parseEnumOptions(alterColumnTypeMatch.group(4));
      if (!optionsResult.success) {
        return EditorCommandResult.failure(optionsResult.message);
      }
      return _handleAlterColumnType(
        tableName,
        columnName,
        newType,
        schemaState,
        enumOptions: optionsResult.options,
      );
    }

    return const EditorCommandResult.failure(
      'Comando inválido. Use "help" para ver os formatos suportados.',
    );
  }

  EditorCommandResult _handleCreateTable(
    String tableName,
    SchemaState schemaState, {
    required bool autoIncrement,
  }) {
    final alreadyExists = schemaState.tables.any(
      (t) => t.name.toLowerCase() == tableName.toLowerCase(),
    );
    if (alreadyExists) {
      return EditorCommandResult.failure('A tabela "$tableName" já existe.');
    }

    schemaState.addTable(tableName);
    if (autoIncrement) {
      _addAutoIncrementId(tableName, schemaState);
      return EditorCommandResult.success(
        'Tabela "$tableName" criada com id autoincrement.',
      );
    }
    return EditorCommandResult.success('Tabela "$tableName" criada com sucesso.');
  }

  void _addAutoIncrementId(String tableName, SchemaState schemaState) {
    final idType = switch (schemaState.databaseEngine) {
      DatabaseEngine.postgres => 'serial',
      DatabaseEngine.mysql => 'int',
      DatabaseEngine.sqlite => 'integer',
    };
    schemaState.addColumn(tableName, 'id', idType, description: 'auto increment');
    schemaState.setPrimaryKey(tableName, 'id');
  }

  EditorCommandResult _handleAddColumns(
    String tableName,
    List<_ColumnInputSpec> specs,
    SchemaState schemaState,
  ) {
    final table = schemaState.findTableByName(tableName);
    if (table == null) {
      return EditorCommandResult.failure('Tabela "$tableName" não encontrada.');
    }

    final existingNames = table.columns.map((c) => c.name.toLowerCase()).toSet();
    final batchNames = <String>{};
    final added = <String>[];

    for (final spec in specs) {
      final normalizedName = spec.name.toLowerCase();
      if (existingNames.contains(normalizedName) || batchNames.contains(normalizedName)) {
        return EditorCommandResult.failure(
          'A coluna "${spec.name}" já existe em "$tableName".',
        );
      }
      batchNames.add(normalizedName);

      if (!schemaState.isColumnTypeAllowed(spec.type)) {
        return _invalidTypeResult(spec.type, schemaState);
      }

      final isEnum = _normalizeType(spec.type) == 'enum';
      final hasEnumOptions = spec.enumOptions.isNotEmpty;
      if (isEnum && !hasEnumOptions) {
        return EditorCommandResult.failure(
          'A coluna "${spec.name}" é enum e precisa de options(v1|v2|...).',
        );
      }
      if (!isEnum && hasEnumOptions) {
        return EditorCommandResult.failure(
          'options(...) só pode ser usado com tipo enum (coluna "${spec.name}").',
        );
      }

      schemaState.addColumn(
        table.name,
        spec.name,
        spec.type,
        enumOptions: spec.enumOptions,
        description: spec.description,
      );
      existingNames.add(normalizedName);
      added.add(spec.name);
    }

    return EditorCommandResult.success(
      'Colunas adicionadas em "$tableName": ${added.join(', ')}.',
    );
  }

  EditorCommandResult _handleSetPrimaryKey(
    String tableName,
    String columnName,
    SchemaState schemaState,
  ) {
    final table = schemaState.findTableByName(tableName);
    if (table == null) {
      return EditorCommandResult.failure('Tabela "$tableName" não encontrada.');
    }

    final column = schemaState.findColumnByName(table, columnName);
    if (column == null) {
      return EditorCommandResult.failure(
        'Coluna "$columnName" não encontrada em "$tableName".',
      );
    }

    if (column.isPrimaryKey) {
      return EditorCommandResult.failure(
        'A coluna "$columnName" já é PK em "$tableName".',
      );
    }

    schemaState.setPrimaryKey(table.name, column.name);
    return EditorCommandResult.success('PK definida: "$tableName"."$columnName".');
  }

  EditorCommandResult _handleAddForeignKey(
    String tableName,
    String columnName,
    String referenceTableName,
    String referenceColumnName,
    SchemaState schemaState,
  ) {
    final sourceTable = schemaState.findTableByName(tableName);
    if (sourceTable == null) {
      return EditorCommandResult.failure('Tabela "$tableName" não encontrada.');
    }

    final sourceColumn = schemaState.findColumnByName(sourceTable, columnName);
    if (sourceColumn == null) {
      return EditorCommandResult.failure(
        'Coluna "$columnName" não encontrada em "$tableName".',
      );
    }

    final targetTable = schemaState.findTableByName(referenceTableName);
    if (targetTable == null) {
      return EditorCommandResult.failure(
        'Tabela de referência "$referenceTableName" não encontrada.',
      );
    }

    final targetColumn = schemaState.findColumnByName(targetTable, referenceColumnName);
    if (targetColumn == null) {
      return EditorCommandResult.failure(
        'Coluna de referência "$referenceColumnName" não encontrada em "$referenceTableName".',
      );
    }

    if (!targetColumn.isPrimaryKey) {
      return EditorCommandResult.failure(
        'A coluna de referência "$referenceTableName"."$referenceColumnName" precisa ser PK.',
      );
    }

    final alreadyExists = sourceTable.foreignKeys.any(
      (fk) =>
          fk.columnName.toLowerCase() == sourceColumn.name.toLowerCase() &&
          fk.referenceTableName.toLowerCase() == targetTable.name.toLowerCase() &&
          fk.referenceColumnName.toLowerCase() == targetColumn.name.toLowerCase(),
    );
    if (alreadyExists) {
      return const EditorCommandResult.failure('FK já existe para essa coluna.');
    }

    schemaState.addForeignKey(
      sourceTable.name,
      sourceColumn.name,
      targetTable.name,
      targetColumn.name,
    );
    return EditorCommandResult.success(
      'FK criada: "$tableName"."$columnName" -> "$referenceTableName"."$referenceColumnName".',
    );
  }

  EditorCommandResult _handleSetDatabase(String database, SchemaState schemaState) {
    switch (database) {
      case 'postgres':
        schemaState.setDatabaseEngine(DatabaseEngine.postgres);
        break;
      case 'mysql':
        schemaState.setDatabaseEngine(DatabaseEngine.mysql);
        break;
      case 'sqlite':
        schemaState.setDatabaseEngine(DatabaseEngine.sqlite);
        break;
      default:
        return const EditorCommandResult.failure(
          'Database inválido. Use postgres, mysql ou sqlite.',
        );
    }
    return EditorCommandResult.success(
      'Database alterado para ${schemaState.databaseEngine.name}.',
    );
  }

  EditorCommandResult _handleRenameTable(
    String oldName,
    String newName,
    SchemaState schemaState,
  ) {
    final current = schemaState.findTableByName(oldName);
    if (current == null) {
      return EditorCommandResult.failure('Tabela "$oldName" não encontrada.');
    }
    if (schemaState.findTableByName(newName) != null) {
      return EditorCommandResult.failure('A tabela "$newName" já existe.');
    }

    schemaState.renameTable(current.name, newName);
    return EditorCommandResult.success('Tabela renomeada: "$oldName" -> "$newName".');
  }

  EditorCommandResult _handleRenameColumn(
    String tableName,
    String oldName,
    String newName,
    SchemaState schemaState,
  ) {
    final table = schemaState.findTableByName(tableName);
    if (table == null) {
      return EditorCommandResult.failure('Tabela "$tableName" não encontrada.');
    }
    if (schemaState.findColumnByName(table, oldName) == null) {
      return EditorCommandResult.failure(
        'Coluna "$oldName" não encontrada em "$tableName".',
      );
    }
    if (schemaState.findColumnByName(table, newName) != null) {
      return EditorCommandResult.failure(
        'A coluna "$newName" já existe em "$tableName".',
      );
    }

    schemaState.renameColumn(table.name, oldName, newName);
    return EditorCommandResult.success(
      'Coluna renomeada: "$tableName"."$oldName" -> "$newName".',
    );
  }

  EditorCommandResult _handleAlterColumnType(
    String tableName,
    String columnName,
    String newType,
    SchemaState schemaState, {
    List<String> enumOptions = const <String>[],
  }) {
    final table = schemaState.findTableByName(tableName);
    if (table == null) {
      return EditorCommandResult.failure('Tabela "$tableName" não encontrada.');
    }
    final column = schemaState.findColumnByName(table, columnName);
    if (column == null) {
      return EditorCommandResult.failure(
        'Coluna "$columnName" não encontrada em "$tableName".',
      );
    }
    if (!schemaState.isColumnTypeAllowed(newType)) {
      return _invalidTypeResult(newType, schemaState);
    }

    final isEnum = _normalizeType(newType) == 'enum';
    if (isEnum && enumOptions.isEmpty) {
      return const EditorCommandResult.failure(
        'Tipo enum exige options(v1|v2|...) no alter/change type.',
      );
    }
    if (!isEnum && enumOptions.isNotEmpty) {
      return const EditorCommandResult.failure(
        'options(...) no alter/change type só pode ser usado com enum.',
      );
    }

    schemaState.changeColumnType(
      table.name,
      column.name,
      newType,
      enumOptions: isEnum ? enumOptions : null,
    );
    return EditorCommandResult.success(
      'Tipo alterado: "$tableName"."$columnName" -> "$newType".',
    );
  }

  EditorCommandResult _invalidTypeResult(String type, SchemaState schemaState) {
    final allowed = schemaState.getAllowedTypes().toList()..sort();
    return EditorCommandResult.failure(
      'Tipo "$type" inválido para ${schemaState.databaseEngine.name}. Tipos aceitos: ${allowed.join(', ')}',
    );
  }

  _ColumnSpecsParseResult _parseColumnSpecs(String payload) {
    final chunks = _splitSpecs(payload);
    if (chunks.isEmpty) {
      return const _ColumnSpecsParseResult.failure(
        'Nenhuma coluna detectada. Exemplo: add columns <table> id int; name varchar(255)',
      );
    }

    final specs = <_ColumnInputSpec>[];
    for (final chunk in chunks) {
      final match = _columnSpecPattern.firstMatch(chunk);
      if (match == null) {
        return _ColumnSpecsParseResult.failure(
          'Formato inválido de coluna: "$chunk". Use "<coluna> <tipo> [options(...)] [description(...)]".',
        );
      }

      final optionsResult = _parseEnumOptions(match.group(3));
      if (!optionsResult.success) {
        return _ColumnSpecsParseResult.failure(optionsResult.message);
      }

      specs.add(
        _ColumnInputSpec(
          name: match.group(1)!.trim(),
          type: match.group(2)!.trim(),
          enumOptions: optionsResult.options,
          description: _cleanDescription(match.group(4)),
        ),
      );
    }

    return _ColumnSpecsParseResult.success(specs);
  }

  List<String> _splitSpecs(String payload) {
    final specs = <String>[];
    var depth = 0;
    var start = 0;

    for (var i = 0; i < payload.length; i++) {
      final char = payload[i];
      if (char == '(') {
        depth += 1;
      } else if (char == ')' && depth > 0) {
        depth -= 1;
      } else if (depth == 0 && (char == ';' || char == ',')) {
        final part = payload.substring(start, i).trim();
        if (part.isNotEmpty) specs.add(part);
        start = i + 1;
      }
    }

    final tail = payload.substring(start).trim();
    if (tail.isNotEmpty) specs.add(tail);
    return specs;
  }

  _EnumOptionsParseResult _parseEnumOptions(String? raw) {
    if (raw == null) {
      return const _EnumOptionsParseResult.success(<String>[]);
    }

    final values = raw
        .split(RegExp(r'[|,]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.isEmpty) {
      return const _EnumOptionsParseResult.failure(
        'options(...) precisa ter ao menos um valor.',
      );
    }

    final dedup = <String>{};
    for (final value in values) {
      if (!dedup.add(value.toLowerCase())) {
        return _EnumOptionsParseResult.failure(
          'Valor enum duplicado em options(...): "$value".',
        );
      }
    }
    return _EnumOptionsParseResult.success(values);
  }

  String? _cleanDescription(String? value) {
    if (value == null) return null;
    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }

  String _normalizeType(String type) {
    final normalized = type.trim().toLowerCase();
    final parenIndex = normalized.indexOf('(');
    return parenIndex == -1 ? normalized : normalized.substring(0, parenIndex);
  }

  String _buildHelpMessage(DatabaseEngine engine) {
    return 'DB atual: ${engine.name} | '
        'Comandos: create table <table> [--autoincrement] | '
        'add column <table> <column> <type> [options(v1|v2)] [description(text)] | '
        'add columns <table> <col1 type ...; col2 type ...> | '
        'add column <column> type <type> to <table> [options(v1|v2)] [description(text)] | '
        'set pk <table> <column> | '
        'add fk <table> <column> references <ref_table> <ref_column> | '
        'set database <postgres|mysql|sqlite> | show database | show types | '
        'rename table <old> to <new> | '
        'change table <old> to <new> | '
        'rename column <table> <old> to <new> | '
        'change column <table> <old> to <new> | '
        'alter column <table> <column> type <new_type> [options(v1|v2)] | '
        'change column <table> <column> type <new_type> [options(v1|v2)] | '
        'history';
  }
}

class _ColumnInputSpec {
  const _ColumnInputSpec({
    required this.name,
    required this.type,
    this.enumOptions = const <String>[],
    this.description,
  });

  final String name;
  final String type;
  final List<String> enumOptions;
  final String? description;
}

class _ColumnSpecsParseResult {
  const _ColumnSpecsParseResult.success(this.specs)
    : success = true,
      message = '';
  const _ColumnSpecsParseResult.failure(this.message)
    : success = false,
      specs = const <_ColumnInputSpec>[];

  final bool success;
  final String message;
  final List<_ColumnInputSpec> specs;
}

class _EnumOptionsParseResult {
  const _EnumOptionsParseResult.success(this.options)
    : success = true,
      message = '';
  const _EnumOptionsParseResult.failure(this.message)
    : success = false,
      options = const <String>[];

  final bool success;
  final String message;
  final List<String> options;
}

class EditorCommandResult {
  const EditorCommandResult.success(this.message) : success = true;
  const EditorCommandResult.failure(this.message) : success = false;

  final bool success;
  final String message;
}