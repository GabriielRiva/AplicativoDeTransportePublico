import '../entities/speed_profile.dart';

/// Contrato de consulta do perfil de velocidades (nó speedProfile/).
abstract interface class SpeedProfileRepository {
  /// Stream do perfil; sem o nó no banco, emite [SpeedProfile.fallback].
  Stream<SpeedProfile> watchSpeedProfile();
}
