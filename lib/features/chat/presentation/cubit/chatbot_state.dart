import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chatbot_reply.dart';

class ChatbotState {
  /// Oldest first.
  final List<ChatMessage> messages;

  /// The medicine / pharmacies the assistant found, by the id of the
  /// assistant message they belong to.
  final Map<int, ChatbotReply> results;
  final bool isSending;

  const ChatbotState({
    required this.messages,
    this.results = const {},
    this.isSending = false,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    Map<int, ChatbotReply>? results,
    bool? isSending,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      results: results ?? this.results,
      isSending: isSending ?? this.isSending,
    );
  }
}
