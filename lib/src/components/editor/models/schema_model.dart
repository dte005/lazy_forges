import '../../../shared/models/enums.dart';

class ColumnDef {
  String name;
  String type;
  bool isPrimaryKey;
  List<String> enumOptions;
  String? description;

  ColumnDef({
    required this.name,
    required this.type,
    this.isPrimaryKey = false,
    List<String>? enumOptions,
    this.description,
  }) : enumOptions = enumOptions ?? <String>[];

  factory ColumnDef.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['enumOptions'];
    final options = rawOptions is List
        ? rawOptions.map((e) => e.toString()).toList()
        : <String>[];
    return ColumnDef(
      name: (json['name'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'text',
      isPrimaryKey: (json['isPrimaryKey'] as bool?) ?? false,
      enumOptions: options,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'type': type,
      'isPrimaryKey': isPrimaryKey,
      'enumOptions': enumOptions,
      'description': description,
    };
  }
}

class ForeignKeyDef {
  String columnName;
  String referenceTableName;
  String referenceColumnName;

  ForeignKeyDef({
    required this.columnName,
    required this.referenceTableName,
    required this.referenceColumnName,
  });

  factory ForeignKeyDef.fromJson(Map<String, dynamic> json) {
    return ForeignKeyDef(
      columnName: (json['columnName'] as String?) ?? '',
      referenceTableName: (json['referenceTableName'] as String?) ?? '',
      referenceColumnName: (json['referenceColumnName'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'columnName': columnName,
      'referenceTableName': referenceTableName,
      'referenceColumnName': referenceColumnName,
    };
  }
}

/// Estado central: a lista de tabelas que existem no schema em memória.
class SchemaState {
  final List<TableDef> tables = [];
  DatabaseEngine databaseEngine = DatabaseEngine.postgres;
  SchemaState();

  static const Map<DatabaseEngine, Set<String>> _allowedTypesByEngine = {
    DatabaseEngine.postgres: {
      'smallint',
      'integer',
      'bigint',
      'serial',
      'bigserial',
      'numeric',
      'decimal',
      'real',
      'double',
      'boolean',
      'char',
      'varchar',
      'text',
      'date',
      'time',
      'timestamp',
      'timestamptz',
      'uuid',
      'json',
      'jsonb',
      'bytea',
      'enum',
    },
    DatabaseEngine.mysql: {
      'tinyint',
      'smallint',
      'mediumint',
      'int',
      'bigint',
      'decimal',
      'float',
      'double',
      'bit',
      'char',
      'varchar',
      'text',
      'tinytext',
      'mediumtext',
      'longtext',
      'date',
      'time',
      'datetime',
      'timestamp',
      'year',
      'json',
      'binary',
      'varbinary',
      'blob',
      'tinyblob',
      'mediumblob',
      'longblob',
      'boolean',
      'enum',
    },
    DatabaseEngine.sqlite: {
      'integer',
      'real',
      'text',
      'blob',
      'numeric',
      'boolean',
      'date',
      'datetime',
    },
  };

  factory SchemaState.fromJson(Map<String, dynamic> json) {
    final state = SchemaState();
    state.databaseEngine = DatabaseEngine.fromString(
      json['databaseEngine'] as String,
    );

    final rawTables = json['tables'];
    if (rawTables is List) {
      for (final rawTable in rawTables) {
        if (rawTable is Map<String, dynamic>) {
          state.tables.add(TableDef.fromJson(rawTable));
        } else if (rawTable is Map) {
          state.tables.add(TableDef.fromJson(rawTable.cast<String, dynamic>()));
        }
      }
    }
    return state;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'databaseEngine': databaseEngine.name,
      'tables': tables.map((t) => t.toJson()).toList(),
    };
  }

  void setDatabaseEngine(DatabaseEngine engine) {
    databaseEngine = engine;
  }

  Set<String> getAllowedTypes() {
    return _allowedTypesByEngine[databaseEngine] ?? const <String>{};
  }

  bool isColumnTypeAllowed(String type) {
    final normalized = type.trim().toLowerCase();
    final parenIndex = normalized.indexOf('(');
    final baseType = parenIndex == -1
        ? normalized
        : normalized.substring(0, parenIndex).trim();
    return getAllowedTypes().contains(baseType);
  }

  void addTable(String name) {
    tables.add(TableDef(name: name));
  }

  bool deleteTable(String tableName) {
    final target = findTableByName(tableName);
    if (target == null) return false;

    tables.remove(target);
    for (final table in tables) {
      table.foreignKeys.removeWhere(
        (fk) =>
            fk.referenceTableName.toLowerCase() == target.name.toLowerCase(),
      );
    }
    return true;
  }

  void addColumn(
    String tableName,
    String columnName,
    String type, {
    List<String>? enumOptions,
    String? description,
  }) {
    final table = findTableByName(tableName);
    if (table == null) return;
    table.columns.add(
      ColumnDef(
        name: columnName,
        type: type,
        enumOptions: enumOptions,
        description: description,
      ),
    );
  }

  void setPrimaryKey(String tableName, String columnName) {
    final table = findTableByName(tableName);
    if (table == null) return;

    final column = findColumnByName(table, columnName);
    if (column == null) return;
    column.isPrimaryKey = true;
  }

  void addForeignKey(
    String tableName,
    String columnName,
    String referenceTableName,
    String referenceColumnName,
  ) {
    final table = findTableByName(tableName);
    if (table == null) return;

    table.foreignKeys.add(
      ForeignKeyDef(
        columnName: columnName,
        referenceTableName: referenceTableName,
        referenceColumnName: referenceColumnName,
      ),
    );
  }

  TableDef? findTableByName(String tableName) {
    for (final table in tables) {
      if (table.name.toLowerCase() == tableName.toLowerCase()) return table;
    }
    return null;
  }

  ColumnDef? findColumnByName(TableDef table, String columnName) {
    for (final column in table.columns) {
      if (column.name.toLowerCase() == columnName.toLowerCase()) return column;
    }
    return null;
  }

  bool renameTable(String currentName, String newName) {
    final table = findTableByName(currentName);
    if (table == null) return false;

    table.name = newName;
    for (final current in tables) {
      for (final fk in current.foreignKeys) {
        if (fk.referenceTableName.toLowerCase() == currentName.toLowerCase()) {
          fk.referenceTableName = newName;
        }
      }
    }
    return true;
  }

  bool renameColumn(String tableName, String currentName, String newName) {
    final table = findTableByName(tableName);
    if (table == null) return false;

    final column = findColumnByName(table, currentName);
    if (column == null) return false;

    column.name = newName;

    for (final fk in table.foreignKeys) {
      if (fk.columnName.toLowerCase() == currentName.toLowerCase()) {
        fk.columnName = newName;
      }
    }

    for (final current in tables) {
      for (final fk in current.foreignKeys) {
        final sameTable =
            fk.referenceTableName.toLowerCase() == table.name.toLowerCase();
        final sameColumn =
            fk.referenceColumnName.toLowerCase() == currentName.toLowerCase();
        if (sameTable && sameColumn) {
          fk.referenceColumnName = newName;
        }
      }
    }

    return true;
  }

  bool changeColumnType(
    String tableName,
    String columnName,
    String newType, {
    List<String>? enumOptions,
  }) {
    final table = findTableByName(tableName);
    if (table == null) return false;

    final column = findColumnByName(table, columnName);
    if (column == null) return false;

    column.type = newType;
    if (enumOptions != null) {
      column.enumOptions = List<String>.from(enumOptions);
    } else if (_normalizeType(newType) != 'enum') {
      column.enumOptions = <String>[];
    }
    return true;
  }

  bool setColumnDescription(
    String tableName,
    String columnName,
    String? description,
  ) {
    final table = findTableByName(tableName);
    if (table == null) return false;

    final column = findColumnByName(table, columnName);
    if (column == null) return false;

    final clean = description?.trim();
    column.description = (clean == null || clean.isEmpty) ? null : clean;
    return true;
  }

  String toSqlDdl() {
    final buffer = StringBuffer();
    buffer.writeln('-- LazyForge SQL DDL');
    buffer.writeln('-- Database: ${databaseEngine.name}');
    buffer.writeln('');

    for (final table in tables) {
      buffer.writeln('CREATE TABLE ${table.name} (');
      final items = <String>[];

      for (final column in table.columns) {
        if (column.description != null &&
            column.description!.trim().isNotEmpty) {
          items.add('  -- ${column.name}: ${column.description!.trim()}');
        }
        items.add('  ${_buildColumnSql(column)}');
      }

      for (final fk in table.foreignKeys) {
        items.add(
          '  FOREIGN KEY (${fk.columnName}) REFERENCES ${fk.referenceTableName}(${fk.referenceColumnName})',
        );
      }

      for (var i = 0; i < items.length; i++) {
        final suffix = i == items.length - 1 ? '' : ',';
        buffer.writeln('${items[i]}$suffix');
      }
      buffer.writeln(');');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  String _buildColumnSql(ColumnDef column) {
    final baseType = _normalizeType(column.type);
    final typeSql = baseType == 'enum' ? 'TEXT' : column.type.toUpperCase();
    final parts = <String>['${column.name} $typeSql'];

    if (baseType == 'enum' && column.enumOptions.isNotEmpty) {
      final values = column.enumOptions
          .map((value) => "'${_escapeSql(value)}'")
          .join(', ');
      parts.add('CHECK (${column.name} IN ($values))');
    }

    if (column.isPrimaryKey) {
      parts.add('PRIMARY KEY');
    }

    return parts.join(' ');
  }

  String _normalizeType(String type) {
    final normalized = type.trim().toLowerCase();
    final parenIndex = normalized.indexOf('(');
    return parenIndex == -1 ? normalized : normalized.substring(0, parenIndex);
  }

  String _escapeSql(String value) {
    return value.replaceAll("'", "''");
  }
}

/// Representa uma tabela, com nome e lista de colunas.
class TableDef {
  String name;
  final List<ColumnDef> columns;
  final List<ForeignKeyDef> foreignKeys;

  TableDef({
    required this.name,
    List<ColumnDef>? columns,
    List<ForeignKeyDef>? foreignKeys,
  }) : columns = columns ?? [],
       foreignKeys = foreignKeys ?? [];

  factory TableDef.fromJson(Map<String, dynamic> json) {
    final rawColumns = json['columns'];
    final parsedColumns = <ColumnDef>[];
    if (rawColumns is List) {
      for (final raw in rawColumns) {
        if (raw is Map<String, dynamic>) {
          parsedColumns.add(ColumnDef.fromJson(raw));
        } else if (raw is Map) {
          parsedColumns.add(ColumnDef.fromJson(raw.cast<String, dynamic>()));
        }
      }
    }

    final rawForeignKeys = json['foreignKeys'];
    final parsedForeignKeys = <ForeignKeyDef>[];
    if (rawForeignKeys is List) {
      for (final raw in rawForeignKeys) {
        if (raw is Map<String, dynamic>) {
          parsedForeignKeys.add(ForeignKeyDef.fromJson(raw));
        } else if (raw is Map) {
          parsedForeignKeys.add(
            ForeignKeyDef.fromJson(raw.cast<String, dynamic>()),
          );
        }
      }
    }

    return TableDef(
      name: (json['name'] as String?) ?? '',
      columns: parsedColumns,
      foreignKeys: parsedForeignKeys,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'columns': columns.map((c) => c.toJson()).toList(),
      'foreignKeys': foreignKeys.map((f) => f.toJson()).toList(),
    };
  }
}
