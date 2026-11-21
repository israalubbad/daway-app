import 'package:dio/dio.dart';

/// The request options of a call made as the signed-in account: its token as a
/// bearer `Authorization` header. Every remote data source that needs the
/// session builds its options with this.
Options authOptions(String token) => Options(headers: {'Authorization': 'Bearer $token'});
