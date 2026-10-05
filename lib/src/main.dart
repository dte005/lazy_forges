import 'package:lazy_forge/src/components/editor/editor_component.dart';
import 'package:lazy_forge/src/components/init/components/init_component.dart';
import 'package:lazy_forge/src/services/storage/models/project_model.dart';
import 'package:lazy_forge/src/services/storage/project_storage.dart';
import 'package:nocterm/nocterm.dart';

import './shared/models/enums.dart';

class LazyForgeApp extends StatefulComponent {
  const LazyForgeApp({super.key});
  @override
  State<LazyForgeApp> createState() => _LazyForgeApp();
}

class _LazyForgeApp extends State<LazyForgeApp> {
  Screen _screen = Screen.init;
  final ProjectStorage _projectStorage = ProjectStorage();
  LoadedProject? _activeProject;

  void _openProject(LoadedProject project) {
    setState(() {
      _activeProject = project;
      _screen = Screen.editor;
    });
  }

  @override
  Component build(BuildContext context) {
    switch (_screen) {
      case Screen.init:
        return InitComponent(
          onSelect: _openProject,
          projectStorage: _projectStorage,
        );
      case Screen.editor:
        if (_activeProject == null) {
          return InitComponent(
            onSelect: _openProject,
            projectStorage: _projectStorage,
          );
        }
        return EditorComponent(
          projectName: _activeProject!.name,
          initialSchema: _activeProject!.schemaState,
          projectStorage: _projectStorage,
        );
    }
  }
}
