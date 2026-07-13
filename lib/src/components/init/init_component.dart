import 'dart:io';

import 'package:nocterm/nocterm.dart';

import '../../shared/models/enums.dart';
import '../storage/project_storage.dart';

class InitComponent extends StatefulComponent {
  const InitComponent({
    super.key,
    required this.onSelect,
    required this.projectStorage,
  });

  final void Function(LoadedProject project) onSelect;
  final ProjectStorage projectStorage;

  @override
  State<InitComponent> createState() => _InitComponent();
}

class _InitComponent extends State<InitComponent> {
  final TextEditingController _projectNameController = TextEditingController();
  final List<DatabaseEngine> _engines = DatabaseEngine.values;
  final List<String> _lazyArt = const [
    '██╗      █████╗ ███████╗██╗   ██╗',
    '██║     ██╔══██╗╚══███╔╝╚██╗ ██╔╝',
    '██║     ███████║  ███╔╝  ╚████╔╝ ',
    '██║     ██╔══██║ ███╔╝    ╚██╔╝  ',
    '███████╗██║  ██║███████╗   ██║   ',
    '╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ',
  ];
  final List<String> _forgeArt = const [
    '███████╗ ██████╗ ██████╗  ██████╗ ███████╗',
    '██╔════╝██╔═══██╗██╔══██╗██╔════╝ ██╔════╝',
    '█████╗  ██║   ██║██████╔╝██║  ███╗█████╗  ',
    '██╔══╝  ██║   ██║██╔══██╗██║   ██║██╔══╝  ',
    '██║     ╚██████╔╝██║  ██║╚██████╔╝███████╗',
    '╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝',
  ];

