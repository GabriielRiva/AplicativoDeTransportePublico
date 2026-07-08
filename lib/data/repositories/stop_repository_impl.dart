import '../../domain/entities/stop.dart';
import '../../domain/repositories/stop_repository.dart';
import '../datasources/stop_remote_datasource.dart';

/// Implementação de [StopRepository] via Realtime Database.
final class StopRepositoryImpl implements StopRepository {
  /// Cria a implementação recebendo o datasource de paradas.
  const StopRepositoryImpl(this._datasource);

  final StopRemoteDatasource _datasource;

  @override
  Future<List<Stop>> getStopsByLine(String lineId) =>
      _datasource.getStopsByLine(lineId);
}
