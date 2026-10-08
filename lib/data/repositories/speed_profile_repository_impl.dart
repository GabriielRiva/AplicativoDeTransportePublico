import '../../domain/entities/speed_profile.dart';
import '../../domain/repositories/speed_profile_repository.dart';
import '../datasources/speed_profile_remote_datasource.dart';

/// Implementação de [SpeedProfileRepository] via Realtime Database.
final class SpeedProfileRepositoryImpl implements SpeedProfileRepository {
  /// Cria a implementação recebendo o datasource do perfil.
  const SpeedProfileRepositoryImpl(this._datasource);

  final SpeedProfileRemoteDatasource _datasource;

  @override
  Stream<SpeedProfile> watchSpeedProfile() => _datasource.watchSpeedProfile();
}
