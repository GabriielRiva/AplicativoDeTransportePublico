import 'package:firebase_auth/firebase_auth.dart';

import 'app_exception.dart';

/// Traduz erros técnicos em mensagens amigáveis em português.
abstract final class ErrorHandler {
  /// Converte um [FirebaseAuthException] em [AuthException] traduzida.
  static AuthException handleAuthError(FirebaseAuthException error) {
    final String message = switch (error.code) {
      'invalid-email' => 'O e-mail informado é inválido.',
      'user-disabled' => 'Esta conta foi desativada.',
      'user-not-found' => 'Nenhuma conta encontrada para este e-mail.',
      'wrong-password' ||
      'invalid-credential' =>
        'E-mail ou senha incorretos.',
      'email-already-in-use' => 'Este e-mail já está cadastrado.',
      'weak-password' => 'A senha é muito fraca. Use ao menos 6 caracteres.',
      'too-many-requests' =>
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      'network-request-failed' =>
        'Sem conexão com a internet. Verifique sua rede.',
      _ => 'Não foi possível concluir a operação. Tente novamente.',
    };
    return AuthException(message);
  }

  /// Extrai a mensagem amigável de qualquer erro capturado na aplicação.
  static String getUserMessage(Object error) {
    if (error is AppException) return error.message;
    if (error is FirebaseAuthException) {
      return handleAuthError(error).message;
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }
}
