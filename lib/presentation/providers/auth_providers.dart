import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user.dart';
import 'usecase_providers.dart';

/// Stream com o UID da sessão atual (nulo quando deslogado) — RF20.
final StreamProvider<String?> authStateProvider =
    StreamProvider<String?>((Ref ref) {
  return ref.watch(watchAuthStateProvider).call();
});

/// Perfil do usuário autenticado, recarregado a cada mudança de sessão.
///
/// Retorna [Driver] ou [Passenger], base do redirecionamento por
/// perfil (RF03), ou nulo quando não há sessão ativa.
final FutureProvider<User?> currentUserProfileProvider =
    FutureProvider<User?>((Ref ref) async {
  // Observa a sessão para invalidar o perfil em login/logout.
  ref.watch(authStateProvider);
  return ref.watch(getCurrentUserProvider).call();
});
