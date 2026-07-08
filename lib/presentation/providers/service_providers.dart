import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/network/network_info.dart';
import '../../core/services/location_service.dart';
import '../../core/services/permission_service.dart';

/// Serviço de acesso ao GPS do dispositivo.
final Provider<LocationService> locationServiceProvider =
    Provider<LocationService>((Ref ref) => LocationService());

/// Serviço de permissões de localização.
final Provider<PermissionService> permissionServiceProvider =
    Provider<PermissionService>((Ref ref) => PermissionService());

/// Verificador de conectividade.
final Provider<NetworkInfo> networkInfoProvider =
    Provider<NetworkInfo>((Ref ref) => NetworkInfoImpl(Connectivity()));

/// Posição atual do usuário, obtida após garantir a permissão de GPS.
///
/// Usada pelo mapa do passageiro para centralizar a câmera e calcular
/// a lista de ônibus próximos (RF13).
final FutureProvider<Position> userPositionProvider =
    FutureProvider<Position>((Ref ref) async {
  await ref.watch(permissionServiceProvider).ensureLocationPermission();
  return ref.watch(locationServiceProvider).getCurrentPosition();
});
