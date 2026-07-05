enum DatabaseEngine { postgres, mysql, sqlite }
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
}

/// Estado central: a lista de tabelas que existem no schema em memória.
class SchemaState {
  final List<TableDef> tables = [];
  DatabaseEngine databaseEngine = DatabaseEngine.postgres;

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
    } else if (newType.toLowerCase() != 'enum') {
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
}
