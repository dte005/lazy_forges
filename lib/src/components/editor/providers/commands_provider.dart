import '../../../model/enums.dart';
import '../../../model/schema_state.dart';
import '../../../storage/project_storage.dart';
import '../models/editor_model.dart';

class CommandsProvider {
  static const String _identifier = r'([a-zA-Z_][a-zA-Z0-9_]*)';
  static const String _typeToken =
      r'([a-zA-Z_][a-zA-Z0-9_]*(?:\([0-9,\s]+\))?)';

  static final RegExp _createTablePattern = RegExp(
    '^create\\s+table\\s+$_identifier(?:\\s+(--autoincrement))?\$',
    caseSensitive: false,
  );
  static final RegExp _deleteTablePattern = RegExp(
    '^delete\\s+table\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _dropTablePattern = RegExp(
    '^drop\\s+table\\s+$_identifier\$',
    caseSensitive: false,
  );
  static final RegExp _addColumnsPattern = RegExp(
    '^add\\s+columns?\\s+$_identifier\\s+(.+)\$',
    caseSensitive: false,
  );
  static final RegExp _addColumnShortPattern = RegExp(
    '^add\\s+column\\s+$_identifier\\s+$_identifier\\s+$_typeToken(\\s+as\\s+pk)?(?:\\s+options\\(([^)]*)\\))?(?:\\s+description\\(([^)]*)\\))?\$',
    caseSensitive: false,
  );
  static final RegExp _addColumnVerbosePattern = RegExp(
    '^add\\s+column\\s+$_identifier\\s+type\\s+$_typeToken\\s+to\\s+$_identifier(\\s+as\\s+pk)?(?:\\s+options\\(([^)]*)\\))?(?:\\s+description\\(([^)]*)\\))?\$',
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
  static final RegExp _exportPattern = RegExp(
    r'^export(?:\s+([a-zA-Z0-9_-]+(?:\.sql)?))?$',
    caseSensitive: false,
  );
  static final RegExp _columnSpecPattern = RegExp(
    '^$_identifier\\s+$_typeToken(\\s+as\\s+pk)?(?:\\s+options\\(([^)]*)\\))?(?:\\s+description\\(([^)]*)\\))?\$',
    caseSensitive: false,
  );

  EditorCommandResult handle(
    String command,
    SchemaState schemaState, {
    required String projectName,
    required ProjectStorage projectStorage,
  }) {
    final lower = command.toLowerCase();

    if (lower == 'help') {
      return EditorCommandResult.success(
        _buildHelpMessage(schemaState.databaseEngine),
      );
    }

    if (lower == 'show tables') {
      if (schemaState.tables.isEmpty) {
        return const EditorCommandResult.success(
          'Nenhuma tabela criada ainda.',
        );
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

    final exportMatch = _exportPattern.firstMatch(command);
    if (exportMatch != null) {
      final fileName = exportMatch.group(1);
      try {
        final path = projectStorage.exportDdl(
          projectName,
          schemaState,
          fileName: fileName,
        );
        return EditorCommandResult.success('DDL exportado em: $path');
      } catch (error) {
        return EditorCommandResult.failure('Falha ao exportar DDL: $error');
      }
    }

    final createTableMatch = _createTablePattern.firstMatch(command);
    if (createTableMatch != null) {
      final tableName = createTableMatch.group(1)!;
      final autoIncrement = createTableMatch.group(2) != null;
      return _handleCreateTable(
        tableName,
        schemaState,
        autoIncrement: autoIncrement,
      );
    }

    final deleteTableMatch =
        _deleteTablePattern.firstMatch(command) ??
        _dropTablePattern.firstMatch(command);
    if (deleteTableMatch != null) {
      final tableName = deleteTableMatch.group(1)!;
      return _handleDeleteTable(tableName, schemaState);
    }

    final addColumnShortMatch = _addColumnShortPattern.firstMatch(command);
    if (addColumnShortMatch != null) {
      final tableName = addColumnShortMatch.group(1)!;
      final columnName = addColumnShortMatch.group(2)!;
      final type = addColumnShortMatch.group(3)!;
      final optionsResult = _parseEnumOptions(addColumnShortMatch.group(5));
      if (!optionsResult.success) {
        return EditorCommandResult.failure(optionsResult.message);
      }
      return _handleAddColumns(tableName, [
        ColumnInputSpec(
          name: columnName,
          type: type,
          asPrimaryKey: addColumnShortMatch.group(4) != null,
          enumOptions: optionsResult.options,
          description: _cleanDescription(addColumnShortMatch.group(6)),
        ),
      ], schemaState);
    }

    final addColumnVerboseMatch = _addColumnVerbosePattern.firstMatch(command);
    if (addColumnVerboseMatch != null) {
      final columnName = addColumnVerboseMatch.group(1)!;
      final type = addColumnVerboseMatch.group(2)!;
      final tableName = addColumnVerboseMatch.group(3)!;
      final optionsResult = _parseEnumOptions(addColumnVerboseMatch.group(5));
      if (!optionsResult.success) {
        return EditorCommandResult.failure(optionsResult.message);
      }
      return _handleAddColumns(tableName, [
        ColumnInputSpec(
          name: columnName,
          type: type,
          asPrimaryKey: addColumnVerboseMatch.group(4) != null,
          enumOptions: optionsResult.options,
          description: _cleanDescription(addColumnVerboseMatch.group(6)),
        ),
      ], schemaState);
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
      return const EditorCommandResult.success(
        'Tabela criada com id autoincrement.',
        shouldPersist: true,
      );
    }
    return const EditorCommandResult.success(
      'Tabela criada com sucesso.',
      shouldPersist: true,
    );
  }

  EditorCommandResult _handleDeleteTable(
    String tableName,
    SchemaState schemaState,
  ) {
    final deleted = schemaState.deleteTable(tableName);
    if (!deleted) {
      return EditorCommandResult.failure('Tabela "$tableName" não encontrada.');
    }
    return const EditorCommandResult.success(
      'Tabela removida com sucesso.',
      shouldPersist: true,
    );
  }

  void _addAutoIncrementId(String tableName, SchemaState schemaState) {
    final idType = switch (schemaState.databaseEngine) {
      DatabaseEngine.postgres => 'serial',
      DatabaseEngine.mysql => 'int',
      DatabaseEngine.sqlite => 'integer',
    };
    schemaState.addColumn(
      tableName,
      'id',
      idType,
      description: 'auto increment',
    );
    schemaState.setPrimaryKey(tableName, 'id');
  }

  EditorCommandResult _handleAddColumns(
    String tableName,
    List<ColumnInputSpec> specs,
    SchemaState schemaState,
  ) {
    final table = schemaState.findTableByName(tableName);
    if (table == null) {
      return EditorCommandResult.failure('Tabela "$tableName" não encontrada.');
    }

    final existingNames = table.columns
        .map((c) => c.name.toLowerCase())
        .toSet();
    final batchNames = <String>{};
    final added = <String>[];

    for (final spec in specs) {
      final normalizedName = spec.name.toLowerCase();
      if (existingNames.contains(normalizedName) ||
          batchNames.contains(normalizedName)) {
        return EditorCommandResult.failure(
          'A coluna "${spec.name}" já existe em "$tableName".',
        );
      }
      batchNames.add(normalizedName);

      final normalizedType = _normalizeInputType(spec.type);
      if (!schemaState.isColumnTypeAllowed(normalizedType)) {
        return _invalidTypeResult(normalizedType, schemaState);
      }

      final isEnum = _normalizeType(normalizedType) == 'enum';
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
        normalizedType,
        enumOptions: spec.enumOptions,
        description: spec.description,
      );
      if (spec.asPrimaryKey) {
        schemaState.setPrimaryKey(table.name, spec.name);
      }

      existingNames.add(normalizedName);
      added.add(spec.name);
    }

    return EditorCommandResult.success(
      'Colunas adicionadas em "$tableName": ${added.join(', ')}.',
      shouldPersist: true,
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
    return const EditorCommandResult.success(
      'PK definida com sucesso.',
      shouldPersist: true,
    );
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

    final targetColumn = schemaState.findColumnByName(
      targetTable,
      referenceColumnName,
    );
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
          fk.referenceTableName.toLowerCase() ==
              targetTable.name.toLowerCase() &&
          fk.referenceColumnName.toLowerCase() ==
              targetColumn.name.toLowerCase(),
    );
    if (alreadyExists) {
      return const EditorCommandResult.failure(
        'FK já existe para essa coluna.',
      );
    }

    schemaState.addForeignKey(
      sourceTable.name,
      sourceColumn.name,
      targetTable.name,
      targetColumn.name,
    );
    return const EditorCommandResult.success(
      'FK criada com sucesso.',
      shouldPersist: true,
    );
  }

  EditorCommandResult _handleSetDatabase(
    String database,
    SchemaState schemaState,
  ) {
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
      shouldPersist: true,
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
    return const EditorCommandResult.success(
      'Tabela renomeada com sucesso.',
      shouldPersist: true,
    );
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
    return const EditorCommandResult.success(
      'Coluna renomeada com sucesso.',
      shouldPersist: true,
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

    final normalizedType = _normalizeInputType(newType);
    if (!schemaState.isColumnTypeAllowed(normalizedType)) {
      return _invalidTypeResult(normalizedType, schemaState);
    }

    final isEnum = _normalizeType(normalizedType) == 'enum';
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
      normalizedType,
      enumOptions: isEnum ? enumOptions : null,
    );
    return const EditorCommandResult.success(
      'Tipo de coluna alterado com sucesso.',
      shouldPersist: true,
    );
  }

  EditorCommandResult _invalidTypeResult(String type, SchemaState schemaState) {
    final allowed = schemaState.getAllowedTypes().toList()..sort();
    return EditorCommandResult.failure(
      'Tipo "$type" inválido para ${schemaState.databaseEngine.name}. Tipos aceitos: ${allowed.join(', ')}',
    );
  }

  ColumnSpecsParseResult _parseColumnSpecs(String payload) {
    final chunks = _splitSpecs(payload);
    if (chunks.isEmpty) {
      return const ColumnSpecsParseResult.failure(
        'Nenhuma coluna detectada. Exemplo: add columns <table> id int; name varchar(255)',
      );
    }

    final specs = <ColumnInputSpec>[];
    for (final chunk in chunks) {
      final match = _columnSpecPattern.firstMatch(chunk);
      if (match == null) {
        return ColumnSpecsParseResult.failure(
          'Formato inválido de coluna: "$chunk". Use "<coluna> <tipo> [as pk] [options(...)] [description(...)]".',
        );
      }

      final optionsResult = _parseEnumOptions(match.group(4));
      if (!optionsResult.success) {
        return ColumnSpecsParseResult.failure(optionsResult.message);
      }

      specs.add(
        ColumnInputSpec(
          name: match.group(1)!.trim(),
          type: match.group(2)!.trim(),
          asPrimaryKey: match.group(3) != null,
          enumOptions: optionsResult.options,
          description: _cleanDescription(match.group(5)),
        ),
      );
    }

    return ColumnSpecsParseResult.success(specs);
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
        if (part.isNotEmpty) {
          specs.add(part);
        }
        start = i + 1;
      }
    }

    final tail = payload.substring(start).trim();
    if (tail.isNotEmpty) {
      specs.add(tail);
    }
    return specs;
  }

