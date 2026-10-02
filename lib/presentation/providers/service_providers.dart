import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_constants.dart';
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

/// Posição do usuário em tempo real, após garantir a permissão de GPS.
///
/// Emite a posição atual assim que o GPS responde e, depois, uma nova a
/// cada deslocamento de [kPassengerDistanceFilterMeters] metros. Usada pelo
/// mapa do passageiro para centralizar a câmera e manter a lista de ônibus
/// próximos atualizada (RF13). Fica só no aparelho: não vai ao Firebase.
final StreamProvider<Position> userPositionProvider =
    StreamProvider<Position>((Ref ref) async* {
  await ref.watch(permissionServiceProvider).ensureLocationPermission();
  final LocationService location = ref.watch(locationServiceProvider);
  yield await location.getCurrentPosition();
  yield* location.watchUserPosition();
});
