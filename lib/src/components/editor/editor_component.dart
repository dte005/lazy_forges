import 'dart:async';
import 'dart:io';

import 'package:nocterm/nocterm.dart';

import '../../services/clipboard_service.dart';
import '../../services/storage/project_storage.dart';
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
    required this.onExit,
  });
  final String projectName;
  final SchemaState initialSchema;
  final ProjectStorage projectStorage;

  /// Called when the user leaves the editor and returns to the entry menu.
  final VoidCallback onExit;

  @override
  State<EditorComponent> createState() => _EditorComponent();
}

enum _Overlay { help, dbTypes }

class _EditorComponent extends State<EditorComponent> {
  late final EditorProvider _editorProvider;
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _editorVerticalController = ScrollController();
  final ScrollController _editorHorizontalController = ScrollController();
  // Last pointer position while the right button is held; null when idle.
  ({int x, int y})? _panAnchor;
  final ScrollController _sidebarVerticalController = ScrollController();
  // Open overlays in opening order; the last item is the most recently opened.
  final List<_Overlay> _overlays = [];
  bool get _isHelpOpen => _overlays.contains(_Overlay.help);
  bool get _isDbTypesOpen => _overlays.contains(_Overlay.dbTypes);
  int _historyCursor = -1;
  String _historyDraft = '';
  StreamSubscription<ProcessSignal>? _sigintSubscription;
  String _copyFeedback = '';
  bool _copyFeedbackIsError = false;

  static const Color _panelBackground = Colors.black;
  static const TextStyle _panelTextStyle = TextStyle(color: Colors.white);

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

