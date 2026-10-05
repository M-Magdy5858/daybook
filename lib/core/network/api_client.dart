import 'package:daybook/core/error/exceptions.dart';
import 'package:daybook/core/network/dio_error_mapper.dart';
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _sendMap(() => _dio.get<Object?>(path, queryParameters: query));

  /// For endpoints that return a JSON array, e.g. `GET /tasks`.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final data = await _send(
      () => _dio.get<Object?>(path, queryParameters: query),
    );
    if (data == null || data == '') return const [];
    if (data is List) return data;
    throw const ParsingException();
  }

  Future<Map<String, dynamic>> post(String path, {Object? body}) =>
      _sendMap(() => _dio.post<Object?>(path, data: body));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) =>
      _sendMap(() => _dio.patch<Object?>(path, data: body));

  Future<void> delete(String path) => _send(() => _dio.delete<Object?>(path));

  Future<Map<String, dynamic>> _sendMap(
    Future<Response<Object?>> Function() request,
  ) async {
    final data = await _send(request);
    if (data == null || data == '') return {};
    if (data is Map<String, dynamic>) return data;
    throw const ParsingException();
  }

  Future<Object?> _send(Future<Response<Object?>> Function() request) async {
    try {
      final response = await request();
      return response.data;
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
