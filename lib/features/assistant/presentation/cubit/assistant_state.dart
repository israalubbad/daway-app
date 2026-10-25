import '../../domain/entities/assistant_reply.dart';

/// One bubble of the conversation with the assistant.
class AssistantMessage {
  final bool isUser;
  final String text;
  final List<AssistantMedicine> medicines;
  final List<AssistantPharmacy> pharmacies;

  /// A failed request, drawn as an error line rather than an answer.
  final bool isError;

  const AssistantMessage({
    required this.isUser,
    required this.text,
    this.medicines = const [],
    this.pharmacies = const [],
    this.isError = false,
  });
}

class AssistantState {
  final List<AssistantMessage> messages;
  final bool isSending;

  const AssistantState({this.messages = const [], this.isSending = false});

  AssistantState copyWith({List<AssistantMessage>? messages, bool? isSending}) {
    return AssistantState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
    );
  }
}
