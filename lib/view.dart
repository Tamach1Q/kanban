import 'package:flutter/material.dart';
import 'model.dart';
import 'view_model.dart';

const _ink = Color(0xFF263F35);
const _muted = Color(0xFF788078);
const _line = Color(0xFFE4E7DF);
const _laneColors = [Color(0xFF718C69), Color(0xFFBD8854), Color(0xFF658C9E)];
const _laneIcons = [
  Icons.bookmark_border_rounded,
  Icons.auto_stories_outlined,
  Icons.check_circle_outline_rounded,
];

class ReadingView extends StatefulWidget {
  const ReadingView({super.key, required this.vm});
  final ReadingViewModel vm;

  @override
  State<ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends State<ReadingView> {
  final _search = TextEditingController();
  ReadingStatus _selected = ReadingStatus.wantToRead;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit({Book? book, ReadingStatus? status}) async {
    final result = await showDialog<Book>(
      context: context,
      builder: (_) => _BookEditor(book: book, status: status),
    );
    if (result == null || !mounted) return;
    if (book == null) {
      widget.vm.add(result);
      _search.clear();
    } else {
      widget.vm.update(book, result);
    }
    setState(() => _selected = result.status);
  }

  Future<void> _delete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('本棚から削除しますか？'),
        content: Text('「${book.title}」の読書メモと評価も削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '削除する',
              style: TextStyle(color: Color(0xFFAE4F43)),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) widget.vm.remove(book);
  }

