import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'model.dart';

class ReadingViewModel extends ChangeNotifier {
  ReadingViewModel({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  final books = <Book>[];
  String? errorMessage;
  Future<void> _pendingSave = Future.value();
  bool _canSave = true;

  Future<void> load() async {
    try {
      // 以前のKanbanの記録も、新しい読書記録として引き継ぐ。
      final data =
          await _preferences.getString('reading_books') ??
          await _preferences.getString('kanban');
      if (data == null) return;
      final loaded = (jsonDecode(data) as List<dynamic>)
          .map((item) => Book.fromJson(item as Map<String, dynamic>))
          .toList();
      books
        ..clear()
        ..addAll(loaded);
    } catch (_) {
      _canSave = false;
      errorMessage = '記録を読み込めませんでした。ページを開き直してください。';
    }
    notifyListeners();
  }

  Future<void> _save() {
    notifyListeners();
    if (!_canSave) return Future.value();
    final data = jsonEncode(books.map((book) => book.toJson()).toList());
    // 操作した順に保存し、最後の状態が確実に残るようにする。
    _pendingSave = _pendingSave.then((_) async {
      try {
        await _preferences.setString('reading_books', data);
        errorMessage = null;
      } catch (_) {
        errorMessage = '保存できませんでした。ブラウザの保存設定を確認してください。';
      }
      notifyListeners();
    });
    return _pendingSave;
  }

  Future<void> add(Book book) {
    if (book.title.trim().isEmpty) return Future.value();
    book.title = book.title.trim();
    books.add(book);
    return _save();
  }

  Future<void> update(Book book, Book edited) {
    if (edited.title.trim().isEmpty) return Future.value();
    book
      ..title = edited.title.trim()
      ..author = edited.author
      ..note = edited.note
      ..status = edited.status
      ..rating = edited.rating;
    return _save();
  }

  Future<void> move(Book book, ReadingStatus status) {
    book.status = status;
    return _save();
  }

  Future<void> remove(Book book) {
    books.remove(book);
    return _save();
  }

  Future<void> addExamples() {
    if (books.isNotEmpty) return Future.value();
    books.addAll([
      Book(
        title: 'リーダブルコード',
        author: 'Dustin Boswell / Trevor Foucher',
        note: '気になっていた技術書。読みやすいコードの書き方を学びたい。',
      ),
      Book(
        title: '銀河鉄道の夜',
        author: '宮沢賢治',
        status: ReadingStatus.reading,
        note: '寝る前に少しずつ。言葉の響きも楽しみながら。',
      ),
      Book(
        title: 'こころ',
        author: '夏目漱石',
        status: ReadingStatus.finished,
        rating: 4,
        note: '読み終わったあとも、しばらく余韻が残る一冊。',
      ),
    ]);
    return _save();
  }
}
[]