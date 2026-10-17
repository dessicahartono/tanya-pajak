import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna sesuai desain UI TanyaPajak.
class AppColors {
  static const navy = Color(0xFF204E8C); // judul, teks utama aksen
  static const accent = Color(0xFF1F4E8C); // tombol kirim, bubble pengguna
  static const yellow = Color(0xFFF5B800); // tombol Kring Pajak
  static const gold = Color(0xFFD7A719); // teks aksen kuning
  static const ink = Color(0xFF1B2A2F); // teks isi
  static const muted = Color(0xFF56656A);
  static const footnote = Color(0xFF5F6B70);
  static const bg = Color(0xFFF6F5F1); // latar beranda
  static const chatBg = Color(0xFFF2F2F2); // latar area chat
  static const border = Color(0xFFE2DFD6);
  static const borderStrong = Color(0xFFD5D1C6);
  static const divider = Color(0xFFEFEDE6);
  static const cardBorder = Color(0xFFE8E5DD);
  static const suggestBorder = Color(0xFFEAD6B4);
  static Color get accentTint => accent.withValues(alpha: 0.12);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent, primary: AppColors.accent),
    scaffoldBackgroundColor: AppColors.bg,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