  List<Book> _booksFor(ReadingStatus status) {
    final query = _search.text.trim().toLowerCase();
    return widget.vm.books
        .where(
          (book) =>
              book.status == status &&
              '${book.title} ${book.author} ${book.note}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.vm,
        builder: (context, child) => LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final compact = constraints.maxWidth < 650;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 20 : 48,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _header(compact),
                        const Divider(height: 1, color: _line),
                        _hero(compact),
                        _summary(compact),
                        const SizedBox(height: 40),
                        _boardToolbar(compact),
                        const SizedBox(height: 24),
                        if (widget.vm.errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEE8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(widget.vm.errorMessage!),
                          ),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final status in ReadingStatus.values) ...[
                                if (status.index > 0) const SizedBox(width: 20),
                                Expanded(child: _lane(status)),
                              ],
                            ],
                          )
                        else ...[
                          _tabs(),
                          const SizedBox(height: 16),
                          _lane(_selected),
                        ],
                        if (widget.vm.books.isEmpty && _search.text.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 22),
                            child: Center(
                              child: TextButton.icon(
                                onPressed: widget.vm.addExamples,
                                icon: const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 16,
                                ),
                                label: const Text('サンプルの本で試してみる'),
                              ),
                            ),
                          ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 36),
                          child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            runSpacing: 8,
                            spacing: 20,
                            children: [
                              Text(
                                '一冊ずつ、自分のペースで。',
                                style: TextStyle(fontSize: 12, color: _muted),
                              ),
                              Text(
                                '記録はこの端末・ブラウザに保存されます',
                                style: TextStyle(fontSize: 11, color: _muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _header(bool compact) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.auto_stories_outlined,
            color: Color(0xFFF4EEDD),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '余白の本棚',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  letterSpacing: 2,
                ),
              ),
              Text(
                'MY READING JOURNAL',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2.2,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        if (!compact) ...[
          const Text(
            '本と、わたしの記録。',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(width: 28),
        ],
        FilledButton.icon(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add, size: 18),
          label: Text(compact ? '本を追加' : '本棚に追加'),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 20,
              vertical: 17,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero(bool compact) => Padding(
    padding: EdgeInsets.symmetric(vertical: compact ? 32 : 44),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.spa_outlined, color: Color(0xFF7E946F), size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'A LITTLE SPACE FOR YOUR BOOKS',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.8,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '次の一冊が、\n楽しみになる。',
                style: TextStyle(
                  fontSize: compact ? 32 : 42,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  height: 1.5,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '読みたい気持ちも、読み終えた余韻も。\nあなただけの本棚に、少しずつ集めよう。',
                style: TextStyle(color: _muted, fontSize: 13, height: 1.9),
              ),
            ],
          ),
        ),
        if (!compact)
          const SizedBox(
            width: 280,
            height: 230,
            child: CustomPaint(painter: _BookshelfPainter()),
          ),
      ],
    ),
  );

  Widget _summary(bool compact) => Container(
    padding: EdgeInsets.symmetric(vertical: 20, horizontal: compact ? 10 : 28),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        for (final status in ReadingStatus.values) ...[
          if (status.index > 0) Container(width: 1, height: 40, color: _line),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!compact) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _laneColors[status.index].withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _laneIcons[status.index],
                      color: _laneColors[status.index],
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Column(
                  crossAxisAlignment: compact
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.label,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${widget.vm.books.where((book) => book.status == status).length}',
                            style: const TextStyle(
                              fontSize: 27,
                              color: _ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: '  冊',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _boardToolbar(bool compact) {
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'わたしの本棚',
          style: TextStyle(
            fontSize: 21,
            color: _ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${widget.vm.books.length} books',
          style: const TextStyle(fontSize: 12, color: _muted),
        ),
      ],
    );
    final search = TextField(
      controller: _search,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: '書名・著者・メモで検索',
        hintStyle: const TextStyle(color: _muted, fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 20),
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: '検索をクリア',
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(_search.clear),
              ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        isDense: true,
      ),
    );
    return compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [title, const SizedBox(height: 16), search],
          )
        : Row(
            children: [
              title,
              const Spacer(),
              SizedBox(width: 290, child: search),
            ],
          );
  }

  Widget _tabs() => Row(
    children: [
      for (final status in ReadingStatus.values)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(
                  status.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              selected: _selected == status,
              showCheckmark: false,
              selectedColor: const Color(0xFFE0E9DC),
              side: BorderSide(
                color: _selected == status ? const Color(0xFF9AAE91) : _line,
              ),
              onSelected: (_) => setState(() => _selected = status),
            ),
          ),
        ),
    ],
  );

  Widget _lane(ReadingStatus status) {
    final books = _booksFor(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1EB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                _laneIcons[status.index],
                color: _laneColors[status.index],
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                status.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 9),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${books.length}',
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
              ),
              const Spacer(),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '${status.label}に本を追加',
                onPressed: () => _edit(status: status),
                icon: const Icon(Icons.add, size: 19, color: _muted),
              ),
            ],
          ),
          Text(
            status.description,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
          const SizedBox(height: 20),
          for (final book in books) ...[
            _bookCard(book),
            const SizedBox(height: 12),
          ],
          if (books.isEmpty) _emptyLane(status),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: () => _edit(status: status),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('本を追加する', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: _muted),
          ),
        ],
      ),
    );
  }

  Widget _emptyLane(ReadingStatus status) {
    final searching = _search.text.trim().isNotEmpty;
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 38),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            searching ? Icons.search_off_rounded : _laneIcons[status.index],
            size: 36,
            color: _laneColors[status.index].withValues(alpha: 0.55),
          ),
          const SizedBox(height: 18),
          Text(
            searching ? '見つかりませんでした' : 'まだ本がありません',
            style: const TextStyle(color: _ink, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            searching
                ? '別の言葉で検索してみましょう。'
                : switch (status) {
                    ReadingStatus.wantToRead =>
                      '気になっていた技術書や小説を\n最初の一冊にしてみませんか。',
                    ReadingStatus.reading => '読み始めた本をここへ。\n少しずつ、自分のペースで。',
                    ReadingStatus.finished => '読み終えた一冊が\nここに並んでいきます。',
                  },
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11, height: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _bookCard(Book book) {
    final index = book.status.index;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAE3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BookCover(book: book),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: _ink,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      book.author.isEmpty ? '著者未登録' : book.author,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 24,
                height: 26,
                child: PopupMenuButton<String>(
                  tooltip: '本のメニュー',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz, color: _muted, size: 20),
                  onSelected: (value) =>
                      value == 'edit' ? _edit(book: book) : _delete(book),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('記録を編集')),
                    PopupMenuItem(value: 'delete', child: Text('本を削除')),
                  ],
                ),
              ),
            ],
          ),
          if (book.rating > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: List.generate(
                5,
                (i) => Icon(
                  i < book.rating
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: const Color(0xFFBD9454),
                  size: 18,
                ),
              ),
            ),
          ],
          if (book.note.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                book.note,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF757C71),
                  fontSize: 11,
                  height: 1.8,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: _line),
          const SizedBox(height: 8),
          Row(
            children: [
              if (index > 0)
                IconButton(
                  tooltip: '${ReadingStatus.values[index - 1].label}に戻す',
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: _muted,
                  ),
                  onPressed: () {
                    widget.vm.move(book, ReadingStatus.values[index - 1]);
                    setState(() => _selected = ReadingStatus.values[index - 1]);
                  },
                  visualDensity: VisualDensity.compact,
                ),
              const Spacer(),
              if (index < 2)
                TextButton(
                  onPressed: () {
                    widget.vm.move(book, ReadingStatus.values[index + 1]);
                    setState(() => _selected = ReadingStatus.values[index + 1]);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _ink,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        index == 0 ? '読み始める' : '読了にする',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 7),
                      const Icon(Icons.arrow_forward_rounded, size: 15),
                    ],
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () => _edit(book: book),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('感想を残す', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: _ink,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    const palettes = [
      Color(0xFF355E50),
      Color(0xFFB98266),
      Color(0xFF617F94),
      Color(0xFFA28D50),
    ];
    final index =
        book.title.runes.fold<int>(0, (sum, rune) => sum + rune) %
        palettes.length;
    return Container(
      width: 60,
      height: 86,
      decoration: BoxDecoration(
        color: palettes[index],
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(2),
          right: Radius.circular(5),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            offset: Offset(2, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0x30FFFFFF))),
              color: Color(0x15000000),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                children: [
                  Text(
                    book.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFF8E8),
                      fontSize: 8,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.spa_outlined,
                    size: 16,
                    color: Color(0x99FFF8E8),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookEditor extends StatefulWidget {
  const _BookEditor({this.book, this.status});
  final Book? book;
  final ReadingStatus? status;

  @override
  State<_BookEditor> createState() => _BookEditorState();
}

class _BookEditorState extends State<_BookEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.book?.title ?? '');
  late final _author = TextEditingController(text: widget.book?.author ?? '');
  late final _note = TextEditingController(text: widget.book?.note ?? '');
  late ReadingStatus _status =
      widget.book?.status ?? widget.status ?? ReadingStatus.wantToRead;
  late int _rating = widget.book?.rating ?? 0;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: const Color(0xFFFAF9F5),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    title: Text(
      widget.book == null ? '本棚に、新しい一冊を。' : '本の記録を編集',
      style: const TextStyle(
        fontSize: 20,
        color: _ink,
        fontWeight: FontWeight.w700,
      ),
    ),
    content: SizedBox(
      width: 430,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '気になる本も、お気に入りの本も。',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _title,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '書名（必須）',
                  hintText: '例：リーダブルコード',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '書名を入力してください'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _author,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '著者',
                  hintText: '例：宮沢賢治',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ReadingStatus>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: '読書の状態'),
                items: ReadingStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _note,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '読書メモ・感想',
                  alignLabelWithHint: true,
                  hintText: '読みたい理由や、心に残ったこと。',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'この本の評価',
                style: TextStyle(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 4),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      tooltip: '評価$i',
                      onPressed: () =>
                          setState(() => _rating = _rating == i ? 0 : i),
                      icon: Icon(
                        i <= _rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFBD9454),
                        size: 28,
                      ),
                    ),
                  Text(
                    _rating == 0 ? '未評価' : '$_rating / 5',
                    style: const TextStyle(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('キャンセル'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            Book(
              title: _title.text.trim(),
              author: _author.text.trim(),
              note: _note.text.trim(),
              status: _status,
              rating: _rating,
            ),
          );
        },
        child: Text(widget.book == null ? '本棚に追加' : '変更を保存'),
      ),
    ],
  );
}

