import 'package:flutter/material.dart';

class Topic {
  final String name;
  final IconData icon;
  final String starterQuestion; // pertanyaan yang dikirim saat tombol topik diketuk
  const Topic(this.name, this.icon, this.starterQuestion);
}

/// 10 topik di beranda. Topik "Umum" ada di model tetapi tidak punya tombol.
const topics = <Topic>[
  Topic('NPWP', Icons.badge_outlined, 'Apa saja saluran untuk melakukan pendaftaran NPWP?'),
  Topic('e-Filing', Icons.upload_outlined, 'Bagaimana cara lapor SPT online?'),
  Topic('SPT Tahunan', Icons.description_outlined, 'Apakah masih bisa melaporkan SPT dengan media kertas?'),
  Topic('PPh 21', Icons.account_balance_wallet_outlined, 'Bagaimana cara mengecek jika berhak dapat fasilitas DTP 21?'),
  Topic('PPN', Icons.receipt_long_outlined, 'Bagaimana cara mengecek e-Faktur yang valid?'),
  Topic('Sanksi & Denda', Icons.warning_amber_rounded, 'Bagaimana cara mengajukan penghapusan sanksi administrasi?'),
  Topic('EFIN', Icons.key_outlined, 'Bagaimana cara mendapatkan kembali EFIN yang lupa?'),
  Topic('Kode Billing', Icons.qr_code_2_outlined, 'Berapa lama masa daluwarsa kode billing?'),
  Topic('Coretax', Icons.dns_outlined, 'Apa yang dimaksud dengan ID TKU?'),
  Topic('e-SPT', Icons.desktop_windows_outlined, 'Bagaimana cara memperoleh installer e-SPT?'),
];

const exampleQuestions = <String>[
  'Cara lapor SPT online?',
  'Lupa EFIN, gimana?',
  'Gak lapor pajak kena sanksi?',
];
