import 'package:dio/dio.dart';

sealed class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException([
    super.message = 'Сервер недоступен. Проверьте соединение.',
  ]);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Требуется вход в систему.']);
}

class ForbiddenException extends ApiException {
  const ForbiddenException([
    super.message = 'Недостаточно прав для этого действия.',
  ]);
}

class NotFoundException extends ApiException {
  const NotFoundException([super.message = 'Запись не найдена.']);
}

class ConflictException extends ApiException {
  const ConflictException(super.message);
}

class ValidationException extends ApiException {
  final Map<String, String> errors;
  const ValidationException(super.message, this.errors);
}

class ServerException extends ApiException {
  const ServerException([
    super.message = 'Ошибка на сервере. Попробуйте позже.',
  ]);
}

ApiException mapHttpError(int status, dynamic body) {
  final message = (body is Map && body['message'] is String)
      ? body['message'] as String
      : null;
  return switch (status) {
    401 => UnauthorizedException(message ?? 'Требуется вход в систему.'),
    403 => ForbiddenException(
      message ?? 'Недостаточно прав для этого действия.',
    ),
    404 => NotFoundException(message ?? 'Запись не найдена.'),
    409 => ConflictException(message ?? 'Операция невозможна.'),
    400 => _pocketBaseError(body, message),
    422 => ValidationException(
      message ?? 'Ошибка валидации',
      (body is Map && body['errors'] is Map)
          ? (body['errors'] as Map).map(
              (key, value) => MapEntry('$key', '$value'),
            )
          : const {},
    ),
    _ => ServerException(message ?? 'Неизвестная ошибка (код $status).'),
  };
}

ApiException _pocketBaseError(dynamic body, String? message) {
  final data = body is Map ? body['data'] : null;
  if (data is! Map || data.isEmpty) {
    return ServerException(message ?? 'Запрос отклонён.');
  }
  final errors = <String, String>{};
  var onlyUnique = true;
  for (final entry in data.entries) {
    final value = entry.value;
    final code = value is Map ? '${value['code'] ?? ''}' : '';
    final raw = value is Map && value['message'] is String
        ? value['message'] as String
        : 'Проверьте поле';
    if (code != 'validation_not_unique') onlyUnique = false;
    errors['${entry.key}'] = _russianFieldMessage(code, raw);
  }
  final details = errors.values.where((item) => item.isNotEmpty).join('\n');
  if (onlyUnique) {
    return ConflictException(
      details.isEmpty ? 'Такое значение уже есть' : details,
    );
  }
  return ValidationException(
    details.isEmpty ? 'Проверьте поля формы' : details,
    errors,
  );
}

String _russianFieldMessage(String code, String raw) {
  return switch (code) {
    'validation_required' => 'Заполните поле',
    'validation_not_unique' => 'Такое значение уже есть',
    'validation_min_text_constraint' ||
    'validation_max_text_constraint' => 'Проверьте длину',
    'validation_min_number_constraint' ||
    'validation_max_number_constraint' => 'Число вне допустимого диапазона',
    'validation_invalid_email' => 'Укажите почту в верном формате',
    _ => raw,
  };
}

ApiException mapDioError(DioException error) {
  final existing = error.error;
  if (existing is ApiException) return existing;
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout => const NetworkException(
      'Сервер не ответил вовремя.',
    ),
    DioExceptionType.connectionError => const NetworkException(
      'Не удалось соединиться с сервером. '
      'Если сервер запущен, откройте консоль браузера и проверьте наличие ошибки CORS.',
    ),
    DioExceptionType.cancel => const NetworkException('Запрос отменён.'),
    _ => const ServerException(),
  };
}

Future<T> guard<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on DioException catch (error) {
    throw mapDioError(error);
  }
}
