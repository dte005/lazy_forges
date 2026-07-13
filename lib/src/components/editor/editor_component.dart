import 'dart:async';
import 'dart:io';

import 'package:nocterm/nocterm.dart';

import '../../services/clipboard_service.dart';
import '../storage/project_storage.dart';
import './components/sidebar/sidebar_component.dart';
import './components/table/table_component.dart';
import './components/vertical_divider/vertical_divider_component.dart';
import 'models/schema_model.dart';
import 'providers/editor_provider.dart';

class EditorComponent extends StatefulComponent {
  const EditorComponent({
    super.key,
    required this.projectName,
    required this.initialSchema,
    required this.projectStorage,
  });
  final String projectName;
  final SchemaState initialSchema;
  final ProjectStorage projectStorage;

  @override
  State<EditorComponent> createState() => _EditorComponent();
}

class _EditorComponent extends State<EditorComponent> {
  late final EditorProvider _editorProvider;
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _editorVerticalController = ScrollController();
  final ScrollController _editorHorizontalController = ScrollController();
  final ScrollController _sidebarVerticalController = ScrollController();
  bool _isHelpOpen = false;
  bool _isDbTypesOpen = false;
  int _historyCursor = -1;
  String _historyDraft = '';
  StreamSubscription<ProcessSignal>? _sigintSubscription;
  String _copyFeedback = '';
  bool _copyFeedbackIsError = false;

  static const List<String> _helpCommandTemplates = [
    'create table <table>',
    'delete table <table>',
    'create table <table> - add column <table> id string as pk; name string;',
    'create table <table> --autoincrement',
    'add column <table> <column> <type> as pk',
    'add column <table> <column> enum options(v1|v2|v3)',
    'add column <table> <column> <type> description(descricao opcional)',
    'add columns <table> <coluna1> <tipo1> as pk; <coluna2> <tipo2>',
    'add column <column> type <type> to <table>',
    'rename table <old_table> to <new_table>',
    'rename column <table> <old_column> to <new_column>',
    'alter column <table> <column> type <new_type>',
    'alter column <table> <column> type enum options(v1|v2)',
    'set pk <table> <column>',
    'add fk <table> <column> references <ref_table> <ref_column>',
    'set database <postgres|mysql|sqlite>',
    'show database',
    'show types',
    'show tables',
    'export',
    'history',
  ];

  @override
  void initState() {
    super.initState();
    _editorProvider = EditorProvider(
      schemaState: component.initialSchema,
      projectName: component.projectName,
      projectStorage: component.projectStorage,
    );
    _sigintSubscription = ProcessSignal.sigint.watch().listen((_) {
      _copyInputToClipboard();
    });
  }

