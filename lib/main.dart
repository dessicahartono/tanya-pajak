import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  // Font diambil dari assets/google_fonts/, bukan diunduh. Jadi app tetap tampil
  // sesuai desain walaupun tidak ada internet.
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const TanyaPajakApp());
}

class TanyaPajakApp extends StatelessWidget {
  const TanyaPajakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TanyaPajak',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeScreen(),
    );
  }
}
