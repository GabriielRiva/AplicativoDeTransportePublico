import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/marker_icon_utils.dart';

/// Imagem do ônibus 3D visto de trás, usada no trajeto do motorista.
const String kBus3dAsset = 'assets/images/bus_3d.png';

/// Ponto da imagem [kBus3dAsset] que fica sobre a posição do GPS: o centro
/// do ônibus no chão (calculado na renderização do modelo 3D).
const Offset kBus3dAnchor = Offset(0.5, 0.66);

/// Conjunto de ícones customizados usados nos mapas.
class MapMarkerIcons {
  /// Cria o conjunto de ícones.
  const MapMarkerIcons({
    required this.bus,
    required this.bus3d,
    required this.stop,
  });

  /// Ícone circular do ônibus em circulação (telas do passageiro).
  final BitmapDescriptor bus;

  /// Ônibus 3D visto de trás, no mesmo ângulo da câmera inclinada do
  /// motorista (que sempre gira junto com o ônibus).
  final BitmapDescriptor bus3d;

  /// Ícone das paradas da rota (menor, cor primária).
  final BitmapDescriptor stop;
}

/// Carrega os ícones uma única vez para reuso em todas as telas de mapa.
final FutureProvider<MapMarkerIcons> markerIconsProvider =
    FutureProvider<MapMarkerIcons>((Ref ref) async {
  final BitmapDescriptor bus = await MarkerIconUtils.fromIcon(
    icon: Icons.directions_bus,
    color: kSuccessColor,
    size: 40,
  );
  final BitmapDescriptor bus3d = await MarkerIconUtils.fromAsset(
    kBus3dAsset,
    width: 40,
  );
  final BitmapDescriptor stop = await MarkerIconUtils.fromIcon(
    icon: Icons.location_on,
    color: kPrimaryColor,
    size: 26,
  );
  return MapMarkerIcons(bus: bus, bus3d: bus3d, stop: stop);
});
