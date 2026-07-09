import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/bus.dart';
import '../../domain/entities/enums/driver_status.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/trip.dart';
import '../providers/auth_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/service_providers.dart';
import '../providers/usecase_providers.dart';

/// Estado imutável do fluxo de trajeto do motorista.
class DriverTripState {
  /// Cria o estado do trajeto.
  const DriverTripState({
    this.status = DriverStatus.online,
    this.selectedLine,
    this.selectedBus,
    this.availableBuses = const <Bus>[],
    this.activeTrip,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Status atual do motorista.
  final DriverStatus status;

  /// Linha selecionada para o trajeto.
  final Line? selectedLine;

  /// Ônibus selecionado para o trajeto.
  final Bus? selectedBus;

  /// Ônibus disponíveis para a linha selecionada.
  final List<Bus> availableBuses;

  /// Trajeto ativo (nulo quando não há trajeto em andamento).
  final Trip? activeTrip;

  /// Indica operação em andamento (exibe Loading na tela).
  final bool isLoading;

  /// Mensagem de erro a exibir em Snackbar (nula quando não há erro).
  final String? errorMessage;

  /// Indica se o GPS está transmitindo ("GPS Ativo" na tela).
  bool get isTransmitting => status == DriverStatus.tripStarted;

  /// Indica se o botão Iniciar Trajeto pode ser acionado.
  bool get canStartTrip =>
      !isLoading && !isTransmitting && selectedLine != null &&
      selectedBus != null;

  /// Retorna uma cópia do estado alterando apenas os campos informados.
  DriverTripState copyWith({
    DriverStatus? status,
    Line? selectedLine,
    Bus? selectedBus,
    List<Bus>? availableBuses,
    Trip? activeTrip,
    bool? isLoading,
    String? errorMessage,
    bool clearBus = false,
    bool clearTrip = false,
    bool clearError = false,
  }) {
    return DriverTripState(
      status: status ?? this.status,
      selectedLine: selectedLine ?? this.selectedLine,
      selectedBus: clearBus ? null : (selectedBus ?? this.selectedBus),
      availableBuses: availableBuses ?? this.availableBuses,
      activeTrip: clearTrip ? null : (activeTrip ?? this.activeTrip),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ViewModel do perfil do motorista (RF04/RF05/RF06).
///
/// Orquestra a seleção de linha e ônibus, o início e o encerramento do
/// trajeto e o loop de transmissão de GPS a cada 5 segundos (RNF05).
class DriverTripController extends Notifier<DriverTripState> {
  StreamSubscription<Position>? _positionSubscription;

  @override
  DriverTripState build() {
    // Reinicia o fluxo de trajeto a cada mudança de sessão, evitando
    // que dados do motorista anterior permaneçam após um novo login.
    ref.watch(authStateProvider);
    ref.onDispose(_stopTransmission);
    return const DriverTripState();
  }

  /// Seleciona a linha do trajeto e carrega os ônibus disponíveis.
  Future<void> selectLine(Line line) async {
    state = state.copyWith(
      isLoading: true,
      selectedLine: line,
      clearBus: true,
      clearError: true,
    );
    try {
      final List<Bus> buses =
          await ref.read(getBusesByLineProvider).call(line.id);
      state = state.copyWith(
        isLoading: false,
        availableBuses: buses,
        status: DriverStatus.waiting,
      );
    } catch (error, stackTrace) {
      AppLogger.error('Erro ao carregar ônibus da linha', error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        availableBuses: const <Bus>[],
        errorMessage: ErrorHandler.getUserMessage(error),
      );
    }
  }

  /// Seleciona o ônibus do trajeto.
  void selectBus(Bus bus) {
    state = state.copyWith(selectedBus: bus, clearError: true);
  }

  /// Inicia o trajeto (RF04): valida GPS, grava o início no banco e
  /// abre a stream de transmissão de localização (RF05/RF06).
  Future<void> startTrip() async {
    final String? driverId =
        ref.read(authRepositoryProvider).currentUid;
    final Line? line = state.selectedLine;
    final Bus? bus = state.selectedBus;

    if (driverId == null) {
      state = state.copyWith(
        errorMessage: 'Sessão expirada. Faça login novamente.',
      );
      return;
    }
    if (line == null || bus == null) {
      state = state.copyWith(
        errorMessage: 'Selecione a linha e o ônibus antes de iniciar.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(permissionServiceProvider)
          .ensureLocationPermission();
      final Position position =
          await ref.read(locationServiceProvider).getCurrentPosition();

      final Trip trip = await ref.read(startTripProvider).call(
            driverId: driverId,
            lineId: line.id,
            busId: bus.id,
            initialLatitude: position.latitude,
            initialLongitude: position.longitude,
          );

      _startTransmission(driverId);
      state = state.copyWith(
        isLoading: false,
        status: DriverStatus.tripStarted,
        activeTrip: trip,
      );
      AppLogger.info('Trajeto iniciado na linha ${line.displayName}');
    } on AppException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
    } catch (error, stackTrace) {
      AppLogger.error('Erro ao iniciar trajeto', error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorHandler.getUserMessage(error),
      );
    }
  }

  /// Encerra o trajeto ativo (RF05), interrompendo a transmissão.
  Future<void> finishTrip() async {
    final String? driverId =
        ref.read(authRepositoryProvider).currentUid;
    if (driverId == null || !state.isTransmitting) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      _stopTransmission();
      await ref.read(finishTripProvider).call(driverId);
      state = state.copyWith(
        isLoading: false,
        status: DriverStatus.tripFinished,
        clearTrip: true,
      );
      AppLogger.info('Trajeto encerrado.');
    } catch (error, stackTrace) {
      AppLogger.error('Erro ao encerrar trajeto', error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        errorMessage: ErrorHandler.getUserMessage(error),
      );
    }
  }

  /// Limpa a mensagem de erro após exibição na tela.
  void clearError() => state = state.copyWith(clearError: true);

  void _startTransmission(String driverId) {
    _positionSubscription?.cancel();
    _positionSubscription = ref
        .read(locationServiceProvider)
        .watchPosition()
        .listen((Position position) async {
      try {
        await ref.read(sendLocationProvider).call(
              driverId: driverId,
              latitude: position.latitude,
              longitude: position.longitude,
            );
        final Trip? trip = state.activeTrip;
        if (trip != null) {
          state = state.copyWith(
            activeTrip: trip.copyWith(
              currentLatitude: position.latitude,
              currentLongitude: position.longitude,
            ),
          );
        }
      } catch (error, stackTrace) {
        // Falha pontual de transmissão não interrompe o trajeto.
        AppLogger.error('Falha ao transmitir posição', error, stackTrace);
      }
    });
  }

  void _stopTransmission() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}

/// Provider do [DriverTripController].
final NotifierProvider<DriverTripController, DriverTripState>
    driverTripControllerProvider =
    NotifierProvider<DriverTripController, DriverTripState>(
  DriverTripController.new,
);