import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/marker_icon_utils.dart';

/// Conjunto de ícones customizados usados nos mapas.
class MapMarkerIcons {
  /// Cria o conjunto de ícones.
  const MapMarkerIcons({
    required this.bus,
    required this.busTopDown,
    required this.stop,
  });

  /// Ícone circular do ônibus em circulação (mapa geral do passageiro).
  final BitmapDescriptor bus;

  /// Ônibus visto de cima, usado no trajeto ativo (motorista e
  /// acompanhamento da linha), girando com a direção da rua.
  final BitmapDescriptor busTopDown;

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
  final BitmapDescriptor busTopDown = await MarkerIconUtils.topDownBus(
    color: kSuccessColor,
  );
  final BitmapDescriptor stop = await MarkerIconUtils.fromIcon(
    icon: Icons.location_on,
    color: kPrimaryColor,
    size: 26,
  );
  return MapMarkerIcons(bus: bus, busTopDown: busTopDown, stop: stop);
});
