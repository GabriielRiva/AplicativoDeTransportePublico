import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modos de apresentação do mapa de trajeto ativo, espelhando as duas
/// experiências do Uber: navegação turn-by-turn para o motorista e
/// acompanhamento (tracking) visto de cima para o passageiro.
enum TripMode { driver, passenger }

/// Configurações de câmera de cada [TripMode]. Centralizadas aqui para que
/// as telas do motorista e do passageiro nunca dupliquem a lógica de câmera.
abstract final class TripCameraConfig {
  static const double _driverZoom = 18.5;
  static const double _passengerZoom = 15;
  /// Mesma inclinação usada para renderizar o ônibus 3D (assets/images),
  /// para o desenho combinar com a perspectiva do mapa.
  static const double _driverTilt = 50;

  /// Monta a câmera para o [mode] centrada em [position]. [heading] é o
  /// rumo (bearing) em graus (0-360); só gira o mapa no modo motorista.
  static CameraPosition forMode(
    TripMode mode, {
    required LatLng position,
    double heading = 0,
  }) {
    switch (mode) {
      case TripMode.driver:
        return CameraPosition(
          target: position,
          zoom: _driverZoom,
          tilt: _driverTilt,
          bearing: heading,
        );
      case TripMode.passenger:
        return CameraPosition(
          target: position,
          zoom: _passengerZoom,
          tilt: 0,
          bearing: 0,
        );
    }
  }
}