  /// Builds a floating panel with a solid background so the content behind
  /// it never bleeds through. [children] go below the title divider.
  Component _buildOpaquePanel({
    required double width,
    required String title,
    required VoidCallback onClose,
    required List<Component> children,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
      decoration: BoxDecoration(
        color: _panelBackground,
        border: BoxBorder.all(style: BoxBorderStyle.double),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
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
          ...children,
        ],
      ),
    );
  }

  Component _buildDbTypesWindow() {
    final types = _editorProvider.schemaState.getAllowedTypes().toList()
      ..sort();
    return _buildOpaquePanel(
      width: 32,
      title: 'BD TYPES',
      onClose: _closeDbTypesWindow,
      children: [
        Text(
          'DB: ${_editorProvider.schemaState.databaseEngine.name}',
          style: _panelTextStyle,
        ),
        const Divider(style: DividerStyle.single),
        for (final type in types) Text(type, style: _panelTextStyle),
        const Divider(style: DividerStyle.single),
        const Text('Esc fecha', style: _panelTextStyle),
      ],
    );
  }

  Component _buildSidebarPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Scrollbar(
            controller: _sidebarVerticalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _sidebarVerticalController,
              child: SidebarComponent(schemas: _editorProvider.schemaState),
            ),
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

  void _openOverlay(_Overlay overlay) {
    setState(() {
      _overlays
        ..remove(overlay)
        ..add(overlay);
    });
  }

  void _closeOverlay(_Overlay overlay) {
    if (!_overlays.contains(overlay)) return;
    setState(() {
      _overlays.remove(overlay);
    });
  }

  /// Closes the most recently opened overlay; returns false if none is open.
  bool _popTopOverlay() {
    if (_overlays.isEmpty) return false;
    setState(() {
      _overlays.removeLast();
    });
    return true;
  }

  void _toggleHelpWindow() {
    if (_isHelpOpen) {
      _closeOverlay(_Overlay.help);
    } else {
      _openOverlay(_Overlay.help);
    }
  }

  void _toggleDbTypesWindow() {
    if (_isDbTypesOpen) {
      _closeOverlay(_Overlay.dbTypes);
    } else {
      _openOverlay(_Overlay.dbTypes);
    }
  }

  void _closeHelpWindow() => _closeOverlay(_Overlay.help);

  void _closeDbTypesWindow() => _closeOverlay(_Overlay.dbTypes);

  void _copyHelpCommandToInput(String command) {
    setState(() {
      _commandController.text = command;
      _commandController.selection = TextSelection.collapsed(
        offset: command.length,
      );
      _historyCursor = -1;
      _historyDraft = '';
      _overlays.remove(_Overlay.help);
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

  // Right-button drag pans the canvas (grab-and-drag). The drag ends on the
  // first event without the right button, even after a release outside.
  void _handleCanvasPointer(MouseEvent event) {
    if (!event.buttons.contains(MouseButton.right)) {
      _panAnchor = null;
      return;
    }
    final anchor = _panAnchor;
    _panAnchor = (x: event.x, y: event.y);
    if (anchor == null) return;
    _panBy(_editorHorizontalController, anchor.x - event.x);
    _panBy(_editorVerticalController, anchor.y - event.y);
  }

  void _panBy(ScrollController controller, int delta) {
    if (delta == 0) return;
    final target = (controller.offset + delta).clamp(
      0.0,
      controller.maxScrollExtent,
    );
    controller.jumpTo(target);
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
    if (event.logicalKey == LogicalKey.pageUp) {
      _editorVerticalController.pageUp();
      return true;
    }
    if (event.logicalKey == LogicalKey.pageDown) {
      _editorVerticalController.pageDown();
      return true;
    }
    // Left/Right pan the canvas only on an empty input; otherwise the text
    // field keeps them for cursor movement.
    if (_commandController.text.isEmpty) {
      if (event.logicalKey == LogicalKey.arrowLeft) {
        _editorHorizontalController.scrollUp(_scrollStep);
        return true;
      }
      if (event.logicalKey == LogicalKey.arrowRight) {
        _editorHorizontalController.scrollDown(_scrollStep);
        return true;
      }
    }
    // `q` acts as Esc only on an empty input so typed commands are never
    // intercepted (onKeyEvent runs before text insertion).
    final isLeaveKey =
        event.logicalKey == LogicalKey.escape ||
        (!event.isControlPressed &&
            event.logicalKey == LogicalKey.keyQ &&
            _commandController.text.isEmpty);
    if (isLeaveKey) {
      if (!_popTopOverlay()) component.onExit();
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
    return _buildOpaquePanel(
      width: 70,
      title: 'HELP',
      onClose: _closeHelpWindow,
      children: [
        const Text(
          'Clique no comando para copiar no input',
          style: _panelTextStyle,
        ),
        const Divider(style: DividerStyle.single),
        ...commandItems,
        const Divider(style: DividerStyle.single),
        const Text(
          'Historico: seta cima/baixo no input',
          style: _panelTextStyle,
        ),
        const Text(
          'Navegar: PageUp/PageDown, setas esq/dir (input vazio)',
          style: _panelTextStyle,
        ),
        const Text(
          'Mouse: setas nas barras, botao direito arrasta',
          style: _panelTextStyle,
        ),
        const Text('Copiar input: Ctrl + C', style: _panelTextStyle),
        const Text('Copiar feedback: Ctrl + E', style: _panelTextStyle),
        const Text('ESC fecha help', style: _panelTextStyle),
      ],
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
              onTap: component.onExit,
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
                      padding: const EdgeInsets.only(top: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: MouseRegion(
                                    onHover: _handleCanvasPointer,
                                    onExit: (_) => _panAnchor = null,
                                    child: SingleChildScrollView(
                                      controller: _editorVerticalController,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        controller: _editorHorizontalController,
                                        child: TableGraphLayoutComponent(
                                          schemaState:
                                              _editorProvider.schemaState,
                                        ),
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
                          SizedBox(
                            width: 1,
                            child: _VerticalScrollIndicator(
                              controller: _editorVerticalController,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _HorizontalScrollIndicator(
                        controller: _editorHorizontalController,
                      ),
                    ],
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

// Lines/columns moved by one arrow-button or Left/Right step.
const double _scrollStep = 3;

const _scrollIndicatorStyle = TextStyle(color: Colors.cyan);

/// One-line horizontal scroll indicator (`◄▬▬░░░►`) for the graph canvas.
///
/// nocterm's `Scrollbar` only paints vertically, so this fills the gap. It
/// renders nothing while the content fits the viewport.
class _HorizontalScrollIndicator extends StatefulComponent {
  const _HorizontalScrollIndicator({required this.controller});

  final ScrollController controller;

  @override
  State<_HorizontalScrollIndicator> createState() =>
      _HorizontalScrollIndicatorState();
}

class _HorizontalScrollIndicatorState
    extends State<_HorizontalScrollIndicator> {
  @override
  void initState() {
    super.initState();
    component.controller.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    component.controller.removeListener(_onScrollChanged);
    super.dispose();
  }

  // Metrics change during layout, so rebuild on the next frame.
  void _onScrollChanged() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Component build(BuildContext context) {
    final controller = component.controller;
    final max = controller.maxScrollExtent;
    final viewport = controller.viewportDimension;
    final track = viewport.floor() - 2;
    if (max <= 0 || track < 2) return const SizedBox(height: 0);

    final thumb = (track * viewport / (viewport + max)).round().clamp(1, track);
    final room = track - thumb;
    final start = (room * (controller.offset / max)).round().clamp(0, room);
    return Row(
      children: [
        GestureDetector(
          onTap: () => controller.scrollUp(_scrollStep),
          child: const Text('◄', style: _scrollIndicatorStyle),
        ),
        Text(
          '${'░' * start}${'▬' * thumb}${'░' * (room - start)}',
          style: _scrollIndicatorStyle,
        ),
        GestureDetector(
          onTap: () => controller.scrollDown(_scrollStep),
          child: const Text('►', style: _scrollIndicatorStyle),
        ),
      ],
    );
  }
}

/// Vertical counterpart of [_HorizontalScrollIndicator]: `▲` and `▼` buttons
/// around a track with a thumb. Renders nothing while the content fits.
class _VerticalScrollIndicator extends StatefulComponent {
  const _VerticalScrollIndicator({required this.controller});

  final ScrollController controller;

  @override
  State<_VerticalScrollIndicator> createState() =>
      _VerticalScrollIndicatorState();
}

class _VerticalScrollIndicatorState extends State<_VerticalScrollIndicator> {
  @override
  void initState() {
    super.initState();
    component.controller.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    component.controller.removeListener(_onScrollChanged);
    super.dispose();
  }

  // Metrics change during layout, so rebuild on the next frame.
  void _onScrollChanged() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Component build(BuildContext context) {
    final controller = component.controller;
    final max = controller.maxScrollExtent;
    final viewport = controller.viewportDimension;
    final track = viewport.floor() - 2;
    if (max <= 0 || track < 2) return const SizedBox(width: 1);

    final thumb = (track * viewport / (viewport + max)).round().clamp(1, track);
    final room = track - thumb;
    final start = (room * (controller.offset / max)).round().clamp(0, room);
    return Column(
      children: [
        GestureDetector(
          onTap: () => controller.scrollUp(_scrollStep),
          child: const Text('▲', style: _scrollIndicatorStyle),
        ),
        for (var i = 0; i < track; i++)
          Text(
            i >= start && i < start + thumb ? '▬' : '░',
            style: _scrollIndicatorStyle,
          ),
        GestureDetector(
          onTap: () => controller.scrollDown(_scrollStep),
          child: const Text('▼', style: _scrollIndicatorStyle),
        ),
      ],
    );
  }
}