  List<ProjectSummary> _projects = [];
  int _selectedProject = 0;
  int _selectedEngine = 0;
  bool _isCreating = false;
  bool _isPickingDatabase = false;
  String? _pendingProjectName;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _reloadProjects();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    super.dispose();
  }

  void _reloadProjects() {
    setState(() {
      _projects = component.projectStorage.listProjects();
      if (_projects.isEmpty) {
        _selectedProject = 0;
      } else if (_selectedProject >= _projects.length) {
        _selectedProject = _projects.length - 1;
      }
      _feedback = _projects.isEmpty
          ? 'Nenhum projeto salvo ainda. Pressione N para criar.'
          : 'Escolha um projeto e pressione Enter.';
    });
  }

  void _openSelectedProject() {
    if (_projects.isEmpty) {
      setState(() {
        _feedback = 'Nenhum projeto salvo. Pressione N para criar.';
      });
      return;
    }

    final selected = _projects[_selectedProject];
    try {
      final loaded = component.projectStorage.loadProject(selected.name);
      component.onSelect(loaded);
    } catch (error) {
      setState(() {
        _feedback = 'Falha ao abrir projeto: $error';
      });
    }
  }

  void _startCreateFlow() {
    setState(() {
      _isCreating = true;
      _isPickingDatabase = false;
      _pendingProjectName = null;
      _selectedEngine = 0;
      _projectNameController.clear();
      _feedback = 'Digite o nome do projeto e pressione Enter.';
    });
  }

  void _cancelCreateFlow() {
    setState(() {
      _isCreating = false;
      _isPickingDatabase = false;
      _pendingProjectName = null;
      _feedback = 'Criação cancelada.';
    });
  }

  void _submitProjectName() {
    final name = _projectNameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _feedback = 'Informe um nome para o projeto.';
      });
      return;
    }

    setState(() {
      _pendingProjectName = name;
      _isPickingDatabase = true;
      _feedback = 'Escolha o banco na janela e pressione Enter.';
    });
  }

  void _createProject() {
    final name = _pendingProjectName?.trim();
    if (name == null || name.isEmpty) {
      setState(() {
        _feedback = 'Informe um nome para o projeto.';
      });
      return;
    }

    final engine = _engines[_selectedEngine];
    try {
      final created = component.projectStorage.createProject(name, engine);
      setState(() {
        _isCreating = false;
        _isPickingDatabase = false;
        _pendingProjectName = null;
        _feedback = 'Projeto "$name" criado com sucesso.';
      });
      _reloadProjects();
      component.onSelect(created);
    } catch (error) {
      setState(() {
        _feedback = 'Falha ao criar projeto: $error';
      });
    }
  }

  bool _handleBrowseKeyEvent(KeyboardEvent event) {
    if (_isPickingDatabase) {
      if (event.logicalKey == LogicalKey.arrowUp ||
          event.logicalKey == LogicalKey.arrowLeft) {
        setState(() {
          _selectedEngine =
              (_selectedEngine - 1 + _engines.length) % _engines.length;
        });
        return true;
      }

      if (event.logicalKey == LogicalKey.arrowDown ||
          event.logicalKey == LogicalKey.arrowRight) {
        setState(() {
          _selectedEngine = (_selectedEngine + 1) % _engines.length;
        });
        return true;
      }

      if (event.logicalKey == LogicalKey.enter) {
        _createProject();
        return true;
      }

      if (event.logicalKey == LogicalKey.escape) {
        setState(() {
          _isPickingDatabase = false;
          _feedback = 'Seleção de banco cancelada.';
        });
        return true;
      }
      return false;
    }

    if (_isCreating) return false;
    if (event.logicalKey == LogicalKey.escape) {
      exit(0);
    }

    if (event.logicalKey == LogicalKey.arrowDown) {
      if (_projects.isNotEmpty) {
        setState(() {
          _selectedProject = (_selectedProject + 1) % _projects.length;
        });
      }
      return true;
    }

    if (event.logicalKey == LogicalKey.arrowUp) {
      if (_projects.isNotEmpty) {
        setState(() {
          _selectedProject =
              (_selectedProject - 1 + _projects.length) % _projects.length;
        });
      }
      return true;
    }

    if (event.logicalKey == LogicalKey.enter) {
      _openSelectedProject();
      return true;
    }

    if (event.logicalKey == LogicalKey.keyN) {
      _startCreateFlow();
      return true;
    }

    if (event.logicalKey == LogicalKey.keyR) {
      _reloadProjects();
      return true;
    }

    return false;
  }

  bool _handleCreateKeyEvent(KeyboardEvent event) {
    if (event.logicalKey == LogicalKey.escape) {
      _cancelCreateFlow();
      return true;
    }
    return false;
  }

  List<Component> _buildProjectList() {
    if (_projects.isEmpty) {
      return const [Text('  (sem projetos salvos)')];
    }

    final items = <Component>[];
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final prefix = i == _selectedProject ? '> ' : '  ';
      items.add(
        Text('$prefix${project.name} [${project.databaseEngine.name}]'),
      );
    }
    return items;
  }

  List<Component> _buildBanner() {
    final items = <Component>[];
    for (final line in _lazyArt) {
      items.add(Text('  $line', style: const TextStyle(color: Colors.cyan)));
    }
    for (final line in _forgeArt) {
      items.add(Text('  $line', style: const TextStyle(color: Colors.yellow)));
    }
    items.add(const Text(''));
    items.add(
      const Text(
        '  forge database schemas without leaving your terminal',
        style: TextStyle(color: Colors.brightBlack),
      ),
    );
    items.add(
      const Text(
        '  v0.1.0 · lazy by design',
        style: TextStyle(color: Colors.brightYellow),
      ),
    );
    items.add(const Divider(style: DividerStyle.single));
    return items;
  }

  Component _buildCreatePanel() {
    if (_isPickingDatabase) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Novo projeto'),
          const Divider(style: DividerStyle.single),
          Text('Nome: ${_pendingProjectName ?? ''}'),
          const Text('Escolha o banco na janela de seleção.'),
          const Text('Esc: cancelar seleção de banco'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Novo projeto'),
        const Divider(style: DividerStyle.single),
        TextField(
          controller: _projectNameController,
          focused: true,
          placeholder: 'nome_do_projeto',
          onKeyEvent: _handleCreateKeyEvent,
          onSubmitted: (_) => _submitProjectName(),
          decoration: InputDecoration(
            border: BoxBorder.all(style: BoxBorderStyle.double),
            focusedBorder: BoxBorder.all(
              color: Colors.cyan,
              style: BoxBorderStyle.double,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 1),
          ),
        ),
        const Text('Enter: avançar para escolha de banco | Esc: cancelar'),
      ],
    );
  }

  Component _buildDatabasePickerWindow() {
    final options = <Component>[];
    for (var i = 0; i < _engines.length; i++) {
      final selected = i == _selectedEngine;
      final prefix = selected ? '> ' : '  ';
      options.add(
        Text(
          '$prefix${_engines[i].name}',
          style: TextStyle(
            color: selected ? Colors.brightCyan : Colors.white,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return Container(
      width: 42,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.brightBlack,
        border: BoxBorder.all(style: BoxBorderStyle.double),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selecionar banco',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
          ),
          const Divider(style: DividerStyle.single),
          Text('Projeto: ${_pendingProjectName ?? ''}'),
          const Divider(style: DividerStyle.single),
          ...options,
          const Divider(style: DividerStyle.single),
          const Text('↑/↓ ou ←/→: mudar | Enter: confirmar | Esc: cancelar'),
        ],
      ),
    );
  }

  Component _buildBrowsePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Projetos salvos'),
        const Divider(style: DividerStyle.single),
        ..._buildProjectList(),
        const Divider(style: DividerStyle.single),
        const Text(
          '↑/↓: selecionar | Enter: abrir | N: novo projeto | R: recarregar',
        ),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: !_isCreating || _isPickingDatabase,
      onKeyEvent: _handleBrowseKeyEvent,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildBanner(),
                if (_isCreating) _buildCreatePanel() else _buildBrowsePanel(),
                const Divider(style: DividerStyle.single),
                Text(
                  _feedback,
                  style: TextStyle(
                    color: _feedback.toLowerCase().contains('falha')
                        ? Colors.red
                        : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          if (_isPickingDatabase)
            Positioned(left: 8, top: 14, child: _buildDatabasePickerWindow()),
        ],
      ),
    );
  }
}
