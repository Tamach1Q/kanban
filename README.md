# 余白の本棚

Kanbanアプリを、自分の読書記録用に変更したFlutterアプリです。
「読みたい」「読んでいる」「読了」の3つの状態で本を整理します。

- 書名・著者・読書メモ・5段階の評価を登録、編集
- 「読み始める」「読了にする」で状態を移動
- 書名・著者・メモから検索、状態ごとの冊数を表示
- PCでは3列、スマートフォンではタブで切り替え
- SharedPreferencesで端末・ブラウザに保存（端末間の同期なし）
- サンプルの本は、空の本棚のボタンから任意で追加

`lib/model.dart` は本のデータ、`lib/view_model.dart` は操作・保存、
`lib/view.dart` は画面、`lib/main.dart` は起動とテーマを担当します。
以前のKanbanで保存した記録は、書名と状態を引き継いで表示します。

```sh
flutter pub get
flutter run -d chrome
```

```sh
flutter analyze
flutter test
flutter build web --base-href "/kanban/"
```

GitHub Pagesへの更新は、Webビルド後に行います。

```sh
dart pub global run github_pages:github_pages -d build/web
```
