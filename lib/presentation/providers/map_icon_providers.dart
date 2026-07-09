import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/marker_icon_utils.dart';

/// Conjunto de ícones customizados usados nos mapas.
class MapMarkerIcons {
  /// Cria o conjunto de ícones.
  const MapMarkerIcons({required this.bus, required this.stop});

  /// Ícone do ônibus em circulação (verde).
  final BitmapDescriptor bus;

  /// Ícone das paradas da rota (menor, cor primária).
  final BitmapDescriptor stop;
}

/// Carrega os ícones uma única vez para reuso em todas as telas de mapa.
final FutureProvider<MapMarkerIcons> markerIconsProvider =
    FutureProvider<MapMarkerIcons>((Ref ref) async {
  final BitmapDescriptor bus = await MarkerIconUtils.fromIcon(
    icon: Icons.directions_bus,
    color: kSuccessColor,
  );
  final BitmapDescriptor stop = await MarkerIconUtils.fromIcon(
    icon: Icons.location_on,
    color: kPrimaryColor,
    size: 64,
  );
  return MapMarkerIcons(bus: bus, stop: stop);
});