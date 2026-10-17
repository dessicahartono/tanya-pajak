import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/prediction.dart';

abstract class TanyaPajakService {
  /// Tebak topik dari pertanyaan bebas.
  Future<Prediction> ask(String question);

  /// Ambil jawaban untuk topik yang dipilih pengguna (dari layar "kurang yakin").
  /// [question] adalah pertanyaan asli, dipakai untuk mencari FAQ di topik itu.
  Future<Prediction> answerForTopic(String topic, String question);

  static TanyaPajakService create() => ApiTanyaPajakService(apiBaseUrl);
}

/// Memanggil API FastAPI: POST /predict {"pertanyaan": "..."}.
/// Respons yang diharapkan:
/// {"topik": "EFIN", "confidence": 0.91, "jawaban": "...", "sumber": "https://...",
///  "label_sumber": "...", "saran_topik": ["..."], "pertanyaan_terkait": ["..."]}
class ApiTanyaPajakService implements TanyaPajakService {
  final String baseUrl;
  ApiTanyaPajakService(this.baseUrl);

  @override
  Future<Prediction> ask(String question) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/predict'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'pertanyaan': question}),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}');
    }
    return Prediction.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }

  /// GET /jawaban/{topik}?pertanyaan=... -> format respons sama dengan /predict.
  @override
  Future<Prediction> answerForTopic(String topic, String question) async {
    final uri = Uri.parse('$baseUrl/jawaban/${Uri.encodeComponent(topic)}')
        .replace(queryParameters: {'pertanyaan': question});
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}');
    }
    return Prediction.fromJson(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }
}
