import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exceptions.dart';
import 'config.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<bool> Function()? refresh,
  Future<void> Function()? onSessionLost,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (apiDelayMs.isNotEmpty) {
          options.queryParameters['__delay'] = apiDelayMs;
        }
        if (apiFailCode.isNotEmpty) {
          options.queryParameters['__fail'] = apiFailCode;
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        final status = response.statusCode ?? 0;
        final path = response.requestOptions.path;
        if (status == 401 &&
            refresh != null &&
            !path.contains('/auth/') &&
            response.requestOptions.extra['authRetry'] != true) {
          final ok = await refresh();
          if (ok) {
            final options = response.requestOptions;
            options.extra['authRetry'] = true;
            final token = tokenProvider?.call();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            try {
              final retried = await dio.fetch(options);
              return handler.resolve(retried);
            } on DioException catch (error) {
              return handler.reject(error);
            }
          }
          await onSessionLost?.call();
        }
        if (kDebugMode && status < 400) {
          debugPrint('[API] ${response.requestOptions.method} ${response.requestOptions.uri} → $status');
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, _decodeBody(response.data)),
            ),
            true,
          );
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          final status = error.response?.statusCode ?? error.type.name;
          debugPrint('[API] ${error.requestOptions.method} ${error.requestOptions.uri} → $status');
        }
        var current = error;
        while (_canRetry(current)) {
          final options = current.requestOptions;
          final attempt = options.extra['attempt'] as int? ?? 0;
          if (attempt >= 2) break;
          options.extra['attempt'] = attempt + 1;
          await Future<void>.delayed(Duration(milliseconds: 200 * (attempt + 1)));
          try {
            final response = await dio.fetch(options);
            return handler.resolve(response);
          } on DioException catch (next) {
            current = next;
          }
        }
        handler.next(current);
      },
    ),
  );
  return dio;
}

dynamic _decodeBody(dynamic data) {
  if (data is! String) return data;
  final text = data.trim();
  if (!text.startsWith('{') && !text.startsWith('[')) return data;
  try {
    return jsonDecode(text);
  } catch (_) {
    return data;
  }
}

bool _canRetry(DioException error) {
  if (error.requestOptions.method.toUpperCase() != 'GET') return false;
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError =>
      true,
    _ => false,
  };
}
