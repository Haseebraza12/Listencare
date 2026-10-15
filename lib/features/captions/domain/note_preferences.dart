enum NoteFont {
  inter('Inter', 'Inter'),
  system('System', null),
  naskh('Noto Naskh Arabic', 'NotoNaskhArabic');

  const NoteFont(this.label, this.family);
  final String label;
  final String? family;
}
