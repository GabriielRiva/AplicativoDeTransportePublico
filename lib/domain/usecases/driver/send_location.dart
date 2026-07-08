import '../../../core/errors/app_exception.dart';
import '../../repositories/driver_repository.dart';

/// Transmite a posição atual do motorista (RF06), sobrescrevendo as
/// coordenadas no nó drivers/{uid} a cada 5 segundos (RNF05).
class SendLocation {
  /// Cria o usecase com o repositório do motorista.
  const SendLocation(this._driverRepository);

  final DriverRepository _driverRepository;

  /// Grava a nova posição do veículo, validando as coordenadas.
  Future<void> call({
    required String driverId,
    required double latitude,
    required double longitude,
  }) async {
    if (latitude < -90 || latitude > 90 || longitude < -180 ||
        longitude > 180) {
      throw const LocationException('Coordenadas GPS inválidas.');
    }
    await _driverRepository.sendLocation(
      driverId: driverId,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
