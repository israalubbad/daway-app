import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/helpers/api_result.dart';
import '../../../patient/domain/usecases/get_current_location_usecase.dart';
import '../../domain/usecases/send_assistant_message_usecase.dart';
import 'assistant_state.dart';

/// The conversation with the assistant. Starts with a welcome line (written
/// here, not by the server) and keeps the whole exchange in memory.
class AssistantCubit extends Cubit<AssistantState> {
  static const welcomeText =
      'مرحباً! اسألني عن أي دواء، أو اكتب ما تشعر به، وأدلّك على الصيدليات القريبة منك.';

  final SendAssistantMessageUseCase _sendMessageUseCase;
  final GetCurrentLocationUseCase _getCurrentLocationUseCase;

  double? _latitude;
  double? _longitude;

  AssistantCubit(this._sendMessageUseCase, this._getCurrentLocationUseCase)
      : super(const AssistantState(messages: [AssistantMessage(isUser: false, text: welcomeText)])) {
    _loadLocation();
  }

  /// Best effort and in the background: with a position the server can sort
  /// the pharmacies by distance; without one (denied, GPS off) it still answers.
  Future<void> _loadLocation() async {
    final result = await _getCurrentLocationUseCase();
    if (isClosed) return;
    if (result case Success(:final data)) {
      _latitude = data.latitude;
      _longitude = data.longitude;
    }
  }

  Future<void> send(String text) async {
    final message = text.trim();
    if (message.isEmpty || state.isSending) return;

    emit(
      state.copyWith(
        messages: [...state.messages, AssistantMessage(isUser: true, text: message)],
        isSending: true,
      ),
    );

    final result = await _sendMessageUseCase(
      message,
      latitude: _latitude,
      longitude: _longitude,
    );
    if (isClosed) return;

    final reply = switch (result) {
      Success(:final data) => AssistantMessage(
          isUser: false,
          text: data.text.isNotEmpty
              ? data.text
              : (data.hasResults
                  ? 'هذا ما وجدته لك:'
                  : 'لم أفهم طلبك، جرّب أن تكتب اسم الدواء.'),
          medicines: data.medicines,
          pharmacies: data.pharmacies,
        ),
      ApiError(:final failure) => AssistantMessage(
          isUser: false,
          text: failure.message,
          isError: true,
        ),
    };
    emit(state.copyWith(messages: [...state.messages, reply], isSending: false));
  }
}
