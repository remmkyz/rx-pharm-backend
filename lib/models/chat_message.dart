/// One message bubble in the Ask AI chat.
class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({required this.text, required this.isUser});
}