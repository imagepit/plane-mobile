import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:plane_mobile/core/utils/date_formatter.dart';
import 'package:plane_mobile/domain/entities/work_item.dart';
import 'package:plane_mobile/presentation/widgets/preview/code_block_preview.dart';
import 'work_item_card.dart';

enum CommentSendResult { sent, failed, uncertain }

enum CommentCheckResult { posted, notPosted, failed }

class CommentSection extends StatefulWidget {
  final String itemId;
  final List<Comment> comments;
  final Widget? body;
  final bool isLoading, hasNext, uncertain;
  final String? error;
  final VoidCallback? onLoadMore, onReload;
  final Future<CommentSendResult> Function(String commentHtml) onAddComment;
  final Future<CommentCheckResult> Function()? onCheckComments;
  final Map<String, String>? drafts, postedDrafts, pendingDrafts;
  const CommentSection(
      {super.key,
      required this.itemId,
      required this.comments,
      this.body,
      this.isLoading = false,
      this.hasNext = false,
      this.uncertain = false,
      this.error,
      this.onLoadMore,
      this.onReload,
      required this.onAddComment,
      this.onCheckComments,
      this.drafts,
      this.postedDrafts,
      this.pendingDrafts});
  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final _controller = TextEditingController();
  final _localDrafts = <String, String>{};
  final _localPendingDrafts = <String, String>{};
  final _localPostedDrafts = <String, String>{};
  int _revision = 0;
  bool _sending = false, _checking = false, _uncertain = false;
  String? _message;
  Map<String, String> get _drafts => widget.drafts ?? _localDrafts;
  Map<String, String> get _postedDrafts =>
      widget.postedDrafts ?? _localPostedDrafts;
  Map<String, String> get _pendingDrafts =>
      widget.pendingDrafts ?? _localPendingDrafts;
  bool get _alreadyPosted => _postedDrafts[widget.itemId] == _controller.text;
  @override
  void initState() {
    super.initState();
    _controller.text = _drafts[widget.itemId] ?? '';
    _controller.addListener(_changed);
    _uncertain = widget.uncertain;
  }

  void _changed() {
    _revision++;
    _drafts[widget.itemId] = _controller.text;
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(CommentSection old) {
    super.didUpdateWidget(old);
    if (old.itemId != widget.itemId) {
      _drafts[old.itemId] = _controller.text;
      _controller.text = _drafts[widget.itemId] ?? '';
      _message = null;
      _uncertain = widget.uncertain;
    } else if (widget.uncertain) {
      _uncertain = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending ||
        _uncertain ||
        _alreadyPosted ||
        _controller.text.trim().isEmpty) return;
    final id = widget.itemId, revision = _revision;
    final text = _controller.text,
        postedDrafts = _postedDrafts,
        pendingDrafts = _pendingDrafts;
    pendingDrafts[id] = text;
    final html =
        '<p>${const HtmlEscape(HtmlEscapeMode.element).convert(_controller.text.trim()).replaceAll('\n', '<br>')}</p>';
    setState(() {
      _sending = true;
      _message = null;
    });
    CommentSendResult result;
    try {
      result = await widget.onAddComment(html);
    } catch (_) {
      result = CommentSendResult.uncertain;
    }
    if (result == CommentSendResult.sent) postedDrafts[id] = text;
    if (result != CommentSendResult.uncertain) pendingDrafts.remove(id);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (widget.itemId != id) return;
      if (result == CommentSendResult.sent) {
        if (_revision == revision) _controller.clear();
        _message = _revision == revision + 1 && _controller.text.isEmpty
            ? null
            : 'Previous comment sent. Your current draft is kept.';
      } else {
        _uncertain = result == CommentSendResult.uncertain;
        _message = _uncertain
            ? 'Could not confirm sending. Reload and check the comments before retrying.'
            : 'Comment was not sent. Your draft is kept.';
      }
    });
  }

  Future<void> _check() async {
    if (_checking || widget.onCheckComments == null) return;
    final id = widget.itemId,
        sentText = _pendingDrafts[widget.itemId] ?? _controller.text;
    final pendingDrafts = _pendingDrafts, postedDrafts = _postedDrafts;
    setState(() => _checking = true);
    CommentCheckResult result;
    try {
      result = await widget.onCheckComments!();
    } catch (_) {
      result = CommentCheckResult.failed;
    }
    if (result != CommentCheckResult.failed) {
      if (result == CommentCheckResult.posted) postedDrafts[id] = sentText;
      pendingDrafts.remove(id);
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      if (widget.itemId != id) return;
      if (result != CommentCheckResult.failed) {
        _uncertain = false;
        _message = result == CommentCheckResult.posted
            ? 'Confirmed in comments. Your draft is kept; clear or edit it before a new post.'
            : 'Not posted. You can retry manually.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(children: [
      Expanded(
          child: SingleChildScrollView(
              key: const ValueKey('detail-scroll'),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.body != null) widget.body!,
                    const Divider(height: 32),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          Text('Comments',
                              style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          IconButton(
                              tooltip: 'Reload comments',
                              onPressed:
                                  widget.isLoading ? null : widget.onReload,
                              icon: const Icon(Icons.refresh, size: 20))
                        ])),
                    if (widget.isLoading)
                      const LinearProgressIndicator(minHeight: 2),
                    if (widget.error != null)
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(widget.error!)),
                    if (widget.comments.isEmpty &&
                        !widget.isLoading &&
                        widget.error == null)
                      const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No comments yet')),
                    for (final comment in widget.comments)
                      Container(
                          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color:
                                  colors.surfaceContainerHighest.withAlpha(70),
                              borderRadius: BorderRadius.circular(16)),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  if (comment.actor != null)
                                    MemberAvatar(
                                        member: comment.actor!, radius: 14),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Text(
                                          comment.actor?.fullName ?? 'Unknown',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge)),
                                  const SizedBox(width: 8),
                                  Text(
                                      DateFormatter.formatRelative(
                                          comment.createdAt),
                                      style:
                                          Theme.of(context).textTheme.bodySmall)
                                ]),
                                const SizedBox(height: 12),
                                RichHtml(
                                    html: comment.commentHtml.isEmpty
                                        ? comment.comment ?? ''
                                        : comment.commentHtml,
                                    textStyle:
                                        Theme.of(context).textTheme.bodyLarge),
                              ])),
                    if (widget.hasNext)
                      Center(
                          child: TextButton(
                              key: const ValueKey('load-more-comments'),
                              onPressed:
                                  widget.isLoading ? null : widget.onLoadMore,
                              child: const Text('Load more comments'))),
                    const SizedBox(height: 16),
                  ]))),
      SafeArea(
          top: false,
          child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(
                      top: BorderSide(
                          color: colors.outlineVariant.withAlpha(70)))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (_message != null)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(_message!,
                          style: Theme.of(context).textTheme.bodySmall)),
                if (_uncertain)
                  TextButton(
                      onPressed: _checking ? null : _check,
                      child: Text(_checking
                          ? 'Checking comments…'
                          : 'Reload and check comments')),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(
                      child: TextField(
                          key: const ValueKey('comment-input'),
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                              hintText: 'Add comment',
                              prefixIcon: const Icon(Icons.chat_bubble_outline,
                                  size: 20),
                              filled: true,
                              fillColor: colors.surface,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          textInputAction: TextInputAction.newline)),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                      key: const ValueKey('send-comment'),
                      tooltip: 'Send comment',
                      onPressed: _sending || _uncertain || _alreadyPosted
                          ? null
                          : _send,
                      padding: const EdgeInsets.all(16),
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_upward))
                ]),
              ]))),
    ]);
  }
}
