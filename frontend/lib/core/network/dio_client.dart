import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';

/// Dio HTTP client configured with a Firebase bearer token interceptor.
class DioClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage;

  DioClient({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectionTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_authInterceptor());

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('DIO: $obj'),
        ),
      );
    }
  }

  Dio get dio => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.data is FormData) {
          options.headers.remove('Content-Type');
        }

        final token = await _readFirebaseToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final shouldRetry =
            error.response?.statusCode == 401 &&
            error.requestOptions.extra['retriedWithFreshToken'] != true;

        if (shouldRetry) {
          final token = await _refreshFirebaseToken();
          if (token != null) {
            final options = error.requestOptions;
            options.extra['retriedWithFreshToken'] = true;
            options.headers['Authorization'] = 'Bearer $token';

            try {
              final response = await _dio.fetch<dynamic>(options);
              handler.resolve(response);
              return;
            } catch (_) {}
          }
        }

        handler.next(error);
      },
    );
  }

  Future<String?> _readFirebaseToken() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null && token.isNotEmpty) {
        await _storage.write(
          key: ApiConstants.firebaseIdTokenStorageKey,
          value: token,
        );
        return token;
      }
    } catch (_) {}

    return _storage.read(key: ApiConstants.firebaseIdTokenStorageKey);
  }

  Future<String?> _refreshFirebaseToken() async {
    try {
      final token = await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token != null && token.isNotEmpty) {
        await _storage.write(
          key: ApiConstants.firebaseIdTokenStorageKey,
          value: token,
        );
        return token;
      }
    } catch (_) {}

    return null;
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.post(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.delete(path, data: data, queryParameters: queryParameters);
  }
}
