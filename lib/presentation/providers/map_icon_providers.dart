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

/// Abrigo de ônibus 3D usado como marcador dos pontos de parada.
const String kStop3dAsset = 'assets/images/bus_stop_3d.png';

/// Ponto da imagem [kStop3dAsset] que fica sobre a coordenada da parada
/// (o centro do abrigo no chão).
const Offset kStop3dAnchor = Offset(0.41, 0.74);

/// Quantidade de ângulos em que o ônibus 3D foi renderizado para os mapas
/// do passageiro (um a cada 22,5°).
const int kBusDirectionCount = 16;

/// Imagem do ônibus 3D virado para o ângulo [index] × 22,5° (0 = indo para
/// o norte, visto de trás; 4 = indo para o leste; ...), vista por uma câmera
/// inclinada 45° olhando para o norte. O centro do ônibus no chão fica no
/// centro da imagem.
String busDirectionAsset(int index) =>
    'assets/images/bus_dir/bus_${index.toString().padLeft(2, '0')}.png';

/// Conjunto de ícones customizados usados nos mapas.
class MapMarkerIcons {
  /// Cria o conjunto de ícones.
  const MapMarkerIcons({
    required this.bus,
    required this.bus3d,
    required this.busDirections,
    required this.stop,
  });

  /// Ícone circular do ônibus (reserva, caso o 3D não carregue).
  final BitmapDescriptor bus;

  /// Ônibus 3D visto de trás, no mesmo ângulo da câmera inclinada de
  /// navegação (que sempre gira junto com o ônibus).
  final BitmapDescriptor bus3d;

  /// Ônibus 3D em [kBusDirectionCount] direções, para mapas que não giram
  /// junto com o ônibus (mapa inicial e detalhes da linha do passageiro).
  final List<BitmapDescriptor> busDirections;

  /// Abrigo de ônibus 3D dos pontos de parada (âncora: [stopAnchor]).
  final BitmapDescriptor stop;

  /// Âncora do ícone [stop].
  Offset get stopAnchor => kStop3dAnchor;

  /// Ônibus 3D virado para [heading] (graus, 0 = norte), num mapa cuja
  /// câmera aponta para [cameraBearing].
  BitmapDescriptor busFacing(double heading, {double cameraBearing = 0}) {
    final double relative = ((heading - cameraBearing) % 360 + 360) % 360;
    final double step = 360 / busDirections.length;
    final int index = (relative / step).round() % busDirections.length;
    return busDirections[index];
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
  final BitmapDescriptor stop = await MarkerIconUtils.fromAsset(
    kStop3dAsset,
    width: 40,
  );
  return MapMarkerIcons(
    bus: bus,
    bus3d: bus3d,
    busDirections: busDirections,
    stop: stop,
  );
});
