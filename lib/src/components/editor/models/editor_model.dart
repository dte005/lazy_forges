class ColumnInputSpec {
  const ColumnInputSpec({
    required this.name,
    required this.type,
    this.asPrimaryKey = false,
    this.enumOptions = const <String>[],
    this.description,
  });

  final String name;
  final String type;
  final bool asPrimaryKey;
  final List<String> enumOptions;
  final String? description;
}

class ColumnSpecsParseResult {
  const ColumnSpecsParseResult.success(this.specs)
    : success = true,
      message = '';
  const ColumnSpecsParseResult.failure(this.message)
    : success = false,
      specs = const <ColumnInputSpec>[];

  final bool success;
  final String message;
  final List<ColumnInputSpec> specs;
}
