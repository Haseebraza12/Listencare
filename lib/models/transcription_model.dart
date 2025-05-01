class TranscriptionModel {
  final String text;
  final String language;
  final DateTime timestamp;

  TranscriptionModel({
    required this.text,
    required this.language,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'language': language,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TranscriptionModel.fromJson(Map<String, dynamic> json) {
    return TranscriptionModel(
      text: json['text'],
      language: json['language'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}