import 'package:dio/dio.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/simulation_result.dart';
import 'simulation_repository.dart';

class SimulationRepositoryImpl implements SimulationRepository {
  SimulationRepositoryImpl({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  @override
  Future<SimulationResult> fetchSimulation() async {
    try {
      final Response<Map<String, dynamic>> response = await _dio
          .get<Map<String, dynamic>>('/simulate');
      return SimulationResult.fromJson(response.data!);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw const TimeoutError();
        case DioExceptionType.badResponse:
          throw ServerError(e.response?.statusCode ?? 0);
        case DioExceptionType.unknown:
        default:
          throw const NetworkError();
      }
    } on AppException {
      rethrow;
    } catch (_) {
      throw const ParseError();
    }
  }
}
