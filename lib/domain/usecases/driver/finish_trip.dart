import '../../repositories/driver_repository.dart';

/// Encerra o trajeto ativo do motorista (RF05), interrompendo a
/// transmissão de GPS e atualizando o status para trip_finished.
class FinishTrip {
  /// Cria o usecase com o repositório do motorista.
  const FinishTrip(this._driverRepository);

  final DriverRepository _driverRepository;

  /// Executa o encerramento do trajeto do [driverId].
  Future<void> call(String driverId) =>
      _driverRepository.finishTrip(driverId);
}
