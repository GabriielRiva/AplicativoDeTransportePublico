import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trip.dart';
import 'usecase_providers.dart';

/// Stream em tempo real dos ônibus em circulação (RF07/RF12/RF18).
///
/// Cada alteração no nó drivers/ do Realtime Database emite uma nova
/// lista de trajetos ativos, sem intervenção do usuário.
final StreamProvider<List<Trip>> activeBusesProvider =
    StreamProvider<List<Trip>>((Ref ref) {
  return ref.watch(watchActiveBusesProvider).call();
});
