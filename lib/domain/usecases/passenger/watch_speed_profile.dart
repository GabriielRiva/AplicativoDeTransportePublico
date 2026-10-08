import '../../entities/speed_profile.dart';
import '../../repositories/speed_profile_repository.dart';

/// Observa o perfil de velocidades por faixa de horário, usado nas
/// estimativas de tempo (horário previsto e tempo de chegada).
class WatchSpeedProfile {
  /// Cria o usecase com o repositório do perfil.
  const WatchSpeedProfile(this._repository);

  final SpeedProfileRepository _repository;

  /// Stream do perfil, emitida a cada alteração no Firebase.
  Stream<SpeedProfile> call() => _repository.watchSpeedProfile();
}
