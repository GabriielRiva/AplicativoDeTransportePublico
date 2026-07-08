import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/enums/user_role.dart';
import '../../domain/entities/user.dart';
import '../providers/usecase_providers.dart';

/// ViewModel das telas de Login, Cadastro e Recuperação de Senha.
///
/// O estado é o perfil autenticado ([User]) envolvido em [AsyncValue],
/// permitindo que a UI reaja a loading, sucesso e erro sem setState.
class AuthController extends AutoDisposeAsyncNotifier<User?> {
  @override
  FutureOr<User?> build() => null;

  /// Realiza o login do usuário (RF02) e retorna o perfil autenticado
  /// para o redirecionamento por perfil (RF03).
  Future<User?> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue<User?>.loading();
    try {
      final User user = await ref
          .read(loginUserProvider)
          .call(email: email, password: password);
      state = AsyncValue<User?>.data(user);
      return user;
    } catch (error, stackTrace) {
      AppLogger.error('Erro no login', error, stackTrace);
      state = AsyncValue<User?>.error(
        ErrorHandler.getUserMessage(error),
        stackTrace,
      );
      return null;
    }
  }

  /// Realiza o cadastro do usuário (RF01) e retorna o perfil criado.
  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? cnh,
  }) async {
    state = const AsyncValue<User?>.loading();
    try {
      final User user = await ref.read(registerUserProvider).call(
            name: name,
            email: email,
            password: password,
            role: role,
            cnh: cnh,
          );
      state = AsyncValue<User?>.data(user);
      return user;
    } catch (error, stackTrace) {
      AppLogger.error('Erro no cadastro', error, stackTrace);
      state = AsyncValue<User?>.error(
        ErrorHandler.getUserMessage(error),
        stackTrace,
      );
      return null;
    }
  }

  /// Envia o e-mail de recuperação de senha (RF17).
  ///
  /// Retorna `true` em caso de sucesso.
  Future<bool> recoverPassword(String email) async {
    state = const AsyncValue<User?>.loading();
    try {
      await ref.read(recoverPasswordProvider).call(email);
      state = const AsyncValue<User?>.data(null);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('Erro na recuperação de senha', error, stackTrace);
      state = AsyncValue<User?>.error(
        ErrorHandler.getUserMessage(error),
        stackTrace,
      );
      return false;
    }
  }
}

/// Provider do [AuthController].
final AutoDisposeAsyncNotifierProvider<AuthController, User?>
    authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, User?>(
  AuthController.new,
);
