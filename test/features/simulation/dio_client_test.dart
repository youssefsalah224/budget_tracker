import 'package:budget_tracker_mobile/core/network/app_exception.dart';
import 'package:budget_tracker_mobile/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('throws ConfigError when API_BASE_URL is empty', () {
    expect(() => DioClient.forTest(''), throwsA(isA<ConfigError>()));
  });
}
