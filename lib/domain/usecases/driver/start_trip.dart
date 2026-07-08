import '../../../core/errors/app_exception.dart';
import '../../../core/network/network_info.dart';
import '../../entities/enums/driver_status.dart';
import '../../entities/trip.dart';
import '../../repositories/driver_repository.dart';

/// Inicia um trajeto do motorista (RF04).
///
/// Regra de negócio: exige linha e ônibus selecionados, conexão com a
/// internet e a posição inicial do veículo antes de gravar o status
/// trip_started no Realtime Database.
class StartTrip {
  /// Cria o usecase com as dependências necessárias.
  const StartTrip(this._driverRepository, this._networkInfo);

  final DriverRepository _driverRepository;
  final NetworkInfo _networkInfo;

  /// Executa o início do trajeto e retorna o [Trip] criado.
  Future<Trip> call({
    required String driverId,
    required String lineId,
    required String busId,
    required double initialLatitude,
    required double initialLongitude,
  }) async {
    if (lineId.isEmpty) {
      throw const ValidationException(
        'Selecione uma linha antes de iniciar o trajeto.',
      );
    }
    if (busId.isEmpty) {
      throw const ValidationException(
        'Selecione um ônibus antes de iniciar o trajeto.',
      );
    }
    if (!await _networkInfo.isConnected) {
      throw const NetworkException(
        'Sem conexão com a internet. Conecte-se para iniciar o trajeto.',
      );
    }

    final Trip trip = Trip(
      id: driverId,
      driverId: driverId,
      busId: busId,
      lineId: lineId,
      startedAt: DateTime.now(),
      status: DriverStatus.tripStarted,
      currentLatitude: initialLatitude,
      currentLongitude: initialLongitude,
    );

    await _driverRepository.startTrip(trip);
    return trip;
  }
}
