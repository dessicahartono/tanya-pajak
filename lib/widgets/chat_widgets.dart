import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/prediction.dart';
import '../theme.dart';
import 'common.dart';

Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tidak bisa membuka $url')),
    );
  }
}

/// Tombol kuning telepon Kring Pajak.
class _KringPajakButton extends StatelessWidget {
  const _KringPajakButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => openLink(context, 'tel:1500200'),
      icon: const Icon(Icons.call_outlined, size: 18),
      label: const Text('Hubungi Kring Pajak 1500200'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        backgroundColor: AppColors.yellow,
        foregroundColor: const Color(0xFF1F3F7A),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Tombol "Tulis ulang pertanyaan" (mengisi lagi kolom input).
class _RewriteButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _RewriteButton(this.onPressed);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: const StadiumBorder(),
        foregroundColor: AppColors.navy,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: const Text('Tulis ulang pertanyaan'),
    );
  }
}

/// Bubble pertanyaan pengguna (kanan, biru).
class UserBubble extends StatelessWidget {
  final String text;
  const UserBubble(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: const BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45)),
        ),
      ),
    );
  }
}

/// Kerangka kartu bot (kiri, putih).
class _BotCard extends StatelessWidget {
  final Widget child;
  final double widthFactor;
  const _BotCard({required this.child, this.widthFactor = 0.9});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * widthFactor),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class TypingCard extends StatelessWidget {
  const TypingCard({super.key});
  @override
  Widget build(BuildContext context) => const _BotCard(
        widthFactor: 0.6,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
            ),
            SizedBox(width: 10),
            Text('Mencari jawaban...', style: TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      );
}

/// Kartu jawaban: label topik, jawaban, sumber, dan tombol masukan.
/// Kalau FAQ-nya tidak ketemu, sumber dan tombol masukan diganti tombol Kring Pajak.
class AnswerCard extends StatefulWidget {
  final Prediction p;
  final ValueChanged<String> onRelatedTap;
  final VoidCallback onRewrite;
  const AnswerCard({super.key, required this.p, required this.onRelatedTap, required this.onRewrite});

  @override
  State<AnswerCard> createState() => _AnswerCardState();
}

class _AnswerCardState extends State<AnswerCard> {
  bool? _helpful;

  void _feedback(bool v) {
    setState(() => _helpful = v);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terima kasih atas masukannya'), duration: Duration(seconds: 1)),
    );
  }

  Widget _thumb(IconData icon, bool value, String label) {
    final selected = _helpful == value;
    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: 44,
        height: 32,
        child: OutlinedButton(
          onPressed: () => _feedback(value),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: const StadiumBorder(),
            side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
            backgroundColor: selected ? AppColors.accentTint : null,
          ),
          child: Icon(icon, size: 16, color: selected ? AppColors.accent : AppColors.muted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BotCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.topic,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent),
                ),
              ),
              const SizedBox(height: 10),
              Text(p.answer, style: const TextStyle(fontSize: 14, height: 1.55)),
              if (!p.faqFound) ...[
                const SizedBox(height: 14),
                const _KringPajakButton(),
                const SizedBox(height: 8),
                _RewriteButton(widget.onRewrite),
              ] else ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (p.sourceUrl != null)
                      Expanded(
                        child: InkWell(
                          onTap: () => openLink(context, p.sourceUrl!),
                          child: Text(
                            p.sourceLabel ?? 'Sumber',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gold,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.gold,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    _thumb(Icons.thumb_up_alt_outlined, true, 'Jawaban membantu'),
                    const SizedBox(width: 4),
                    _thumb(Icons.thumb_down_alt_outlined, false, 'Jawaban tidak membantu'),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (p.related.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in p.related)
                PillButton(
                  label: r,
                  fontSize: 12,
                  color: AppColors.accent,
                  onTap: () => widget.onRelatedTap(r),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Kartu saat model kurang yakin: saran topik + Kring Pajak + tulis ulang.
/// Saran topik kosong artinya model tidak mengenali satu kata pun di pertanyaannya.
class FallbackCard extends StatelessWidget {
  final Prediction p;
  final ValueChanged<String> onTopicTap;
  final VoidCallback onRewrite;
  const FallbackCard({super.key, required this.p, required this.onTopicTap, required this.onRewrite});

  @override
  Widget build(BuildContext context) {
    return _BotCard(
      widthFactor: 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p.suggestions.isEmpty
                ? 'Maaf, saya belum paham pertanyaan ini.'
                : 'Maaf, saya belum yakin dengan pertanyaan ini. Mungkin maksud Anda...',
            style: const TextStyle(fontSize: 15, height: 1.5, fontWeight: FontWeight.w700, color: AppColors.navy),
          ),
          if (p.suggestions.isEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Coba tulis ulang dengan kata kunci pajak, misalnya NPWP, SPT, EFIN, atau PPN.',
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.muted),
            ),
          ],
          const SizedBox(height: 14),
          for (final t in p.suggestions) ...[
            OutlinedButton(
              onPressed: () => onTopicTap(t),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                side: const BorderSide(color: AppColors.suggestBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: AppColors.navy,
              ),
              child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
          const _KringPajakButton(),
          const SizedBox(height: 8),
          _RewriteButton(onRewrite),
        ],
      ),
    );
  }
}
