import 'package:geolocator/geolocator.dart';

import '../errors/app_exception.dart';

/// Serviço responsável por permissões e disponibilidade do GPS.
class PermissionService {
  /// Garante que o serviço de localização está ligado e que o app possui
  /// permissão de acesso ao GPS. Lança [LocationException] caso contrário.
  Future<void> ensureLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'O GPS do dispositivo está desligado. Ative a localização.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Permissão de localização negada. Autorize o acesso ao GPS.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Permissão de localização negada permanentemente. '
        'Autorize o GPS nas configurações do aparelho.',
      );
    }
  }
}
