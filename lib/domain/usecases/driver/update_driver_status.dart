import '../../entities/enums/driver_status.dart';
import '../../repositories/driver_repository.dart';

/// Atualiza o status do motorista (online, aguardando, em trajeto...).
class UpdateDriverStatus {
  /// Cria o usecase com o repositório do motorista.
  const UpdateDriverStatus(this._driverRepository);

  final DriverRepository _driverRepository;

  /// Grava o novo [status] do [driverId].
  Future<void> call(String driverId, DriverStatus status) =>
      _driverRepository.updateStatus(driverId, status);
}
