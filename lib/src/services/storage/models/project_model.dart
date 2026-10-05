import '../../../components/editor/models/schema_model.dart';
import '../../../shared/models/enums.dart';

class ProjectSummary {
  const ProjectSummary({
    required this.name,
    required this.databaseEngine,
    required this.updatedAt,
  });

  final String name;
  final DatabaseEngine databaseEngine;
  final DateTime updatedAt;
}

class LoadedProject {
  const LoadedProject({
    required this.name,
    required this.schemaState,
    required this.updatedAt,
  });

  final String name;
  final SchemaState schemaState;
  final DateTime updatedAt;
}
