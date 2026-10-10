import 'package:flutter/material.dart';
import 'package:plane_mobile/presentation/widgets/preview/code_block_preview.dart';

// Native platforms retain title editing; rich-body editing is the PWA feature.
Future<void> showWorkItemEditor(BuildContext context,
    {required String title,
    required String html,
    required String identifier,
    bool focusTitle = false,
    required Future<String?> Function(String title, String? changedHtml)
        onSave}) async {
  await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      builder: (context) => _NativeTitleEditor(
          title: title, html: html, identifier: identifier, onSave: onSave));
}

class _NativeTitleEditor extends StatefulWidget {
  final String title, html, identifier;
  final Future<String?> Function(String, String?) onSave;
  const _NativeTitleEditor(
      {required this.title,
      required this.html,
      required this.identifier,
      required this.onSave});
  @override
  State<_NativeTitleEditor> createState() => _NativeTitleEditorState();
}

class _NativeTitleEditorState extends State<_NativeTitleEditor> {
  late final _title = TextEditingController(text: widget.title);
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: Padding(
          padding: EdgeInsets.fromLTRB(
              20, 16, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              TextButton(
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: const Text('Cancel')),
              Expanded(child: Center(child: Text(widget.identifier))),
              TextButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          if (_title.text.trim().isEmpty) return;
                          setState(() => _busy = true);
                          final error =
                              await widget.onSave(_title.text.trim(), null);
                          if (!context.mounted) return;
                          if (error == null) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              _busy = false;
                              _error = error;
                            });
                          }
                        },
                  child: Text(_busy ? 'Saving…' : 'Save'))
            ]),
            TextField(
                key: const ValueKey('edit-title'),
                controller: _title,
                enabled: !_busy,
                maxLength: 255,
                maxLines: null,
                style: Theme.of(context).textTheme.headlineSmall),
            if (_error != null) Text(_error!),
            Flexible(
                child:
                    SingleChildScrollView(child: RichHtml(html: widget.html)))
          ])));
}
