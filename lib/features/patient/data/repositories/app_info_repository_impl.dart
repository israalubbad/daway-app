import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/erroring/error_handler.dart';
import '../../../../core/helpers/api_result.dart';
import '../../domain/repositories/app_info_repository.dart';

class AppInfoRepositoryImpl implements AppInfoRepository {
  const AppInfoRepositoryImpl();

  @override
  Future<ApiResult<String>> getVersion() {
    return guardApi(() async {
      final info = await PackageInfo.fromPlatform();
      return Success(info.version);
    });
  }
}
