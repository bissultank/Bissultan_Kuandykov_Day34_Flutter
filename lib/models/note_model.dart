enum NoteStatus { active, completed, archived }

enum NoteCategory { personal, work, study, other }

class NoteModel {
  final String id;
  final String uid;
  final String title;
  final String content;
  final NoteStatus status;
  final NoteCategory category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.content,
    this.status = NoteStatus.active,
    this.category = NoteCategory.personal,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'title': title,
    'content': content,
    'status': status.name,
    'category': category.name,
    'tags': tags,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  factory NoteModel.fromMap(String id, Map<String, dynamic> map) => NoteModel(
    id: id,
    uid: map['uid'] ?? '',
    title: map['title'] ?? '',
    content: map['content'] ?? '',
    status: NoteStatus.values.firstWhere(
      (e) => e.name == map['status'],
      orElse: () => NoteStatus.active,
    ),
    category: NoteCategory.values.firstWhere(
      (e) => e.name == map['category'],
      orElse: () => NoteCategory.personal,
    ),
    tags: List<String>.from(map['tags'] ?? []),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
  );

  NoteModel copyWith({
    String? title,
    String? content,
    NoteStatus? status,
    NoteCategory? category,
    List<String>? tags,
  }) => NoteModel(
    id: id,
    uid: uid,
    title: title ?? this.title,
    content: content ?? this.content,
    status: status ?? this.status,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}
