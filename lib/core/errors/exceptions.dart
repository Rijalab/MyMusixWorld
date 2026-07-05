class AppException implements Exception {
  final String message;
  final String? code;
  AppException(this.message, {this.code});

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class AuthException extends AppException {
  AuthException(super.message, {super.code});
}

class StorageException extends AppException {
  StorageException(super.message, {super.code});
}

class DatabaseException extends AppException {
  DatabaseException(super.message, {super.code});
}

class MusicPlayerException extends AppException {
  MusicPlayerException(super.message, {super.code});
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code});
}

class CacheException extends AppException {
  CacheException(super.message, {super.code});
}

class DownloadException extends AppException {
  DownloadException(super.message, {super.code});
}

class SyncException extends AppException {
  SyncException(super.message, {super.code});
}
