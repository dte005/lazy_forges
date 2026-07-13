enum Screen { init, editor }

enum DatabaseEngine {
  postgres('postgres'),
  mysql('mysql'),
  sqlite('sqlite');

  const DatabaseEngine(this.label);

  final String label;

  static DatabaseEngine fromString(String? value) {
    final normalized = value?.trim().toLowerCase();
    return DatabaseEngine.values.firstWhere(
      (e) => e.label == normalized,
      orElse: () => DatabaseEngine.postgres,
    );
  }
}

class EnumOptionsParseResult {
  const EnumOptionsParseResult.success(this.options)
    : success = true,
      message = '';
  const EnumOptionsParseResult.failure(this.message)
    : success = false,
      options = const <String>[];

  final bool success;
  final String message;
  final List<String> options;
}

class EditorCommandResult {
  const EditorCommandResult.success(this.message, {this.shouldPersist = false})
    : success = true;
  const EditorCommandResult.failure(this.message)
    : success = false,
      shouldPersist = false;

  final bool success;
  final String message;
  final bool shouldPersist;
}
