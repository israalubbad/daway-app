import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/core/models/picked_location.dart';
import 'package:daway_app/features/assistant/data/models/assistant_reply_model.dart';
import 'package:daway_app/features/assistant/domain/entities/assistant_reply.dart';
import 'package:daway_app/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:daway_app/features/assistant/domain/usecases/send_assistant_message_usecase.dart';
import 'package:daway_app/features/assistant/presentation/cubit/assistant_cubit.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/auth/domain/repositories/session_repository.dart';
import 'package:daway_app/features/patient/domain/repositories/location_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/get_current_location_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssistantRepository implements AssistantRepository {
  ApiResult<AssistantReply> result = const Success(AssistantReply(text: 'تمام'));
  String? lastMessage;
  double? lastLatitude;
  double? lastLongitude;
  int calls = 0;

  @override
  Future<ApiResult<AssistantReply>> sendMessage({
    required String token,
    required String message,
    double? latitude,
    double? longitude,
  }) async {
    calls++;
    lastMessage = message;
    lastLatitude = latitude;
    lastLongitude = longitude;
    return result;
  }
}

class _FakeSession implements SessionRepository {
  @override
  Future<UserSession?> getSession() async =>
      const UserSession(accountType: AccountType.patient, token: 'tok');

  @override
  Future<void> saveSession(UserSession session) async {}

  @override
  Future<void> clearSession() async {}
}

class _FakeLocationRepository implements LocationRepository {
  ApiResult<PickedLocation> result =
      const Success(PickedLocation(latitude: 31.5, longitude: 34.46, address: 'غزة'));

  @override
  Future<ApiResult<PickedLocation>> getCurrentLocation() async => result;

  @override
  Future<ApiResult<String>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async =>
      const Success('');

  @override
  Future<ApiResult<PickedLocation>> searchAddress(String query) async =>
      const ApiError(ValidationFailure('لم يتم العثور على هذا العنوان'));
}

void main() {
  group('AssistantReplyModel', () {
    test('reads the text, the medicine and the pharmacies', () {
      final reply = AssistantReplyModel.fromJson({
        'success': true,
        'message': 'وجدت الدواء',
        'data': {
          'medicine': {'id': 6, 'trade_name': 'Brufen', 'image_url': 'https://x/b.jpg'},
          'pharmacies': [
            {'pharmacy_id': 1, 'name': 'صيدلية الأمل', 'distance_km': 1.2, 'price': 12.5},
            {'pharmacy_id': 2, 'pharmacy_name': 'صيدلية الشفاء'},
          ],
        },
      });

      expect(reply.text, 'وجدت الدواء');
      expect(reply.understood, isTrue);
      expect(reply.medicines.single.id, 6);
      expect(reply.medicines.single.name, 'Brufen');
      expect(reply.medicines.single.imageUrl, 'https://x/b.jpg');
      expect(reply.pharmacies.map((p) => p.name), ['صيدلية الأمل', 'صيدلية الشفاء']);
      expect(reply.pharmacies.first.distanceKm, 1.2);
      expect(reply.pharmacies.first.price, 12.5);
    });

    test('a reply with success false is "not understood" but keeps its text', () {
      final reply = AssistantReplyModel.fromJson({
        'success': false,
        'message': 'اكتب اسم الدواء',
      });

      expect(reply.understood, isFalse);
      expect(reply.text, 'اكتب اسم الدواء');
      expect(reply.hasResults, isFalse);
    });

    test('an unknown shape does not throw and yields an empty reply', () {
      final reply = AssistantReplyModel.fromJson({
        'data': {'weird': 1},
        'medicines': 'nope',
      });

      expect(reply.text, '');
      expect(reply.hasResults, isFalse);
    });

    test('at most five results are kept, and rows without a name are skipped', () {
      final reply = AssistantReplyModel.fromJson({
        'data': {
          'medicines': [
            for (var i = 0; i < 8; i++) {'id': i, 'trade_name': 'M$i'},
            {'id': 99},
          ],
        },
      });

      expect(reply.medicines, hasLength(5));
    });
  });

  group('AssistantCubit', () {
    late _FakeAssistantRepository repository;
    late _FakeLocationRepository locationRepository;

    AssistantCubit build() {
      final cubit = AssistantCubit(
        SendAssistantMessageUseCase(repository, _FakeSession()),
        GetCurrentLocationUseCase(locationRepository),
      );
      addTearDown(cubit.close);
      return cubit;
    }

    setUp(() {
      repository = _FakeAssistantRepository();
      locationRepository = _FakeLocationRepository();
    });

    test('starts with the welcome line', () {
      final cubit = build();

      expect(cubit.state.messages.single.text, AssistantCubit.welcomeText);
      expect(cubit.state.messages.single.isUser, isFalse);
    });

    test('a message adds the patient bubble and then the answer', () async {
      repository.result = const Success(
        AssistantReply(
          text: 'وجدته',
          medicines: [AssistantMedicine(id: 6, name: 'Brufen')],
        ),
      );
      final cubit = build();
      await Future<void>.delayed(Duration.zero);

      await cubit.send('  وين بلاقي بروفين  ');

      expect(repository.lastMessage, 'وين بلاقي بروفين');
      final messages = cubit.state.messages;
      expect(messages, hasLength(3));
      expect(messages[1].isUser, isTrue);
      expect(messages[1].text, 'وين بلاقي بروفين');
      expect(messages[2].text, 'وجدته');
      expect(messages[2].medicines.single.name, 'Brufen');
      expect(cubit.state.isSending, isFalse);
    });

    test('the device position is sent along when known', () async {
      final cubit = build();
      await Future<void>.delayed(Duration.zero);

      await cubit.send('بنادول');

      expect(repository.lastLatitude, 31.5);
      expect(repository.lastLongitude, 34.46);
    });

    test('without a position the question is still sent', () async {
      locationRepository.result =
          const ApiError(PermissionFailure('يرجى السماح بالوصول لموقعك'));
      final cubit = build();
      await Future<void>.delayed(Duration.zero);

      await cubit.send('بنادول');

      expect(repository.calls, 1);
      expect(repository.lastLatitude, isNull);
    });

    test('a failure shows as an error bubble, and sending works again', () async {
      repository.result = const ApiError(NetworkFailure('تعذر الاتصال بالخادم'));
      final cubit = build();

      await cubit.send('بنادول');

      final last = cubit.state.messages.last;
      expect(last.isError, isTrue);
      expect(last.text, 'تعذر الاتصال بالخادم');
      expect(cubit.state.isSending, isFalse);

      repository.result = const Success(AssistantReply(text: 'تمام'));
      await cubit.send('بنادول');
      expect(cubit.state.messages.last.text, 'تمام');
    });

    test('an empty reply with no results gets a hint instead of a blank bubble', () async {
      repository.result = const Success(AssistantReply(text: '', understood: false));
      final cubit = build();

      await cubit.send('مرحبا');

      expect(cubit.state.messages.last.text, isNotEmpty);
    });

    test('blank input and a second send while one is in flight are ignored', () async {
      final cubit = build();

      await cubit.send('   ');
      expect(repository.calls, 0);

      final first = cubit.send('بنادول');
      final second = cubit.send('بنادول');
      await Future.wait([first, second]);
      expect(repository.calls, 1);
    });
  });
}
