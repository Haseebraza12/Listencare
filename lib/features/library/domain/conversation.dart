import '../../captions/domain/speech_engine.dart';

class Conversation {
  const Conversation({
    required this.id,
    required this.text,
    required this.language,
    required this.createdAt,
    required this.durationSeconds,
  });
  final String id;
  final String text;
  final CaptionLanguage language;
  final DateTime createdAt;
  final int durationSeconds;

  String get title {
    final line = text.split('\n').first;
    return line.length > 52 ? '${line.substring(0, 52)}…' : line;
  }

  Map<String, Object> toJson() => {
    'id': id,
    'text': text,
    'language': language.name,
    'createdAt': createdAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };
  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    text: json['text'] as String,
    language: CaptionLanguage.values.byName(json['language'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
    durationSeconds: json['durationSeconds'] as int,
  );
}
