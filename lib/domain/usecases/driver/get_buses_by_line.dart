import '../../entities/bus.dart';
import '../../repositories/bus_repository.dart';

/// Lista os ônibus disponíveis para uma linha, usada pelo motorista
/// ao selecionar o veículo antes de iniciar o trajeto (UI_SPEC).
class GetBusesByLine {
  /// Cria o usecase com o repositório de ônibus.
  const GetBusesByLine(this._busRepository);

  final BusRepository _busRepository;

  /// Retorna os ônibus vinculados à [lineId].
  Future<List<Bus>> call(String lineId) =>
      _busRepository.getBusesByLine(lineId);
}
