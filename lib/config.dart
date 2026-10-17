import 'package:flutter/foundation.dart';

/// Alamat API FastAPI.
/// - Web: host yang sama dengan halaman, port 8000 (dipilih otomatis), jadi kalau
///   dibuka dari HP lewat http://<IP-laptop>:<port> juga langsung ke laptop itu
/// - Emulator Android: http://10.0.2.2:8000 (dipilih otomatis)
/// - Simulator iOS / macOS: http://127.0.0.1:8000
/// - HP fisik (aplikasi native): ganti dengan http://<IP-laptop-di-wifi-yang-sama>:8000
/// - Backend yang sudah di-deploy: build dengan --dart-define=API_URL=https://alamat-backend
const _apiUrlDariBuild = String.fromEnvironment('API_URL');

String get apiBaseUrl {
  if (_apiUrlDariBuild.isNotEmpty) {
    return _apiUrlDariBuild;
  }
  // Dicek sebelum platform, karena di browser HP Android defaultTargetPlatform juga android.
  if (kIsWeb) {
    return 'http://${Uri.base.host}:8000';
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}

/// Di bawah batas ini, aplikasi tidak menampilkan jawaban (layar "kurang yakin").
const double confidenceThreshold = 0.5;
