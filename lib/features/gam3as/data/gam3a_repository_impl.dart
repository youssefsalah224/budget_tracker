import 'package:dio/dio.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../domain/gam3a.dart';
import 'gam3a_repository.dart';

class Gam3aRepositoryImpl implements Gam3aRepository {
  Gam3aRepositoryImpl({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  @override
  Future<List<Gam3a>> fetchAll() async {
    try {
      final response = await _dio.get<List<dynamic>>('/gam3as');
      return (response.data!)
          .map((e) => Gam3a.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.payoutMonth.compareTo(b.payoutMonth));
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw const TimeoutError();
        case DioExceptionType.badResponse:
          throw ServerError(e.response?.statusCode ?? 0);
        default:
          throw const NetworkError();
      }
    } catch (_) {
      throw const ParseError();
    }
  }

  @override
  Future<Gam3a> create(Gam3a gam3a) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/gam3as',
        data: gam3a.toJson(),
      );
      return Gam3a.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerError(e.response?.statusCode ?? 0);
    } catch (_) {
      throw const ParseError();
    }
  }

  @override
  Future<Gam3a> update(Gam3a gam3a) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '/gam3as/${gam3a.id}',
        data: gam3a.toJson(),
      );
      return Gam3a.fromJson(response.data!);
    } on DioException catch (e) {
      throw ServerError(e.response?.statusCode ?? 0);
    } catch (_) {
      throw const ParseError();
    }
  }

  @override
  Future<void> delete(int id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/gam3as/$id');
    } on DioException catch (e) {
      throw ServerError(e.response?.statusCode ?? 0);
    } catch (_) {
      throw const NetworkError();
    }
  }
}
