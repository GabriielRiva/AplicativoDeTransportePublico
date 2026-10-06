import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../domain/entities/stop.dart';
import '../../providers/map_icon_providers.dart';
import 'stop_placement.dart';

/// Marcadores dos pontos de parada (abrigo 3D na calçada, de frente para a
/// rua), compartilhados pelos mapas do motorista e do passageiro.
abstract final class StopMarkers {
  /// Marcador do abrigo da parada [stop], desenhado conforme [display].
  /// [cameraBearing] é para onde a câmera do mapa aponta (0 = norte).
  static Marker of({
    required String id,
    required Stop stop,
    required StopDisplay display,
    MapMarkerIcons? icons,
    double cameraBearing = 0,
    String? snippet,
    double zIndex = 0,
  }) {
    return Marker(
      markerId: MarkerId('stop_$id'),
      position: display.position,
      zIndex: zIndex,
      anchor: icons?.stopAnchor ?? const Offset(0.5, 1),
      icon: icons?.stopFacing(display.facing, cameraBearing: cameraBearing) ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(title: stop.name, snippet: snippet),
    );
  }

  /// Abrigos de todas as [stops] de uma linha, ao lado do traçado [route].
  static Set<Marker> forLine(
    List<Stop> stops,
    List<LatLng> route,
    MapMarkerIcons? icons, {
    double cameraBearing = 0,
  }) {
    return stops.map((Stop stop) {
      return of(
        id: stop.id,
        stop: stop,
        display: StopPlacement.roadside(
          LatLng(stop.latitude, stop.longitude),
          route,
        ),
        icons: icons,
        cameraBearing: cameraBearing,
      );
    }).toSet();
  }
}
