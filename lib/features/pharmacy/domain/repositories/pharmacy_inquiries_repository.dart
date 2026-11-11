import '../../../../core/helpers/api_result.dart';
import '../entities/inquiry.dart';

abstract class PharmacyInquiriesRepository {
  Future<ApiResult<InquiriesOverview>> getInquiries({required String token});

}
