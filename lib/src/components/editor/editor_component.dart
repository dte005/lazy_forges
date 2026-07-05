import 'dart:io';
import 'package:nocterm/nocterm.dart';
import './components/sidebar/sidebar_component.dart';
import './components/table/table_component.dart';
import './components/vertical_divider/vertical_divider_component.dart';
import '../../providers/editor/editor_provider.dart';

class EditorComponent extends StatefulComponent {
  const EditorComponent({super.key});

  @override
  State<EditorComponent> createState() => _EditorComponent();
}

class _EditorComponent extends State<EditorComponent> {
  final EditorProvider _editorProvider = EditorProvider();
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _editorVerticalController = ScrollController();
  final ScrollController _editorHorizontalController = ScrollController();
  final ScrollController _sidebarVerticalController = ScrollController();
  bool _isHelpOpen = false;
  int _historyCursor = -1;
  String _historyDraft = '';

  static const List<String> _helpCommandTemplates = [
    'create table <table>',
    'create table <table> --autoincrement',
    'add column <table> <column> <type>',
    'add column <table> <column> enum options(v1|v2|v3)',
    'add column <table> <column> <type> description(descricao opcional)',
    'add columns <table> <coluna1> <tipo1>; <coluna2> <tipo2>',
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
    'history',
  ];

  @override
  void initState() {
    super.initState();
    _editorProvider.initializeEditorSchema();
  }

  @override
  void dispose() {
    _commandController.dispose();
    _editorVerticalController.dispose();
    _editorHorizontalController.dispose();
    _sidebarVerticalController.dispose();
    super.dispose();
  }

  void _toggleHelpWindow() {
    setState(() {
      _isHelpOpen = !_isHelpOpen;
    });
  }

  void _closeHelpWindow() {
    if (!_isHelpOpen) return;
    setState(() {
      _isHelpOpen = false;
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
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
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
              'LazyForge',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brightCyan,
              ),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            controller: _sidebarVerticalController,
            child: SidebarComponent(schemas: _editorProvider.schemaState),
          ),
        ),
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
                    onTap: _toggleHelpWindow,
                    child: Text(
                      'help',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isHelpOpen ? Colors.brightCyan : Colors.cyan,
                      ),
                    ),
                  ),
                ],
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
    );
  }
}
