import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('planeMountWorkItemEditor')
external _EditorHandle _mountEditor(
    web.HTMLElement host,
    JSString title,
    JSString html,
    JSString identifier,
    JSString focus,
    JSBoolean dark,
    JSNumber scale,
    JSFunction save,
    JSFunction close);

extension type _EditorHandle(JSObject _) implements JSObject {
  external void requestClose();
  external void destroy();
}

Future<void>? _library;

Future<void> _loadEditor() => _library ??= _load().catchError((Object error) {
      _library = null;
      throw error;
    });

Future<void> _load() async {
  final base = Uri.parse(web.document.baseURI);
  final css = web.HTMLLinkElement()
    ..rel = 'stylesheet'
    ..href = base
        .resolve(ui_web.assetManager.getAssetUrl('assets/editor/editor.css'))
        .toString();
  final script = web.HTMLScriptElement()
    ..src = base
        .resolve(ui_web.assetManager.getAssetUrl('assets/editor/editor.js'))
        .toString();
  Future<void> loaded(web.HTMLElement element) {
    final done = Completer<void>();
    element.onload = ((web.Event _) => done.complete()).toJS;
    element.onerror = ((web.Event _) =>
        done.completeError(StateError('Editor unavailable'))).toJS;
    web.document.head!.append(element);
    return done.future.timeout(const Duration(seconds: 20)).whenComplete(() {
      element.onload = null;
      element.onerror = null;
    });
  }

  try {
    await Future.wait([loaded(css), loaded(script)]);
  } catch (_) {
    css.remove();
    rethrow;
  } finally {
    script.remove();
  }
}

/// The PWA edits in a real contenteditable (browser selection/history/IME).
/// Flutter owns the route and API write; JavaScript receives no credentials.
Future<void> showWorkItemEditor(BuildContext context,
    {required String title,
    required String html,
    required String identifier,
    bool focusTitle = false,
    required Future<String?> Function(String title, String? changedHtml)
        onSave}) {
  return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .94,
          child: _EditorSheet(
              title: title,
              html: html,
              identifier: identifier,
              focusTitle: focusTitle,
              onSave: onSave)));
}

class _EditorSheet extends StatefulWidget {
  final String title, html, identifier;
  final bool focusTitle;
  final Future<String?> Function(String, String?) onSave;
  const _EditorSheet(
      {required this.title,
      required this.html,
      required this.identifier,
      required this.focusTitle,
      required this.onSave});
  @override
  State<_EditorSheet> createState() => _EditorSheetState();
}

class _EditorSheetState extends State<_EditorSheet> {
  web.HTMLDivElement? _element;
  _EditorHandle? _handle;
  bool _failed = false;
  bool _loading = true;
  bool _closing = false;
  int _revision = 0;

  Future<void> _start() async {
    final revision = ++_revision;
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    setState(() {
      _failed = false;
      _loading = true;
    });
    try {
      await _loadEditor();
      if (!mounted || _closing || revision != _revision || _element == null)
        return;
      String cssColor(Color color) {
        final argb = color.toARGB32();
        return 'rgba(${(argb >> 16) & 255},${(argb >> 8) & 255},${argb & 255},${(argb >> 24) / 255})';
      }

      final colors = theme.colorScheme;
      for (final entry in {
        '--bg': colors.surface,
        '--fg': colors.onSurface,
        '--muted': colors.onSurfaceVariant,
        '--border': colors.outlineVariant.withAlpha(80),
        '--soft': colors.surfaceContainerHighest.withAlpha(50),
        '--accent': colors.primary,
        '--danger': colors.error,
      }.entries) {
        _element!.style.setProperty(entry.key, cssColor(entry.value));
      }
      _handle = _mountEditor(
          _element!,
          widget.title.toJS,
          widget.html.toJS,
          widget.identifier.toJS,
          (widget.focusTitle ? 'title' : 'body').toJS,
          (theme.brightness == Brightness.dark).toJS,
          scale.toJS,
          ((JSString title, JSString html, JSBoolean changed) =>
                  _save(title.toDart, changed.toDart ? html.toDart : null).toJS)
              .toJS,
          (() => _close()).toJS);
      setState(() => _loading = false);
    } catch (_) {
      if (mounted && revision == _revision) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<JSString> _save(String title, String? html) async {
    if (!mounted) return 'Editor closed'.toJS;
    return ((await widget.onSave(title, html)) ?? '').toJS;
  }

  void _close() {
    if (!mounted || _closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _revision++;
    _handle?.destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) {
          if (_failed || _loading) {
            _close();
          } else {
            _handle?.requestClose();
          }
        }
      },
      child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: Stack(children: [
                Positioned.fill(
                    child: HtmlElementView.fromTagName(
                        tagName: 'div',
                        onElementCreated: (element) {
                          _element = element as web.HTMLDivElement;
                          _element!.style
                            ..width = '100%'
                            ..height = '100%';
                          _start();
                        })),
                if (_loading)
                  const Positioned.fill(
                      child: Center(child: CircularProgressIndicator())),
                if (_loading)
                  Positioned(
                      left: 16,
                      top: 16,
                      child: IconButton(
                          tooltip: 'Close editor',
                          onPressed: _close,
                          icon: const Icon(Icons.close))),
                if (_failed)
                  Positioned.fill(
                      child: Center(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Could not open the editor'),
                    TextButton(onPressed: _start, child: const Text('Retry')),
                    TextButton(onPressed: _close, child: const Text('Close'))
                  ])))
              ]))));
}
