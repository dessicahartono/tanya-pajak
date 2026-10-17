import 'prediction.dart';

enum Sender { user, bot }

class ChatMessage {
  final Sender sender;
  final String text; // untuk pesan pengguna
  final Prediction? prediction; // untuk balasan bot
  final bool loading;

  const ChatMessage.user(this.text)
      : sender = Sender.user,
        prediction = null,
        loading = false;
  const ChatMessage.bot(this.prediction)
      : sender = Sender.bot,
        text = '',
        loading = false;
  const ChatMessage.loading()
      : sender = Sender.bot,
        text = '',
        prediction = null,
        loading = true;
}
