enum Screen { init, editor }

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
