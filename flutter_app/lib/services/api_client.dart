import 'dart:io';
import 'package:dio/dio.dart';
import '../config.dart';
import 'session_service.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {HttpHeaders.contentTypeHeader: 'application/json'},
  ));

  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    final token = await SessionService.I.getToken();
    return _dio.get(path, queryParameters: query, options: Options(headers: _auth(token)));
  }

  Future<Response> post(String path, dynamic body) async {
    final token = await SessionService.I.getToken();
    return _dio.post(path, data: body, options: Options(headers: _auth(token)));
  }

  Future<Response> put(String path, dynamic body) async {
    final token = await SessionService.I.getToken();
    return _dio.put(path, data: body, options: Options(headers: _auth(token)));
  }

  Future<Response> delete(String path) async {
    final token = await SessionService.I.getToken();
    return _dio.delete(path, options: Options(headers: _auth(token)));
  }

  Map<String, String> _auth(String? token) {
    if (token == null || token.isEmpty) return {};
    return {"Authorization": "Bearer $token"};
  }
}
