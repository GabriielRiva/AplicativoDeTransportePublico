import '../../domain/entities/bus.dart';
import '../../domain/repositories/bus_repository.dart';
import '../datasources/bus_remote_datasource.dart';

/// Implementação de [BusRepository] via Realtime Database.
final class BusRepositoryImpl implements BusRepository {
  /// Cria a implementação recebendo o datasource de ônibus.
  const BusRepositoryImpl(this._datasource);

  final BusRemoteDatasource _datasource;

  @override
  Future<List<Bus>> getBuses() => _datasource.getBuses();

  @override
  Future<List<Bus>> getBusesByLine(String lineId) =>
      _datasource.getBusesByLine(lineId);

  @override
  Future<Bus> getBusById(String busId) => _datasource.getBusById(busId);
}
