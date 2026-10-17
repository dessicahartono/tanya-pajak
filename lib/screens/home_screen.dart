import 'package:flutter/material.dart';
import '../data/topics.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();

  void _openChat(String question) {
    _controller.clear();
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(initialQuestion: question)),
    );
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tentang TanyaPajak'),
        content: const Text(
          'Prototipe proyek akhir mata kuliah Kecerdasan Buatan. '
          'Model klasifikasi teks menebak topik pertanyaan, lalu menampilkan jawaban '
          'dari FAQ pajak.go.id.\n\nBukan layanan resmi DJP. Untuk kepastian, '
          'hubungi Kring Pajak 1500200.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  const Text(
                    'TanyaPajak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: AppColors.navy,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      tooltip: 'Tentang aplikasi',
                      onPressed: _showAbout,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                      ),
                      icon: const Icon(Icons.info_outline, size: 20, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            // Isi (bisa di-scroll di HP kecil)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bingung soal Pajak? Tanya di sini.',
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.5,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Jawaban diambil dari FAQ resmi pajak.go.id.',
                      style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.gold),
                    ),
                    const SizedBox(height: 18),
                    const SectionLabel('Topik populer'),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: topics.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 54,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (_, i) => _TopicTile(
                        topic: topics[i],
                        onTap: () => _openChat(topics[i].starterQuestion),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SectionLabel('Coba tanyakan'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final q in exampleQuestions)
                          PillButton(label: q, onTap: () => _openChat(q)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Input + catatan
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  QuestionInput(controller: _controller, onSubmit: _openChat),
                  const SizedBox(height: 8),
                  const Text(
                    'Hanya prototipe, bukan layanan resmi DJP',
                    style: TextStyle(fontSize: 11, color: AppColors.footnote),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  const _TopicTile({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.accentTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(topic.icon, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  topic.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
