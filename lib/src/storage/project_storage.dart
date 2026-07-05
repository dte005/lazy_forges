import 'dart:convert';
import 'dart:io';

import '../model/schema_state.dart';

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

class ProjectStorage {
  static final RegExp _projectNamePattern = RegExp(r'^[a-zA-Z0-9_-]+$');
  static const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
  static const String _workspaceFolderName = 'lazyforge_projects';

  String get _separator => Platform.pathSeparator;
  String get _projectsPath =>
      '${Directory.current.path}$_separator$_workspaceFolderName';

  List<ProjectSummary> listProjects() {
    _ensureBaseDirectories();
    final projectsDir = Directory(_projectsPath);
    final summaries = <ProjectSummary>[];

    for (final entity in projectsDir.listSync()) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.json')) continue;

      try {
        final raw = entity.readAsStringSync();
        final parsed = jsonDecode(raw);
        if (parsed is! Map<String, dynamic>) continue;

        final schema = SchemaState.fromJson(
          (parsed['schema'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        );
        final name = (parsed['name'] as String?)?.trim();
        final updatedAtRaw = parsed['updatedAt'] as String?;

        if (name == null || name.isEmpty) continue;
        final updatedAt = updatedAtRaw == null
            ? DateTime.fromMillisecondsSinceEpoch(0)
            : DateTime.tryParse(updatedAtRaw) ??
                DateTime.fromMillisecondsSinceEpoch(0);

        summaries.add(
          ProjectSummary(
            name: name,
            databaseEngine: schema.databaseEngine,
            updatedAt: updatedAt,
          ),
        );
      } catch (_) {
        // Ignora arquivos inválidos.
      }
    }

    summaries.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return summaries;
  }

  LoadedProject createProject(String projectName, DatabaseEngine engine) {
    _ensureBaseDirectories();
    final cleanName = _validateProjectName(projectName);
    final path = _projectFilePath(cleanName);
    final file = File(path);
    if (file.existsSync()) {
      throw StateError('Projeto "$cleanName" já existe.');
    }

    final schema = SchemaState()..setDatabaseEngine(engine);
    final now = DateTime.now().toUtc();
    _writeProjectFile(cleanName, schema, now);

    return LoadedProject(name: cleanName, schemaState: schema, updatedAt: now);
  }

  LoadedProject loadProject(String projectName) {
    _ensureBaseDirectories();
    final cleanName = _validateProjectName(projectName);
    final file = File(_projectFilePath(cleanName));
    if (!file.existsSync()) {
      throw StateError('Projeto "$cleanName" não encontrado.');
    }

    final raw = file.readAsStringSync();
    final parsed = jsonDecode(raw);
    if (parsed is! Map<String, dynamic>) {
      throw StateError('Projeto "$cleanName" está corrompido.');
    }

    final schema = SchemaState.fromJson(
      (parsed['schema'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final updatedAtRaw = parsed['updatedAt'] as String?;
    final updatedAt = updatedAtRaw == null
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : DateTime.tryParse(updatedAtRaw) ?? DateTime.fromMillisecondsSinceEpoch(0);

    return LoadedProject(name: cleanName, schemaState: schema, updatedAt: updatedAt);
  }

  void saveProject(String projectName, SchemaState schemaState) {
    _ensureBaseDirectories();
    final cleanName = _validateProjectName(projectName);
    final now = DateTime.now().toUtc();
    _writeProjectFile(cleanName, schemaState, now);
  }

  String exportDdl(
    String projectName,
    SchemaState schemaState, {
    String? fileName,
  }) {
    _ensureBaseDirectories();
    final cleanProjectName = _validateProjectName(projectName);
    final normalizedFileName = _normalizeSqlFileName(fileName ?? cleanProjectName);
    final outputPath = '${Directory.current.path}$_separator$normalizedFileName';
    final file = File(outputPath);
    file.writeAsStringSync(schemaState.toSqlDdl());
    return outputPath;
  }

  void _writeProjectFile(
    String projectName,
    SchemaState schemaState,
    DateTime updatedAt,
  ) {
    final payload = <String, dynamic>{
      'name': projectName,
      'updatedAt': updatedAt.toIso8601String(),
      'schema': schemaState.toJson(),
    };
    final file = File(_projectFilePath(projectName));
    file.writeAsStringSync(_encoder.convert(payload));
  }

  void _ensureBaseDirectories() {
    Directory(_projectsPath).createSync(recursive: true);
  }

  String _projectFilePath(String projectName) {
    return '$_projectsPath$_separator$projectName.json';
  }

  String _validateProjectName(String projectName) {
    final clean = projectName.trim();
    if (clean.isEmpty) {
      throw const FormatException('Nome do projeto não pode ser vazio.');
    }
    if (!_projectNamePattern.hasMatch(clean)) {
      throw const FormatException(
        'Nome inválido. Use apenas letras, números, "_" e "-".',
      );
    }
    return clean;
  }

  String _normalizeSqlFileName(String fileName) {
    final clean = fileName.trim();
    if (clean.isEmpty) {
      throw const FormatException('Nome de arquivo SQL inválido.');
    }
    final withoutExtension = clean.toLowerCase().endsWith('.sql')
        ? clean.substring(0, clean.length - 4)
        : clean;
    if (!_projectNamePattern.hasMatch(withoutExtension)) {
      throw const FormatException(
        'Nome de arquivo inválido. Use apenas letras, números, "_" e "-".',
      );
    }
    return '$withoutExtension.sql';
  }
}
