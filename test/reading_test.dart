import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kanban/main.dart';
import 'package:kanban/model.dart';
import 'package:kanban/view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryPreferences extends Fake implements SharedPreferencesAsync {
  final values = <String, String>{};
  final failures = <String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failures.contains('write')) throw StateError('Storage unavailable');
    values[key] = value;
  }
}

void main() {
  test('読書記録の追加・編集・状態変更・削除が再読み込み後も残る', () async {
    final preferences = MemoryPreferences();
    final vm = ReadingViewModel(preferences: preferences);
    final book = Book(title: '  技術書  ', author: '著者');
    await vm.add(book);
    await vm.update(
      book,
      Book(title: '技術書 改訂版', author: '著者', note: '命名が参考になった', rating: 4),
    );
    final firstMove = vm.move(book, ReadingStatus.reading);
    final lastMove = vm.move(book, ReadingStatus.finished);
    await Future.wait([firstMove, lastMove]);

    final reloaded = ReadingViewModel(preferences: preferences);
    await reloaded.load();
    expect(reloaded.books.single.title, '技術書 改訂版');
    expect(reloaded.books.single.author, '著者');
    expect(reloaded.books.single.note, '命名が参考になった');
    expect(reloaded.books.single.rating, 4);
    expect(reloaded.books.single.status, ReadingStatus.finished);
    await reloaded.remove(reloaded.books.single);
    final empty = ReadingViewModel(preferences: preferences);
    await empty.load();
    expect(empty.books, isEmpty);
  });

  test('旧Kanbanのデータを引き継ぎ、空白だけの書名は登録しない', () async {
    final preferences = MemoryPreferences();
    preferences.values['kanban'] = jsonEncode([
      {'title': '前の記録', 'status': 1},
    ]);
    final vm = ReadingViewModel(preferences: preferences);
    await vm.load();
    expect(vm.books.single.status, ReadingStatus.reading);
    await vm.add(Book(title: '   '));
    expect(vm.books.length, 1);
    await vm.move(vm.books.single, ReadingStatus.finished);
    expect(preferences.values.containsKey('reading_books'), isTrue);
  });

  test('保存できないときはエラーを表示し、次の保存で復帰する', () async {
    final preferences = MemoryPreferences()..failures.add('write');
    final vm = ReadingViewModel(preferences: preferences);
    await vm.add(Book(title: '本'));
    expect(vm.errorMessage, isNotNull);
    preferences.failures.clear();
    await vm.move(vm.books.single, ReadingStatus.reading);
    expect(vm.errorMessage, isNull);
  });

  test('破損した保存データを空のリストで上書きしない', () async {
    final preferences = MemoryPreferences();
    preferences.values['reading_books'] = 'broken json';
    final vm = ReadingViewModel(preferences: preferences);
    await vm.load();
    await vm.add(Book(title: '新しい本'));
    expect(vm.errorMessage, isNotNull);
    expect(preferences.values['reading_books'], 'broken json');
  });

  for (final width in [320.0, 390.0, 768.0, 1000.0, 1280.0]) {
    testWidgets('幅$widthで空の本棚・サンプル表示にレイアウトエラーがない', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final vm = ReadingViewModel(preferences: MemoryPreferences());
      await tester.pumpWidget(ReadingApp(vm: vm));
      expect(tester.takeException(), isNull);
      await vm.addExamples();
      await tester.pumpAndSettle();
      expect(find.text('わたしの本棚'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('本を登録し、読み始め、読了にして検索・編集・削除できる', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final vm = ReadingViewModel(preferences: MemoryPreferences());
    await tester.pumpWidget(ReadingApp(vm: vm));
    await tester.tap(find.text('本棚に追加'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '本棚に追加').last);
    await tester.pumpAndSettle();
    expect(find.text('書名を入力してください'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '気になっていた技術書');
    await tester.enterText(find.byType(TextFormField).at(1), '読書 太郎');
    await tester.enterText(find.byType(TextFormField).at(2), '命名を学びたい');
    await tester.tap(find.byTooltip('評価4'));
    await tester.tap(find.widgetWithText(FilledButton, '本棚に追加').last);
    await tester.pumpAndSettle();
    expect(vm.books.single.rating, 4);
    await tester.ensureVisible(find.text('読み始める'));
    await tester.tap(find.text('読み始める'));
    await tester.pumpAndSettle();
    expect(vm.books.single.status, ReadingStatus.reading);
    await tester.tap(find.text('読了にする'));
    await tester.pumpAndSettle();
    expect(vm.books.single.status, ReadingStatus.finished);

    await tester.enterText(find.byType(TextField).first, '存在しない書名');
    await tester.pumpAndSettle();
    expect(find.byTooltip('本のメニュー'), findsNothing);
    await tester.enterText(find.byType(TextField).first, '読書 太郎');
    await tester.pumpAndSettle();
    expect(find.byTooltip('本のメニュー'), findsOneWidget);
    await tester.tap(find.text('感想を残す'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(2), '読み終わった！');
    await tester.tap(find.text('変更を保存'));
    await tester.pumpAndSettle();
    expect(vm.books.single.note, '読み終わった！');

    await tester.tap(find.byTooltip('本のメニュー'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('本を削除'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();
    expect(vm.books, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
