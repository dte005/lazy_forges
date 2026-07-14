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
