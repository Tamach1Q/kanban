enum ReadingStatus {
  wantToRead('読みたい', '気になる一冊を、ここに。'),
  reading('読んでいる', '本と向き合う、いまの時間。'),
  finished('読了', '読み終えたら、思い出に。');

  const ReadingStatus(this.label, this.description);
  final String label;
  final String description;
}

class Book {
  Book({
    required this.title,
    this.author = '',
    this.note = '',
    this.status = ReadingStatus.wantToRead,
    this.rating = 0,
  });

  String title;
  String author;
  String note;
  ReadingStatus status;
  int rating;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    title: json['title'] as String,
    author: json['author'] as String? ?? '',
    note: json['note'] as String? ?? '',
    status: ReadingStatus.values[(json['status'] as int? ?? 0).clamp(0, 2)],
    rating: (json['rating'] as int? ?? 0).clamp(0, 5),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'author': author,
    'note': note,
    'status': status.index,
    'rating': rating,
  };
}
