import 'package:flutter_test/flutter_test.dart';
import 'package:plane_mobile/presentation/widgets/preview/file_tree_view.dart';

void main() {
  group('FileTreeParser', () {
    test('先頭の単独 . はルートとして名前を空にする', () {
      final lines = FileTreeParser.parse('.');
      expect(lines.single.isRoot, isTrue);
      expect(lines.single.name, isEmpty);
    });

    test('枝線の接頭辞を保ったまま名前を分ける', () {
      final lines = FileTreeParser.parse('''
├── pubspec.yaml
│   └── nested.dart
└── README.md
''');
      expect(lines.map((e) => e.name), ['pubspec.yaml', 'nested.dart', 'README.md']);
      expect(lines[0].prefix, '├── ');
      expect(lines[1].prefix, '│   └── ');
      expect(lines[2].prefix, '└── ');
      expect(lines.map((e) => e.depth), [0, 1, 0]);
    });

    test('マーカー ++ / ** / -- を分離する', () {
      final lines = FileTreeParser.parse('''
++ new_file.ts
** edited.ts
-- removed.ts
untouched.ts
''');
      expect(lines.map((e) => e.marker), ['++', '**', '--', '']);
      expect(lines.map((e) => e.name),
          ['new_file.ts', 'edited.ts', 'removed.ts', 'untouched.ts']);
    });

    test('callout <--[...] を分離する', () {
      final line = FileTreeParser.parse('** pubspec.yaml <--[dependencies を追加]').single;
      expect(line.marker, '**');
      expect(line.name, 'pubspec.yaml');
      expect(line.callout, 'dependencies を追加');
    });

    test('マーカー無しのコメント # は callout に畳む', () {
      final line = FileTreeParser.parse('foo.ts # 依存の終点').single;
      expect(line.name, 'foo.ts');
      expect(line.callout, '依存の終点');
    });

    test('空行を無視する', () {
      final lines = FileTreeParser.parse('a.ts\n\n\nb.ts\n');
      expect(lines.map((e) => e.name), ['a.ts', 'b.ts']);
    });
  });
}
