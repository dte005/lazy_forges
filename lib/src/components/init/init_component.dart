import 'package:nocterm/nocterm.dart';

class InitComponent extends StatefulComponent {
  final void Function(String projectName) onSelect;
  const InitComponent({super.key, required this.onSelect});

  @override
  State<InitComponent> createState() => _InitComponent();
}

class _InitComponent extends State<InitComponent> {
  final List<String> _projects = ['ella_backend', 'alpar_api'];
  int _selectedProject = 0;

  List<Component> _buildProject() {
    final items = <Component>[];
    for (var i = 0; i < _projects.length; i++) {
      final isSelcted = i == _selectedProject;
      final prefix = isSelcted ? '▸ ' : ' ';
      items.add(Text('$prefix${_projects[i]}'));
    }
    return items;
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        setState(() {
          if (event.logicalKey == LogicalKey.arrowDown) {
            _selectedProject = (_selectedProject + 1) % _projects.length;
          } else if (event.logicalKey == LogicalKey.arrowUp) {
            _selectedProject =
                (_selectedProject - 1 + _projects.length) % _projects.length;
          } else if (event.logicalKey == LogicalKey.enter) {
            component.onSelect(_projects[_selectedProject]);
          }
        });
        return true;
      },
      child: Column(
        children: [
          const Text('LazyForge - Selecione um projeto'),
          Text(''),
          ..._buildProject(),
        ],
      ),
    );
  }
}
