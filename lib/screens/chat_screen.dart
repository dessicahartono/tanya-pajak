import 'package:flutter/material.dart';
import '../config.dart';
import '../models/chat_message.dart';
import '../models/prediction.dart';
import '../services/tanya_pajak_service.dart';
import '../theme.dart';
import '../widgets/chat_widgets.dart';
import '../widgets/common.dart';

class ChatScreen extends StatefulWidget {
  final String? initialQuestion;
  const ChatScreen({super.key, this.initialQuestion});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _service = TanyaPajakService.create();
  final _controller = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];
  String _lastQuestion = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuestion;
    if (q != null && q.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ask(q));
    }
  }

  Future<void> _run(Future<Prediction> Function() call, {String? userText}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      if (userText != null) _messages.add(ChatMessage.user(userText));
      _messages.add(const ChatMessage.loading());
    });
    _scrollToEnd();
    try {
      final p = await call();
      if (!mounted) return;
      setState(() => _messages[_messages.length - 1] = ChatMessage.bot(p));
    } catch (e) {
      if (!mounted) return;
      setState(() => _messages.removeLast());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal terhubung ke server. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToEnd();
    }
  }

  void _ask(String question) {
    // Cek di sini juga, bukan cuma di _run, supaya kolom input dan _lastQuestion
    // tidak berubah kalau pertanyaannya ternyata tidak jadi dikirim.
    if (_busy) return;
    _lastQuestion = question;
    _controller.clear();
    _run(() => _service.ask(question), userText: question);
  }

  void _pickTopic(String topic, String question) {
    _run(() => _service.answerForTopic(topic, question), userText: 'Topik: $topic');
  }

  void _rewrite() {
    _controller.text = _lastQuestion;
    _controller.selection = TextSelection.collapsed(offset: _lastQuestion.length);
    _focus.requestFocus();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Widget _buildMessage(int i) {
    final m = _messages[i];
    if (m.sender == Sender.user) return UserBubble(m.text);
    if (m.loading) return const TypingCard();
    final p = m.prediction!;
    // Persentase keyakinan tidak ditampilkan; hanya dipakai untuk memilih tampilan.
    if (p.confidence >= confidenceThreshold) {
      return AnswerCard(p: p, onRelatedTap: _ask, onRewrite: _rewrite);
    }
    // Kartu "kurang yakin" selalu tepat di bawah pertanyaan pengguna yang memicunya.
    final question = _messages[i - 1].text;
    return FallbackCard(
      p: p,
      onTopicTap: (topic) => _pickTopic(topic, question),
      onRewrite: _rewrite,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TanyaPajak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text('Asisten tanya-jawab pajak', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.chatBg),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _buildMessage(i),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: QuestionInput(
                controller: _controller,
                focusNode: _focus,
                fillColor: AppColors.bg,
                enabled: !_busy,
                onSubmit: _ask,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
