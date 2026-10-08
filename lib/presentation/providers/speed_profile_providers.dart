import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/speed_profile.dart';
import 'auth_providers.dart';
import 'usecase_providers.dart';

/// Perfil de velocidades por faixa de horário, em tempo real (alterar o nó
/// speedProfile no Firebase atualiza as estimativas sem novo APK).
///
/// Quem lê usa `valueOrNull ?? SpeedProfile.fallback`, então as
/// estimativas funcionam mesmo antes de o perfil carregar.
final StreamProvider<SpeedProfile> speedProfileProvider =
    StreamProvider<SpeedProfile>((Ref ref) {
  // Recria a leitura a cada login/logout (o nó exige usuário logado).
  ref.watch(authStateProvider);
  return ref.watch(watchSpeedProfileProvider).call();
});
