import 'package:geolocator/geolocator.dart';

import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

/// Serviço de acesso ao GPS do dispositivo via Geolocator.
///
/// Toda captura de coordenadas do TranCity passa por esta classe. A leitura
/// é feita a cada [kGpsSampleInterval]; o limite de envio do RNF05
/// (5 segundos) é aplicado por quem transmite a posição.
class LocationService {
  static final LocationSettings _trackingSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    intervalDuration: kGpsSampleInterval,
    distanceFilter: 0,
  );

  static const LocationSettings _passengerSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: kPassengerDistanceFilterMeters,
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
  /// emitindo novas coordenadas a cada [kGpsSampleInterval].
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(locationSettings: _trackingSettings);
  }

  /// Stream de posições do passageiro: só emite quando ele se desloca pelo
  /// menos [kPassengerDistanceFilterMeters] metros, economizando bateria.
  Stream<Position> watchUserPosition() {
    return Geolocator.getPositionStream(locationSettings: _passengerSettings);
  }
}
