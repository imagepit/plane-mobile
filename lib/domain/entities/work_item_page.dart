import 'work_item.dart';

/// A cursor is an opaque query value, never a destination URL.
class CursorPage<T> {
  final List<T> items;
  final String? nextCursor;
  final bool hasNext;
  const CursorPage(
      {required this.items, this.nextCursor, this.hasNext = false});
  CursorPage<R> map<R>(R Function(T) convert) => CursorPage(
      items: items.map(convert).toList(),
      nextCursor: nextCursor,
      hasNext: hasNext);
}

typedef WorkItemPage = CursorPage<WorkItem>;
