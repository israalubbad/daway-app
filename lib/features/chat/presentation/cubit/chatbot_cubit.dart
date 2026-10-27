import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/usecases/chatbot_usecases.dart';
import 'chatbot_state.dart';

const _welcomeMessage =
    'مرحباً! أنا مساعد دواك. اكتب اسم الدواء الذي تبحث عنه وسأدلّك على الصيدليات المتوفر فيها.';

/// The conversation with the patient assistant. Nothing is stored on the
/// backend, so the thread lives only as long as the screen.
class ChatbotCubit extends Cubit<ChatbotState> {
  final SendChatbotMessageUseCase _sendUseCase;
  int _nextId = 0;

  ChatbotCubit(this._sendUseCase) : super(const ChatbotState(messages: [])) {
    emit(ChatbotState(messages: [_message(_welcomeMessage, isMine: false)]));
  }

  ChatMessage _message(String text, {required bool isMine}) => ChatMessage(
        id: _nextId++,
        senderUserId: 0,
        text: text,
        isRead: true,
        createdAt: DateTime.now(),
        isMine: isMine,
      );

  /// Sends [text] and appends the reply. Returns null on success, or a
  /// user-facing error message.
  Future<String?> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return null;

    emit(state.copyWith(
      messages: [...state.messages, _message(trimmed, isMine: true)],
      isSending: true,
    ));

    final result = await _sendUseCase(trimmed);
    if (isClosed) return null;

    switch (result) {
      case Success(:final data):
        emit(state.copyWith(
          messages: [...state.messages, _message(data, isMine: false)],
          isSending: false,
        ));
        return null;
      case ApiError(:final failure):
        emit(state.copyWith(isSending: false));
        return failure.message;
    }
  }
}
