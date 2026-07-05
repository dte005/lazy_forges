import 'package:lazy_forge/src/components/editor/editor_component.dart';
import 'package:lazy_forge/src/components/init/init_component.dart';
import 'package:nocterm/nocterm.dart';
import './model/enums.dart';

class LazyForgeApp extends StatefulComponent {
  const LazyForgeApp({super.key});

  State<LazyForgeApp> createState() => _LazyForgeApp();
}

class _LazyForgeApp extends State<LazyForgeApp> {
  Screen _screen = Screen.init;
  String? _selectedScreen;

  void _openProject(String projectName) {
    setState(() {
      _selectedScreen = projectName;
      _screen = Screen.editor;
    });
  }

  @override
  Component build(BuildContext context) {
    switch (_screen) {
      case Screen.init:
        return InitComponent(onSelect: _openProject);
      case Screen.editor:
        return EditorComponent();
      case _:
        return InitComponent(onSelect: _openProject);
    }
  }
}
