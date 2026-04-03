sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkError extends AppException {
  const NetworkError([super.message = 'Network unavailable']);
}

final class TimeoutError extends AppException {
  const TimeoutError([super.message = 'Request timed out']);
}

final class ServerError extends AppException {
  const ServerError(int statusCode)
    : super('Server returned status $statusCode');
}

final class ParseError extends AppException {
  const ParseError([super.message = 'Failed to parse server response']);
}

final class ConfigError extends AppException {
  const ConfigError([super.message = 'API_BASE_URL is not configured']);
}
