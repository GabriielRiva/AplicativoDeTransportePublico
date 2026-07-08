import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/app_logger.dart';

/// Datasource do Firebase Authentication.
class FirebaseAuthDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseAuth].
  const FirebaseAuthDatasource(this._auth);

  final FirebaseAuth _auth;

  /// Stream com o UID autenticado (nulo quando deslogado).
  Stream<String?> authStateChanges() {
    return _auth.authStateChanges().map((User? user) => user?.uid);
  }

  /// UID do usuário autenticado, ou nulo.
  String? get currentUid => _auth.currentUser?.uid;

  /// Cria uma conta com e-mail e senha e retorna o UID gerado.
  Future<String> register({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String? uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException('Não foi possível criar a conta.');
      }
      AppLogger.info('Conta criada para $email');
      return uid;
    } on FirebaseAuthException catch (error, stackTrace) {
      AppLogger.error('Falha no cadastro', error, stackTrace);
      throw ErrorHandler.handleAuthError(error);
    }
  }

  /// Autentica com e-mail e senha e retorna o UID.
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String? uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException('Não foi possível realizar o login.');
      }
      AppLogger.info('Login realizado para $email');
      return uid;
    } on FirebaseAuthException catch (error, stackTrace) {
      AppLogger.error('Falha no login', error, stackTrace);
      throw ErrorHandler.handleAuthError(error);
    }
  }

  /// Encerra a sessão atual.
  Future<void> logout() async {
    try {
      await _auth.signOut();
      AppLogger.info('Logout realizado.');
    } on FirebaseAuthException catch (error, stackTrace) {
      AppLogger.error('Falha no logout', error, stackTrace);
      throw ErrorHandler.handleAuthError(error);
    }
  }

  /// Envia o e-mail de recuperação de senha.
  Future<void> recoverPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      AppLogger.info('E-mail de recuperação enviado para $email');
    } on FirebaseAuthException catch (error, stackTrace) {
      AppLogger.error('Falha na recuperação de senha', error, stackTrace);
      throw ErrorHandler.handleAuthError(error);
    }
  }
}
