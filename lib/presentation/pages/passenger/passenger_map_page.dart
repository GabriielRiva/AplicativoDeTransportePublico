import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/map_constants.dart';
import '../../../core/errors/error_handler.dart';
import '../../../domain/entities/line.dart';
import '../../../domain/entities/trip.dart';
import '../../../domain/usecases/passenger/get_nearby_buses.dart';
import '../../controllers/lines_controller.dart';
import '../../controllers/passenger_map_controller.dart';
import '../../providers/map_icon_providers.dart';
import '../../providers/service_providers.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_logo.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/map/bus_map.dart';
import '../../widgets/map/nearby_buses_sheet.dart';
import '../../widgets/map/selected_bus_card.dart';
import '../../widgets/map/trip_camera_config.dart';
import '../../widgets/map/trip_map_view.dart';

/// Tela inicial do passageiro (RF06 do TCC / RF07, RF12, RF13, RF18).
///
/// Visão geral: mapa inclinado com prédios em 3D, os ônibus em tempo real
/// (ícone 3D virado na direção em que andam), os pontos de parada e a lista
/// de ônibus próximos. Ao tocar em um ônibus, o mapa passa a acompanhá-lo
/// como na tela do motorista: câmera atrás do ônibus, girando com a rua, e
/// o trajeto que ele ainda vai percorrer.
class PassengerMapPage extends ConsumerStatefulWidget {
  /// Cria a tela do mapa do passageiro.
  const PassengerMapPage({super.key});

  @override
  ConsumerState<PassengerMapPage> createState() => _PassengerMapPageState();
}

class _PassengerMapPageState extends ConsumerState<PassengerMapPage> {
  /// Inclinação da visão geral: a mesma usada para renderizar o ônibus 3D
  /// em várias direções (assets/images/bus_dir).
  static const double _overviewTilt = 45;

  /// Zoom da visão geral: a partir de 17 o Google Maps mostra os prédios.
  static const double _overviewZoom = 17;

  GoogleMapController? _mapController;
  bool _centeredOnUser = false;

  void _centerOnUser(LatLng position) {
    if (_centeredOnUser || _mapController == null) return;
    _centeredOnUser = true;
    _mapController!.animateCamera(CameraUpdate.newLatLng(position));
  }

  Future<void> _openLineDetails(Line line) async {
    // A tela de detalhes lê paradas e horários do LinesController.
    await ref.read(linesControllerProvider.future);
    ref.read(linesControllerProvider.notifier).selectLine(line);
    if (!mounted) return;
    Navigator.of(context).pushNamed(kLineDetailsRoute, arguments: line);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Position>>(userPositionProvider,
        (AsyncValue<Position>? previous, AsyncValue<Position> next) {
      if (next.hasError && !next.isLoading) {
        AppSnackbar.showError(
          context,
          ErrorHandler.getUserMessage(next.error!),
        );
      }
      final Position? position = next.valueOrNull;
      if (position != null) {
        _centerOnUser(LatLng(position.latitude, position.longitude));
      }
    });

    final PassengerMapState state =
        ref.watch(passengerMapControllerProvider);
    final PassengerMapController controller =
        ref.read(passengerMapControllerProvider.notifier);
    final MapMarkerIcons? icons =
        ref.watch(markerIconsProvider).valueOrNull;
    final Trip? selectedTrip = state.selectedTrip;
    final Line? selectedLine = state.selectedLine;

    return LoadingOverlay(
      isLoading: state.isLoading,
      child: Stack(
        children: <Widget>[
          if (selectedTrip != null && selectedLine != null)
            // Acompanhamento do ônibus selecionado, igual à tela do
            // motorista.
            TripMapView(
              key: ValueKey<String>('follow_${selectedTrip.id}'),
              mode: TripMode.driver,
              busPosition: LatLng(
                selectedTrip.currentLatitude,
                selectedTrip.currentLongitude,
              ),
              route: state.selectedRoute,
              extraMarkers: state.stopMarkers,
              busIcon: icons?.bus3d,
              rotateBusIcon: false,
              busIconAnchor: kBus3dAnchor,
              showMyLocation: true,
              interpolationDuration: kGpsUpdateInterval,
              mapPadding: EdgeInsets.only(
                top: MediaQuery.sizeOf(context).height * 0.30,
                bottom: 280,
              ),
            )
          else
            BusMap(
              markers: state.markers,
              initialTarget: state.userPosition ?? kChapecoCenter,
              initialZoom: _overviewZoom,
              initialTilt: _overviewTilt,
              // A visão geral fica sempre apontando para o norte e com a
              // mesma inclinação, para o ícone 3D de cada ônibus ficar
              // coerente com a direção em que ele anda.
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              onMapCreated: (GoogleMapController mapController) {
                _mapController = mapController;
                // O mapa já abre centrado no passageiro quando a posição
                // é conhecida.
                _centeredOnUser = state.userPosition != null;
              },
              onTap: (_) => controller.clearSelection(),
            ),
          if (selectedTrip == null || selectedLine == null)
            const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: AppLogo(fontSize: 28),
              ),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: selectedTrip != null && selectedLine != null
                ? SelectedBusCard(
                    line: selectedLine,
                    etaMinutes: state.selectedEtaMinutes,
                    stopName: state.selectedStopHere?.name,
                    onClose: () {
                      _mapController = null;
                      controller.clearSelection();
                    },
                    onOpenDetails: () => _openLineDetails(selectedLine),
                  )
                : NearbyBusesSheet(
                    buses: state.nearbyBuses,
                    onSelect: (NearbyBus bus) =>
                        controller.selectBus(bus.trip.id),
                  ),
          ),
        ],
      ),
    );
  }
}
