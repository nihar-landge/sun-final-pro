/// Low-level transport errors, mapped to [Failure]s in repository
/// implementations so the presentation layer stays exception-free.
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException(this.message, {this.statusCode});
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);
}

class CacheException implements Exception {
  final String message;

  CacheException(this.message);
}
