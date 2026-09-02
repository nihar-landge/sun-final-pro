/// Domain-level error types. Presentation code switches on these instead of
/// catching exceptions.
sealed class Failure {
  final String message;

  const Failure(this.message);
}

class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, {this.statusCode});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
