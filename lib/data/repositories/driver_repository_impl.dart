import '../../domain/entities/enums/driver_status.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_remote_datasource.dart';
import '../models/trip_model.dart';

/// Implementação de [DriverRepository] via Realtime Database.
final class DriverRepositoryImpl implements DriverRepository {
  /// Cria a implementação recebendo o datasource do motorista.
  const DriverRepositoryImpl(this._datasource);

  final DriverRemoteDatasource _datasource;

  @override
  Future<void> startTrip(Trip trip) {
    final TripModel model = TripModel(
      id: trip.id,
      driverId: trip.driverId,
      busId: trip.busId,
      lineId: trip.lineId,
      startedAt: trip.startedAt,
      status: trip.status,
      currentLatitude: trip.currentLatitude,
      currentLongitude: trip.currentLongitude,
      finishedAt: trip.finishedAt,
    );
    return _datasource.startTrip(model);
  }

  @override
  Future<void> finishTrip(String driverId) =>
      _datasource.finishTrip(driverId);

  @override
  Future<void> sendLocation({
    required String driverId,
    required double latitude,
    required double longitude,
  }) {
    return _datasource.sendLocation(
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<void> updateStatus(String driverId, DriverStatus status) =>
      _datasource.updateStatus(driverId, status);

  @override
  Stream<List<Trip>> watchActiveDrivers() => _datasource.watchDrivers();
}
