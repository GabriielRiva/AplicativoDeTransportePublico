import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/passenger.dart';
import '../../domain/entities/user.dart';
import '../providers/usecase_providers.dart';

/// ViewModel do perfil do usuário autenticado (RF15/RF16).
///
/// Carrega o perfil da sessão, executa o logout e gerencia as linhas
/// favoritas do passageiro.
class ProfileController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() {
    return ref.watch(getCurrentUserProvider).call();
  }

  /// Encerra a sessão do usuário (RF16).
  ///
  /// Retorna `true` em caso de sucesso, para a tela navegar ao Login.
  Future<bool> logout() async {
    try {
      await ref.read(logoutUserProvider).call();
      state = const AsyncValue<User?>.data(null);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('Erro no logout', error, stackTrace);
      state = AsyncValue<User?>.error(
        ErrorHandler.getUserMessage(error),
        stackTrace,
      );
      return false;
    }
  }

  /// Alterna uma linha como favorita do passageiro.
  Future<void> toggleFavoriteLine(String lineId) async {
    final User? user = state.valueOrNull;
    if (user is! Passenger) return;

    try {
      final List<String> updated = await ref.read(favoriteLineProvider).call(
            uid: user.uid,
            lineId: lineId,
            currentFavorites: user.favoriteLineIds,
          );
      state = AsyncValue<User?>.data(
        user.copyWith(favoriteLineIds: updated),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Erro ao favoritar linha', error, stackTrace);
      state = AsyncValue<User?>.error(
        ErrorHandler.getUserMessage(error),
        stackTrace,
      );
    }
  }
}

/// Provider do [ProfileController].
final AsyncNotifierProvider<ProfileController, User?>
    profileControllerProvider =
    AsyncNotifierProvider<ProfileController, User?>(ProfileController.new);
