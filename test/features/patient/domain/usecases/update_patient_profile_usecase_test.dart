import 'package:daway_app/core/erroring/failure.dart';
import 'package:daway_app/core/helpers/api_result.dart';
import 'package:daway_app/features/auth/domain/entities/account_type.dart';
import 'package:daway_app/features/auth/domain/entities/user_session.dart';
import 'package:daway_app/features/patient/domain/entities/patient_profile.dart';
import 'package:daway_app/features/patient/domain/repositories/patient_profile_repository.dart';
import 'package:daway_app/features/patient/domain/usecases/update_patient_profile_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/in_memory_session_repository.dart';

class _FakePatientProfileRepository implements PatientProfileRepository {
  String? lastToken;
  PatientProfile? lastProfile;
  ApiResult<void> result = const Success(null);

  @override
  Future<ApiResult<PatientProfile>> getProfile({required String token}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<void>> updateProfile({
    required String token,
    required PatientProfile profile,
  }) async {
    lastToken = token;
    lastProfile = profile;
    return result;
  }
}

void main() {
  late _FakePatientProfileRepository repository;
  late InMemorySessionRepository sessionRepository;
  late UpdatePatientProfileUseCase useCase;

  const profile = PatientProfile(
    name: 'أحمد محمد',
    phone: '0599123456',
    latitude: 31.5017,
    longitude: 34.4668,
    address: 'غزة - الرمال',
  );

  setUp(() {
    repository = _FakePatientProfileRepository();
    sessionRepository = InMemorySessionRepository();
    useCase = UpdatePatientProfileUseCase(repository, sessionRepository);
  });

  test('fails without hitting the repository when there is no saved session', () async {
    final result = await useCase(profile);

    expect(result, isA<ApiError<void>>());
    expect(repository.lastProfile, isNull);
  });

  test('sends the session token and profile to the repository', () async {
    sessionRepository.savedSession =
        const UserSession(accountType: AccountType.patient, token: 'tok-789');

    final result = await useCase(profile);

    expect(result, isA<Success<void>>());
    expect(repository.lastToken, 'tok-789');
    expect(repository.lastProfile?.name, profile.name);
    expect(repository.lastProfile?.address, profile.address);
  });

  test('surfaces a repository failure', () async {
    sessionRepository.savedSession =
        const UserSession(accountType: AccountType.patient, token: 'tok-789');
    repository.result = const ApiError(NetworkFailure('لا يوجد اتصال بالإنترنت'));

    final result = await useCase(profile);

    expect(result, isA<ApiError<void>>());
  });
}
