import 'package:dio/dio.dart';

import 'app_exception.dart';

class DioClient {
  DioClient._()
    : this._withBaseUrl(const String.fromEnvironment('API_BASE_URL'));

  DioClient.forTest(String baseUrl) : this._withBaseUrl(baseUrl);

  DioClient._withBaseUrl(String baseUrl) {
    if (baseUrl.isEmpty) {
      throw const ConfigError(
        'API_BASE_URL build variable is not set. '
        'Run with --dart-define=API_BASE_URL=http://your-backend/api',
      );
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: <String, String>{'Accept': 'application/json'},
      ),
    );
  }

  static final DioClient instance = DioClient._();
  late final Dio _dio;

  Dio get dio => _dio;
}
