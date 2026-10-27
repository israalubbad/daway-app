import '../../domain/entities/chat_message.dart';

class ChatbotState {
  /// Oldest first.
  final List<ChatMessage> messages;
  final bool isSending;

  const ChatbotState({required this.messages, this.isSending = false});

  ChatbotState copyWith({List<ChatMessage>? messages, bool? isSending}) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}
