/// Exceções próprias do TranCity.
///
/// Todas as camadas lançam exclusivamente subclasses de [AppException],
/// garantindo mensagens amigáveis em português para o usuário final.
sealed class AppException implements Exception {
  /// Cria uma exceção com [message] amigável ao usuário.
  const AppException(this.message);

  /// Mensagem em português exibida na interface.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Falha de autenticação (login, cadastro, recuperação de senha).
final class AuthException extends AppException {
  const AuthException(super.message);
}

/// Falha de leitura/escrita no Firebase Realtime Database.
final class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

/// Falha relacionada ao GPS (serviço desligado ou permissão negada).
final class LocationException extends AppException {
  const LocationException(super.message);
}

/// Falha de conectividade com a internet.
final class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Dados inválidos informados pelo usuário.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}
