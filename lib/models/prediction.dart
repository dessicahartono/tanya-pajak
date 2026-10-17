/// Hasil dari model / API untuk satu pertanyaan.
class Prediction {
  final String topic; // topik dengan peluang tertinggi
  final double confidence; // 0..1, dipakai di belakang layar saja
  final String answer;
  final String? sourceUrl;
  final String? sourceLabel;
  final List<String> suggestions; // topik terdekat untuk layar "kurang yakin"
  final List<String> related; // saran pertanyaan lanjutan
  final bool faqFound; // false = topik yakin, tapi tidak ada FAQ yang cukup mirip

  const Prediction({
    required this.topic,
    required this.confidence,
    required this.answer,
    this.sourceUrl,
    this.sourceLabel,
    this.suggestions = const [],
    this.related = const [],
    this.faqFound = true,
  });

  factory Prediction.fromJson(Map<String, dynamic> j) => Prediction(
        topic: j['topik'] as String,
        confidence: (j['confidence'] as num).toDouble(),
        answer: (j['jawaban'] ?? '') as String,
        sourceUrl: j['sumber'] as String?,
        sourceLabel: j['label_sumber'] as String?,
        suggestions: List<String>.from(j['saran_topik'] ?? const []),
        related: List<String>.from(j['pertanyaan_terkait'] ?? const []),
        faqFound: (j['faq_ditemukan'] ?? true) as bool,
      );
}