  EnumOptionsParseResult _parseEnumOptions(String? raw) {
    if (raw == null) {
      return const EnumOptionsParseResult.success(<String>[]);
    }

    final values = raw
        .split(RegExp(r'[|,]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (values.isEmpty) {
      return const EnumOptionsParseResult.failure(
        'options(...) precisa ter ao menos um valor.',
      );
    }

    final dedup = <String>{};
    for (final value in values) {
      if (!dedup.add(value.toLowerCase())) {
        return EnumOptionsParseResult.failure(
          'Valor enum duplicado em options(...): "$value".',
        );
      }
    }
    return EnumOptionsParseResult.success(values);
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

  String _normalizeInputType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized == 'string') {
      return 'text';
    }
    return type.trim();
  }

  String _buildHelpMessage(DatabaseEngine engine) {
    return 'DB atual: ${engine.name} | '
        'Comandos: create table <table> [--autoincrement] | '
        'delete table <table> | drop table <table> | '
        'create table <table> - add column <table> id string as pk; name string | '
        'add column <table> <column> <type> [as pk] [options(v1|v2)] [description(text)] | '
        'add columns <table> <col1 type [as pk] ...; col2 type ...> | '
        'add column <column> type <type> to <table> [as pk] [options(v1|v2)] [description(text)] | '
        'set pk <table> <column> | '
        'add fk <table> <column> references <ref_table> <refColumn> | '
        'set database <postgres|mysql|sqlite> | show database | show types | show tables | '
        'rename table <old> to <new> | '
        'change table <old> to <new> | '
        'rename column <table> <old> to <new> | '
        'change column <table> <old> to <new> | '
        'alter column <table> <column> type <new_type> [options(v1|v2)] | '
        'change column <table> <column> type <new_type> [options(v1|v2)] | '
        'export [nome_arquivo.sql] | history';
  }
}
