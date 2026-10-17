import 'package:flutter/material.dart';
import '../theme.dart';

/// Kolom ketik pertanyaan + tombol kirim. Border jadi biru saat diklik (fokus).
class QuestionInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String> onSubmit;
  final Color fillColor;
  final bool enabled;

  const QuestionInput({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.focusNode,
    this.fillColor = Colors.white,
    this.enabled = true,
  });

  void _send() {
    final t = controller.text.trim();
    if (t.isEmpty || !enabled) return;
    onSubmit(t);
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: c, width: w),
        );
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              style: const TextStyle(fontSize: 15, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Ketik pertanyaan...',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18),
                enabledBorder: border(AppColors.borderStrong),
                focusedBorder: border(AppColors.accent, 2),
                border: border(AppColors.borderStrong),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: 'Kirim',
          button: true,
          child: Material(
            color: AppColors.accent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _send,
              child: const SizedBox(
                width: 50,
                height: 50,
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tombol pil (contoh pertanyaan / pertanyaan terkait).
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final double fontSize;
  final Color color;
  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.fontSize = 13,
    this.color = AppColors.gold,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: const StadiumBorder(),
        foregroundColor: color,
        textStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

/// Judul bagian kecil huruf kapital ("TOPIK POPULER").
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.navy,
        ),
      );
}
