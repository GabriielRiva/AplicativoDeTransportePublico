import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trancity/presentation/widgets/map/trip_camera_config.dart';

void main() {
  const LatLng position = LatLng(-27.1004, -52.6152);

  group('TripCameraConfig.forMode — motorista (chase-cam)', () {
    test('inclina e gira a câmera conforme o heading do GPS', () {
      final CameraPosition camera = TripCameraConfig.forMode(
        TripMode.driver,
        position: position,
        heading: 128,
      );

      expect(camera.target, position);
      expect(camera.tilt, 60);
      expect(camera.bearing, 128);
      expect(camera.zoom, 18.5);
    });
  });

  group('TripCameraConfig.forMode — passageiro (tracking)', () {
    test('mantém vista de cima e ignora o heading recebido', () {
      final CameraPosition camera = TripCameraConfig.forMode(
        TripMode.passenger,
        position: position,
        heading: 128,
      );

      expect(camera.target, position);
      expect(camera.tilt, 0);
      expect(camera.bearing, 0);
      expect(camera.zoom, 16);
    });

    test('heading tem valor padrão zero quando omitido', () {
      final CameraPosition camera = TripCameraConfig.forMode(
        TripMode.passenger,
        position: position,
      );

      expect(camera.bearing, 0);
    });
  });
}
