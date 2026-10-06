import '../../../core/constants/app_constants.dart';
import '../../entities/trip.dart';
import '../../repositories/driver_repository.dart';

/// Observa os ônibus em circulação em tempo real (RF07/RF12/RF18).
///
/// Filtra a stream do nó drivers/ mantendo apenas trajetos com status
/// trip_started, que são os veículos efetivamente transmitindo GPS.
class WatchActiveBuses {
  /// Cria o usecase com o repositório do motorista.
  const WatchActiveBuses(this._driverRepository);

  final DriverRepository _driverRepository;

  /// Stream com a lista de trajetos ativos, emitida a cada atualização.
  Stream<List<Trip>> call() {
    return _driverRepository.watchActiveDrivers().map(
          (List<Trip> trips) =>
              trips.where((Trip trip) => trip.status.isActive).toList(),
        );
  }

  /// Remove os ônibus sem posição nova há mais de [maxAge] em relação a
  /// [now] ("ônibus fantasma": o app do motorista fechou, ficou sem
  /// bateria ou sem sinal sem encerrar o trajeto). Trajetos ainda sem
  /// horário de atualização são mantidos.
  static List<Trip> withoutStale(
    List<Trip> trips,
    DateTime now, {
    Duration maxAge = kBusStaleAfter,
  }) {
    return trips.where((Trip trip) {
      final DateTime? updatedAt = trip.updatedAt;
      return updatedAt == null || now.difference(updatedAt) <= maxAge;
    }).toList();
  }
}
