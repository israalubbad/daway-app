import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/chat/domain/entities/chatbot_reply.dart';
import 'package:daway_app/features/chat/domain/repositories/chatbot_repository.dart';
import 'package:daway_app/features/chat/domain/usecases/chatbot_usecases.dart';
import 'package:daway_app/features/chat/presentation/cubit/chatbot_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatbotRepository implements ChatbotRepository {
  ApiResult<ChatbotReply> result = const Success(ChatbotReply(text: 'أهلًا وسهلًا!'));
  String? lastMessage;

  @override
  Future<ApiResult<ChatbotReply>> send({required String token, required String message}) async {
    lastMessage = message;
    return result;
  }
}

class _FakeSession implements SessionRepository {
  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.patient, token: 'tok-1');

  @override
  Future<void> clearSession() async {}
}

const _found = ChatbotReply(
  medicine: ChatbotMedicine(id: 8, name: 'Brufen', nameAr: 'بروفين'),
  pharmacies: [ChatbotPharmacy(pharmacyId: 1, name: 'صيدلية الأمل', price: 10)],
  totalFound: 1,
);

void main() {
  late _FakeChatbotRepository repository;

  ChatbotCubit build() {
    final cubit = ChatbotCubit(SendChatbotMessageUseCase(repository, _FakeSession()));
    addTearDown(cubit.close);
    return cubit;
  }

  setUp(() => repository = _FakeChatbotRepository());

  test('starts with an empty thread: nothing is said before the API says it', () {
    expect(build().state.messages, isEmpty);
  });

  test('shows the question and then exactly what the API replied', () async {
    final cubit = build();

    final error = await cubit.send(' مرحبا ');

    expect(error, isNull);
    expect(repository.lastMessage, 'مرحبا');
    final messages = cubit.state.messages;
    expect(messages.map((m) => m.text), ['مرحبا', 'أهلًا وسهلًا!']);
    expect(messages.map((m) => m.isMine), [true, false]);
    expect(cubit.state.results, isEmpty);
    expect(cubit.state.isSending, isFalse);
  });

  test('keeps the medicine and pharmacies found with the assistant message', () async {
    repository.result = const Success(_found);
    final cubit = build();

    await cubit.send('وين بلاقي بروفين');

    final messages = cubit.state.messages;
    expect(messages, hasLength(2));
    // A reply with only results has no words of its own.
    expect(messages.last.text, isEmpty);
    expect(messages.last.isMine, isFalse);
    expect(cubit.state.results[messages.last.id]?.medicine?.nameAr, 'بروفين');
    expect(cubit.state.results[messages.last.id]?.pharmacies.single.name, 'صيدلية الأمل');
  });

  test('adds no assistant message when the response has nothing', () async {
    repository.result = const Success(ChatbotReply());
    final cubit = build();

    await cubit.send('pandol');

    expect(cubit.state.messages.map((m) => m.text), ['pandol']);
    expect(cubit.state.isSending, isFalse);
  });

  test('returns the failure message and keeps the question when the call fails', () async {
    repository.result = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));
    final cubit = build();

    final error = await cubit.send('pandol');

    expect(error, 'تعذر الاتصال بالخادم');
    expect(cubit.state.messages.map((m) => m.text), ['pandol']);
    expect(cubit.state.isSending, isFalse);
  });

  test('ignores an empty message', () async {
    final cubit = build();

    expect(await cubit.send('   '), isNull);
    expect(repository.lastMessage, isNull);
    expect(cubit.state.messages, isEmpty);
  });
}
