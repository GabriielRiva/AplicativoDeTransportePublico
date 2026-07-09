import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trip.dart';
import 'auth_providers.dart';
import 'usecase_providers.dart';

/// Stream em tempo real dos ônibus em circulação (RF07/RF12/RF18).
///
/// Observa a sessão para recriar a stream a cada login/logout,
/// evitando que um erro de permissão pós-logout fique retido.
final StreamProvider<List<Trip>> activeBusesProvider =
    StreamProvider<List<Trip>>((Ref ref) {
  ref.watch(authStateProvider);
  return ref.watch(watchActiveBusesProvider).call();
});