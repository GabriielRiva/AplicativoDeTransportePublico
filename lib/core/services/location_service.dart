import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

/// Serviço de acesso ao GPS do dispositivo via Geolocator.
///
/// Toda captura de coordenadas do TranCity passa por esta classe,
/// que aplica o intervalo de atualização definido pelo RNF05 (5 segundos).
class LocationService {
  static final LocationSettings _trackingSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    intervalDuration: kGpsUpdateInterval,
    distanceFilter: 0,
  );

  /// Obtém a posição atual do dispositivo uma única vez.
  Future<Position> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Falha ao obter posição atual', error, stackTrace);
      throw const LocationException(
        'Não foi possível obter sua localização atual.',
      );
    }
  }

  /// Stream contínua de posições usada durante um trajeto ativo,
  /// emitindo novas coordenadas a cada [kGpsUpdateInterval].
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(locationSettings: _trackingSettings);
  }
}
