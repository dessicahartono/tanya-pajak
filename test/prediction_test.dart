import 'package:flutter_test/flutter_test.dart';
import 'package:tanyapajak/models/prediction.dart';

void main() {
  test('faq_ditemukan dianggap true kalau tidak dikirim backend', () {
    final p = Prediction.fromJson({'topik': 'EFIN', 'confidence': 0.9, 'jawaban': '...'});
    expect(p.faqFound, isTrue);
  });

  test('faq_ditemukan false terbaca', () {
    final p = Prediction.fromJson({
      'topik': 'PPN',
      'confidence': 0.72,
      'jawaban': 'Belum ada FAQ yang cukup mirip...',
      'faq_ditemukan': false,
    });
    expect(p.faqFound, isFalse);
  });

  test('pertanyaan yang tidak dikenali: saran topik kosong', () {
    final p = Prediction.fromJson(
        {'topik': 'Umum', 'confidence': 0.0, 'jawaban': '', 'saran_topik': []});
    expect(p.suggestions, isEmpty);
  });
}