class _BookshelfPainter extends CustomPainter {
  const _BookshelfPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawCircle(
      const Offset(146, 113),
      102,
      paint..color = const Color(0xFFEDEFE4),
    );
    canvas.drawCircle(
      const Offset(232, 44),
      6,
      paint..color = const Color(0xFFD3DCC6),
    );
    canvas.drawCircle(
      const Offset(39, 145),
      4,
      paint..color = const Color(0xFFCFB397),
    );
    void book(
      double x,
      double y,
      double w,
      double h,
      Color color,
      double rotation,
    ) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, w, h),
          const Radius.circular(4),
        ),
        paint..color = color,
      );
      canvas.drawRect(
        Rect.fromLTWH(5, 0, 2, h),
        paint..color = const Color(0x20000000),
      );
      canvas.drawRect(
        Rect.fromLTWH(13, 18, w - 23, 2),
        paint..color = const Color(0x80FFF9EC),
      );
      canvas.drawRect(
        Rect.fromLTWH(13, 24, w - 23, 2),
        paint..color = const Color(0x40FFF9EC),
      );
      canvas.drawCircle(
        Offset(w / 2 + 2, h * .68),
        9,
        paint..color = const Color(0x30FFF9EC),
      );
      canvas.restore();
    }

    book(53, 72, 40, 111, const Color(0xFFA6AD88), -.12);
    book(98, 53, 43, 130, const Color(0xFF426452), 0);
    book(143, 81, 32, 102, const Color(0xFFCA9B7C), 0);
    book(183, 68, 35, 117, const Color(0xFFDAC9A4), .16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(33, 183, 211, 7),
        const Radius.circular(3),
      ),
      paint..color = const Color(0xFFBDAB8D),
    );
    canvas.drawLine(
      const Offset(50, 191),
      const Offset(50, 200),
      paint
        ..color = const Color(0xFFBDAB8D)
        ..strokeWidth = 4,
    );
    canvas.drawLine(const Offset(227, 191), const Offset(227, 200), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
