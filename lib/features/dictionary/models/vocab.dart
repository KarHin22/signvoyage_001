import 'dart:convert';

class Vocab {
  final int? id;
  final String word;
  final String category;
  final List<String> videoPaths;

  Vocab({
    this.id,
    required this.word,
    required this.category,
    required this.videoPaths,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word': word,
      'category': category,
      'videoPaths': jsonEncode(videoPaths),
    };
  }

  factory Vocab.fromMap(Map<String, dynamic> map) {
    return Vocab(
      id: map['id'] as int?,
      word: map['word'] as String,
      category: map['category'] as String,
      videoPaths: List<String>.from(jsonDecode(map['videoPaths'] as String)),
    );
  }
}