  Component _buildDbTypesWindow() {
    final types = _editorProvider.schemaState.getAllowedTypes().toList()
      ..sort();
    final rows = <Component>[];
    for (final type in types) {
      rows.add(Text(type));
    }

    return Container(
      width: 32,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        border: BoxBorder.all(style: BoxBorderStyle.double),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'BD TYPES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _closeDbTypesWindow,
                child: const Text(
                  'X',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const Divider(style: DividerStyle.single),
          Text('DB: ${_editorProvider.schemaState.databaseEngine.name}'),
          const Divider(style: DividerStyle.single),
          ...rows,
          const Divider(style: DividerStyle.single),
          const Text('Esc fecha'),
        ],
      ),
    );
  }

  Component _buildSidebarPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _sidebarVerticalController,
            child: SidebarComponent(schemas: _editorProvider.schemaState),
          ),
        ),
        GestureDetector(
          onTap: _toggleDbTypesWindow,
          child: Text(
            'BD types',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _isDbTypesOpen ? Colors.brightCyan : Colors.cyan,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _sigintSubscription?.cancel();
    _commandController.dispose();
    _editorVerticalController.dispose();
    _editorHorizontalController.dispose();
    _sidebarVerticalController.dispose();
    super.dispose();
  }

  Future<void> _copyInputToClipboard() async {
    final text = _commandController.text;
    if (text.trim().isEmpty) {
      setState(() {
        _copyFeedback = 'Nada para copiar: input vazio.';
        _copyFeedbackIsError = true;
      });
      return;
    }

    try {
      await ClipboardService.copy(text);
      setState(() {
        _copyFeedback = 'Input copiado para a área de transferência.';
        _copyFeedbackIsError = false;
      });
    } catch (error) {
      setState(() {
        _copyFeedback = 'Falha ao copiar input: $error';
        _copyFeedbackIsError = true;
      });
    }
  }

  Future<void> _copyLastFeedbackToClipboard() async {
    final text = _editorProvider.lastFeedback.trim();
    if (text.isEmpty) {
      setState(() {
        _copyFeedback = 'Nada para copiar na mensagem.';
        _copyFeedbackIsError = true;
      });
      return;
    }

    try {
      await ClipboardService.copy(text);
      setState(() {
        _copyFeedback = 'Mensagem copiada para a área de transferência.';
        _copyFeedbackIsError = false;
      });
    } catch (error) {
      setState(() {
        _copyFeedback = 'Falha ao copiar mensagem: $error';
        _copyFeedbackIsError = true;
      });
    }
  }

  void _toggleHelpWindow() {
    setState(() {
      _isHelpOpen = !_isHelpOpen;
    });
  }

  void _toggleDbTypesWindow() {
    setState(() {
      _isDbTypesOpen = !_isDbTypesOpen;
    });
  }

  void _closeHelpWindow() {
    if (!_isHelpOpen) return;
    setState(() {
      _isHelpOpen = false;
    });
  }

  void _closeDbTypesWindow() {
    if (!_isDbTypesOpen) return;
    setState(() {
      _isDbTypesOpen = false;
    });
  }

  void _copyHelpCommandToInput(String command) {
    setState(() {
      _commandController.text = command;
      _commandController.selection = TextSelection.collapsed(
        offset: command.length,
      );
      _historyCursor = -1;
      _historyDraft = '';
      _isHelpOpen = false;
    });
  }

  void _navigateHistory({required bool up}) {
    final history = _editorProvider.commandHistory;
    if (history.isEmpty) return;

    if (up) {
      if (_historyCursor == -1) {
        _historyDraft = _commandController.text;
        _historyCursor = history.length - 1;
      } else if (_historyCursor > 0) {
        _historyCursor -= 1;
      }
    } else {
      if (_historyCursor == -1) return;
      if (_historyCursor < history.length - 1) {
        _historyCursor += 1;
      } else {
        _historyCursor = -1;
        _commandController.text = _historyDraft;
        _commandController.selection = TextSelection.collapsed(
          offset: _commandController.text.length,
        );
        return;
      }
    }

    final selected = history[_historyCursor];
    _commandController.text = selected;
    _commandController.selection = TextSelection.collapsed(
      offset: selected.length,
    );
  }

  void _submitCommand(String value) {
    setState(() {
      _editorProvider.submitCommand(value);
      _commandController.clear();
      _historyCursor = -1;
      _historyDraft = '';
    });
  }

  bool _handleCommandInputKeyEvent(KeyboardEvent event) {
    if (event.isControlPressed && event.logicalKey == LogicalKey.keyC) {
      _copyInputToClipboard();
      return true;
    }
    if (event.isControlPressed && event.logicalKey == LogicalKey.keyE) {
      _copyLastFeedbackToClipboard();
      return true;
    }
    if (!event.isControlPressed && event.logicalKey == LogicalKey.arrowUp) {
      _navigateHistory(up: true);
      return true;
    }
    if (!event.isControlPressed && event.logicalKey == LogicalKey.arrowDown) {
      _navigateHistory(up: false);
      return true;
    }
    if (event.isControlPressed && event.logicalKey == LogicalKey.arrowUp) {
      _editorVerticalController.scrollUp(3);
      return true;
    }
    if (event.isControlPressed && event.logicalKey == LogicalKey.arrowDown) {
      _editorVerticalController.scrollDown(3);
      return true;
    }
    if (event.isControlPressed && event.logicalKey == LogicalKey.arrowLeft) {
      _editorHorizontalController.scrollUp(3);
      return true;
    }
    if (event.isControlPressed && event.logicalKey == LogicalKey.arrowRight) {
      _editorHorizontalController.scrollDown(3);
      return true;
    }
    if (event.logicalKey == LogicalKey.escape && _isHelpOpen) {
      setState(() {
        _isHelpOpen = false;
      });
      return true;
    }
    if (event.logicalKey == LogicalKey.escape && _isDbTypesOpen) {
      setState(() {
        _isDbTypesOpen = false;
      });
      return true;
    }
    return false;
  }

  Component _buildHelpWindow() {
    final commandItems = <Component>[];
    for (final command in _helpCommandTemplates) {
      commandItems.add(
        GestureDetector(
          onTap: () => _copyHelpCommandToInput(command),
          child: Text(command, style: const TextStyle(color: Colors.cyan)),
        ),
      );
    }
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        border: BoxBorder.all(style: BoxBorderStyle.double),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'HELP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _closeHelpWindow,
                child: const Text(
                  'X',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const Divider(style: DividerStyle.single),
          const Text('Clique no comando para copiar no input'),
          const Divider(style: DividerStyle.single),
          ...commandItems,
          const Divider(style: DividerStyle.single),
          const Text('Historico: seta cima/baixo no input'),
          const Text('Scroll editor: Ctrl + setas'),
          const Text('Copiar input: Ctrl + C'),
          const Text('Copiar feedback: Ctrl + E'),
          const Text('ESC fecha help'),
        ],
      ),
    );
  }

  Component _buildEditorHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text(
              'Lazy',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
            ),
            const Text(
              'Forge',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(width: 1),
            Text(
              '[${component.projectName} · ${_editorProvider.schemaState.databaseEngine.name}]',
              style: const TextStyle(color: Colors.brightBlack),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => exit(0),
              child: const Text(
                'sair',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        const Divider(style: DividerStyle.bold),
      ],
    );
  }

  @override
  Component build(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 1, child: _buildSidebarPanel()),
            const VerticalDividerComponent(),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildEditorHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 1, right: 1),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SingleChildScrollView(
                              controller: _editorVerticalController,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                controller: _editorHorizontalController,
                                child: TableGraphLayoutComponent(
                                  schemaState: _editorProvider.schemaState,
                                ),
                              ),
                            ),
                          ),
                          if (_isHelpOpen)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: _buildHelpWindow(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _editorProvider.lastFeedback,
                          style: TextStyle(
                            color: _editorProvider.lastCommandFailed
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _copyInputToClipboard,
                        child: const Text(
                          '[copy cmd]',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                          ),
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(color: Colors.brightBlack),
                      ),
                      GestureDetector(
                        onTap: _copyLastFeedbackToClipboard,
                        child: const Text(
                          '[copy msg]',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan,
                          ),
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(color: Colors.brightBlack),
                      ),
                      GestureDetector(
                        onTap: _toggleHelpWindow,
                        child: Text(
                          '[help]',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isHelpOpen
                                ? Colors.brightCyan
                                : Colors.cyan,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_copyFeedback.isNotEmpty)
                    Text(
                      _copyFeedback,
                      style: TextStyle(
                        color: _copyFeedbackIsError ? Colors.red : Colors.cyan,
                      ),
                    ),
                  TextField(
                    controller: _commandController,
                    focused: true,
                    placeholder: 'Digite um comando... ex: create table users',
                    decoration: InputDecoration(
                      border: BoxBorder.all(style: BoxBorderStyle.double),
                      focusedBorder: BoxBorder.all(
                        color: Colors.cyan,
                        style: BoxBorderStyle.double,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 1),
                    ),
                    onKeyEvent: _handleCommandInputKeyEvent,
                    onSubmitted: _submitCommand,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_isDbTypesOpen)
          Positioned(left: 1, bottom: 2, child: _buildDbTypesWindow()),
      ],
    );
  }
}
