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

/// Quantidade de ângulos em que o abrigo 3D das paradas foi renderizado
/// (um a cada 22,5°).
const int kStopDirectionCount = 16;

/// Abrigo 3D com a frente aberta virada para o rumo [index] × 22,5° (0 =
/// norte, 4 = leste, 8 = sul, ...), visto por uma câmera inclinada 45°
/// olhando para o norte.
String stopDirectionAsset(int index) =>
    'assets/images/stop_dir/stop_${index.toString().padLeft(2, '0')}.png';

/// Ponto das imagens [stopDirectionAsset] que fica sobre a posição da
/// parada: o centro do abrigo no chão (igual em todos os ângulos).
const Offset kStop3dAnchor = Offset(0.435, 0.705);

/// Quantidade de ângulos em que o ônibus 3D foi renderizado para os mapas
/// do passageiro (um a cada 22,5°).
const int kBusDirectionCount = 16;

/// Imagem do ônibus 3D virado para o ângulo [index] × 22,5° (0 = indo para
/// o norte, visto de trás; 4 = indo para o leste; ...), vista por uma câmera
/// inclinada 45° olhando para o norte. O centro do ônibus no chão fica no
/// centro da imagem.
String busDirectionAsset(int index) =>
    'assets/images/bus_dir/bus_${index.toString().padLeft(2, '0')}.png';

/// Imagem [busDirectionAsset] do ônibus indo para [heading] (graus, 0 =
/// norte), vista por uma câmera virada para [cameraBearing].
String busDirectionAssetFor(double heading, {double cameraBearing = 0}) {
  final double relative = ((heading - cameraBearing) % 360 + 360) % 360;
  final double step = 360 / kBusDirectionCount;
  return busDirectionAsset((relative / step).round() % kBusDirectionCount);
}

/// Conjunto de ícones customizados usados nos mapas.
class MapMarkerIcons {
  /// Cria o conjunto de ícones.
  const MapMarkerIcons({
    required this.bus,
    required this.bus3d,
    required this.busDirections,
    required this.stopDirections,
  });

  /// Ícone circular do ônibus (reserva, caso o 3D não carregue).
  final BitmapDescriptor bus;

  /// Ônibus 3D visto de trás, no mesmo ângulo da câmera inclinada de
  /// navegação (que sempre gira junto com o ônibus).
  final BitmapDescriptor bus3d;

  /// Ônibus 3D em [kBusDirectionCount] direções, para mapas que não giram
  /// junto com o ônibus (mapa inicial e detalhes da linha do passageiro).
  final List<BitmapDescriptor> busDirections;

  /// Abrigo 3D das paradas em [kStopDirectionCount] direções (âncora:
  /// [stopAnchor]).
  final List<BitmapDescriptor> stopDirections;

  /// Âncora dos ícones de parada.
  Offset get stopAnchor => kStop3dAnchor;

  /// Abrigo com a frente aberta virada para [facing] (graus, 0 = norte),
  /// num mapa cuja câmera aponta para [cameraBearing]. Com a frente virada
  /// para a rua, o abrigo fica de lado, alinhado com a calçada.
  BitmapDescriptor stopFacing(double facing, {double cameraBearing = 0}) =>
      _facing(stopDirections, facing, cameraBearing);

  /// Ônibus 3D virado para [heading] (graus, 0 = norte), num mapa cuja
  /// câmera aponta para [cameraBearing].
  BitmapDescriptor busFacing(double heading, {double cameraBearing = 0}) =>
      _facing(busDirections, heading, cameraBearing);

  /// Imagem de [images] (renderizadas a cada 360 / length graus) mais
  /// próxima do rumo [angle] visto por uma câmera virada para [bearing].
  static BitmapDescriptor _facing(
    List<BitmapDescriptor> images,
    double angle,
    double bearing,
  ) {
    final double relative = ((angle - bearing) % 360 + 360) % 360;
    final double step = 360 / images.length;
    final int index = (relative / step).round() % images.length;
    return images[index];
  }
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
  final List<BitmapDescriptor> busDirections =
      await Future.wait<BitmapDescriptor>(
    List<Future<BitmapDescriptor>>.generate(
      kBusDirectionCount,
      (int index) =>
          MarkerIconUtils.fromAsset(busDirectionAsset(index), width: 56),
    ),
  );
  final List<BitmapDescriptor> stopDirections =
      await Future.wait<BitmapDescriptor>(
    List<Future<BitmapDescriptor>>.generate(
      kStopDirectionCount,
      (int index) =>
          MarkerIconUtils.fromAsset(stopDirectionAsset(index), width: 28),
    ),
  );
  return MapMarkerIcons(
    bus: bus,
    bus3d: bus3d,
    busDirections: busDirections,
    stopDirections: stopDirections,
  );
});
