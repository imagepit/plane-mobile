class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});

  @override
  String toString() => 'ServerException: $message (status: $statusCode)';
}

class UnauthorizedException extends ServerException {
  UnauthorizedException([String? message])
      : super(message ?? 'Unauthorized', statusCode: 401);
}

class ConnectionException implements Exception {
  final String message;

  ConnectionException([this.message = 'No internet connection']);

  @override
  String toString() => 'ConnectionException: $message';
}

class NotFoundException extends ServerException {
  NotFoundException([String? message])
      : super(message ?? 'Not found', statusCode: 404);
}

class ForbiddenException extends ServerException {
  ForbiddenException([String? message])
      : super(message ?? 'Forbidden', statusCode: 403);
}