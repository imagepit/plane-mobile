import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('planeRenderMermaid')
external JSPromise<JSString> _renderMermaid(
    JSString source, JSBoolean dark, JSString id);

Future<void>? _library;
int _nextId = 0;

Future<void> _loadLibraries() =>
    _library ??= _load().catchError((Object error) {
      _library = null;
      throw error;
    });

Future<void> _load() async {
  for (final file in ['mermaid.min.js', 'renderer.js']) {
    final script = web.HTMLScriptElement()
      ..src = Uri.parse(web.document.baseURI)
          .resolve(ui_web.assetManager.getAssetUrl('assets/mermaid/$file'))
          .toString();
    final done = Completer<void>();
    script.onload = ((web.Event _) => done.complete()).toJS;
    script.onerror = ((web.Event _) =>
        done.completeError(StateError('Diagram library unavailable'))).toJS;
    web.document.head!.append(script);
    try {
      await done.future.timeout(const Duration(seconds: 20));
    } finally {
      script.onload = null;
      script.onerror = null;
      script.remove();
    }
  }
}

/// PWA diagrams use bundled Mermaid and noninteractive SVG in the current page.
class MermaidView extends StatefulWidget {
  final String source;
  final bool allowExpand;

  const MermaidView({super.key, required this.source, this.allowExpand = true});

  @override
  State<MermaidView> createState() => _MermaidViewState();
}

class _MermaidViewState extends State<MermaidView> {
  web.HTMLDivElement? _element;
  bool? _dark;
  bool _failed = false;
  bool _ready = false;
  bool _showSource = false;
  double _ratio = 2;
  int _revision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_dark != dark) {
      _dark = dark;
      _refresh();
    }
  }

  @override
  void didUpdateWidget(MermaidView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) _refresh();
  }

  Future<void> _refresh() async {
    final revision = ++_revision;
    _failed = false;
    _ready = false;
    if (_element == null) return;
    _element!.textContent = '';
    try {
      await _loadLibraries();
      if (!mounted || revision != _revision) return;
      final svg = (await _renderMermaid(widget.source.toJS, _dark!.toJS,
                  'planeDiagram${_nextId++}'.toJS)
              .toDart)
          .toDart;
      if (!mounted || revision != _revision) return;
      final doc = web.DOMParser().parseFromString(svg.toJS, 'image/svg+xml');
      final root = doc.documentElement!;
      final viewBox = (root.getAttribute('viewBox') ?? '')
          .split(RegExp(r'[\s,]+'))
          .map(double.tryParse)
          .toList();
      var ratio = 2.0;
      if (viewBox.length == 4 &&
          viewBox[2] != null &&
          viewBox[3] != null &&
          viewBox[2]! > 0 &&
          viewBox[3]! > 0) {
        ratio = viewBox[2]! / viewBox[3]!;
      }
      _element!.replaceChildren(web.document.importNode(root, true));
      setState(() {
        _ratio = ratio;
        _ready = true;
      });
    } catch (_) {
      if (mounted && revision == _revision) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _revision++;
    _element?.textContent = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.account_tree_outlined, size: 18),
              const SizedBox(width: 6),
              const Text('Mermaid'),
              const Spacer(),
              if (widget.allowExpand && !_failed)
                IconButton(
                  tooltip: '図を拡大',
                  icon: const Icon(Icons.fullscreen, size: 20),
                  onPressed: !_ready
                      ? null
                      : () => showDialog<void>(
                            context: context,
                            useRootNavigator: true,
                            builder: (context) => Dialog.fullscreen(
                                child: Scaffold(
                              appBar: AppBar(
                                  title: const Text('図'),
                                  leading: IconButton(
                                    tooltip: '閉じる',
                                    icon: const Icon(Icons.close),
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  )),
                              body: InteractiveViewer(
                                  maxScale: 6,
                                  child: Center(
                                      child: SizedBox(
                                    width: MediaQuery.sizeOf(context).width,
                                    child: MermaidView(
                                        source: widget.source,
                                        allowExpand: false),
                                  ))),
                            )),
                          ),
                ),
              if (!_failed)
                TextButton(
                  onPressed: () => setState(() => _showSource = !_showSource),
                  child: Text(_showSource ? '図を表示' : 'ソースを表示'),
                ),
            ]),
            // Keep the DOM view mounted while toggling source or retrying render.
            Offstage(
              offstage: _showSource || _failed,
              child: LayoutBuilder(builder: (context, constraints) {
                return SizedBox(
                  height: (constraints.maxWidth / _ratio).clamp(100, 480),
                  child: Stack(children: [
                    Positioned.fill(
                        child: HtmlElementView.fromTagName(
                      tagName: 'div',
                      onElementCreated: (element) {
                        _element = element as web.HTMLDivElement;
                        _element!.style
                          ..width = '100%'
                          ..height = '100%'
                          ..pointerEvents = 'none';
                        _refresh();
                      },
                    )),
                    if (!_ready)
                      const Center(child: CircularProgressIndicator()),
                  ]),
                );
              }),
            ),
            if (_failed && !_showSource) const Text('図を描画できませんでした。ソースを表示します。'),
            if (_showSource || _failed)
              SelectableText(widget.source,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontFamily: 'monospace')),
          ]),
    );
  }
}
