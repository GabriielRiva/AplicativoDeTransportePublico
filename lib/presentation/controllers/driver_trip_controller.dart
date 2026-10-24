import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/map_utils.dart';
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
    this.heading = 0,
    this.isLoading = false,
    this.isOnline = true,
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

  /// Rumo (bearing) mais recente do GPS em graus, usado para orientar a
  /// câmera turn-by-turn e o marcador do ônibus.
  final double heading;

  /// Indica operação em andamento (exibe Loading na tela).
  final bool isLoading;

  /// Indica se o aparelho está conectado ao Firebase durante o trajeto.
  /// Sem conexão, o ônibus aparece offline para os passageiros.
  final bool isOnline;

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
    double? heading,
    bool? isLoading,
    bool? isOnline,
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
      heading: heading ?? this.heading,
      isLoading: isLoading ?? this.isLoading,
      isOnline: isOnline ?? this.isOnline,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ViewModel do perfil do motorista (RF04/RF05/RF06).
///
/// Orquestra a seleção de linha e ônibus, o início e o encerramento do
/// trajeto e o loop de transmissão de GPS a cada 1 segundo (RNF05: até 5 s).
class DriverTripController extends Notifier<DriverTripState> {
  StreamSubscription<Position>? _positionSubscription;

  /// Escuta da conexão com o Firebase durante o trajeto (ônibus fantasma).
  StreamSubscription<bool>? _connectionSubscription;

  /// Reenvia a última posição quando o GPS não manda leituras novas (ônibus
  /// parado), para o passageiro não achar que o ônibus sumiu.
  Timer? _heartbeat;

  /// Momento do último envio de posição ao Firebase (controle do RNF05).
  DateTime? _lastSentAt;

  /// Última leitura do GPS considerada confiável (ver [_isReliable]) e
  /// quando ela chegou. É a posição mostrada no mapa e enviada ao Firebase.
  Position? _lastReliable;
  DateTime? _lastReliableAt;

  /// Quando chegou a última leitura com boa precisão (ver [_isReliable]).
  DateTime? _lastAccurateAt;

  /// Leitura recusada por ser um salto grande demais e quantas leituras
  /// seguidas confirmaram a nova posição (ver [_confirmsJump]).
  Position? _jumpCandidate;
  int _jumpConfirmations = 0;

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

      _lastReliable = position;
      _lastReliableAt = DateTime.now();
      _lastAccurateAt = DateTime.now();
      _startTransmission(driverId);
      state = state.copyWith(
        isLoading: false,
        status: DriverStatus.tripStarted,
        isOnline: true,
        activeTrip: trip,
        heading: position.heading >= 0 ? position.heading : 0,
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
        isOnline: true,
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
    _connectionSubscription?.cancel();
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      kDriverHeartbeatInterval,
      (_) => _sendHeartbeat(driverId),
    );
    // Se a conexão cair, o servidor marca o motorista como offline e o
    // ônibus some do mapa do passageiro; ao reconectar, ele volta.
    bool wasConnected = false;
    _connectionSubscription = ref
        .read(driverRepositoryProvider)
        .keepTripAlive(driverId)
        .listen(
      (bool connected) {
        // O Firebase avisa "desconectado" antes da primeira conexão; o
        // aviso só aparece depois de o aparelho já ter estado online.
        if (connected) wasConnected = true;
        if (!wasConnected) return;
        if (state.isOnline != connected) {
          state = state.copyWith(isOnline: connected);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('Falha ao acompanhar a conexão', error, stackTrace);
      },
    );
    // A posição inicial acabou de ser gravada pelo StartTrip.
    _lastSentAt = DateTime.now();
    _positionSubscription = ref
        .read(locationServiceProvider)
        .watchPosition()
        .listen((Position position) async {
      // O mapa do próprio motorista acompanha toda leitura confiável do GPS
      // (a cada kGpsSampleInterval), para o ônibus andar de forma contínua.
      // Leituras ruins (celular balançando, sinal fraco) são descartadas e
      // o ônibus fica na última posição boa, sem pular para fora da rua.
      final Trip? trip = state.activeTrip;
      if (trip != null && _isReliable(position)) {
        _lastReliable = position;
        _lastReliableAt = DateTime.now();
        // Parado ou devagar, o rumo do GPS é aleatório: mantém o anterior.
        final bool moving = position.speed >= kGpsMovingSpeedMps;
        state = state.copyWith(
          activeTrip: trip.copyWith(
            currentLatitude: position.latitude,
            currentLongitude: position.longitude,
          ),
          heading: moving && position.heading >= 0
              ? position.heading
              : state.heading,
        );
      }
      // O envio continua no mesmo ritmo (RNF05), sempre com a última
      // posição confiável.
      final Position sendPosition = _lastReliable ?? position;

      // Envio ao Firebase a cada kGpsUpdateInterval (1 s, dentro do limite
      // de 5 s do RNF05). A pequena folga absorve variações do GPS, para
      // nenhuma leitura ser descartada por chegar alguns milissegundos antes.
      final DateTime now = DateTime.now();
      final DateTime? lastSent = _lastSentAt;
      if (lastSent != null &&
          now.difference(lastSent) <
              kGpsUpdateInterval - const Duration(milliseconds: 250)) {
        return;
      }
      _lastSentAt = now;
      try {
        await ref.read(sendLocationProvider).call(
              driverId: driverId,
              latitude: sendPosition.latitude,
              longitude: sendPosition.longitude,
            );
      } catch (error, stackTrace) {
        // Falha pontual de transmissão não interrompe o trajeto; a próxima
        // leitura tenta enviar de novo.
        _lastSentAt = lastSent;
        AppLogger.error('Falha ao transmitir posição', error, stackTrace);
      }
    });
  }

  /// Com o ônibus parado o GPS pode ficar sem leituras novas; reenvia a
  /// última posição se nada foi enviado no último
  /// [kDriverHeartbeatInterval].
  Future<void> _sendHeartbeat(String driverId) async {
    final Trip? trip = state.activeTrip;
    final DateTime? lastSent = _lastSentAt;
    if (trip == null) return;
    if (lastSent != null &&
        DateTime.now().difference(lastSent) < kDriverHeartbeatInterval) {
      return;
    }
    _lastSentAt = DateTime.now();
    try {
      await ref.read(sendLocationProvider).call(
            driverId: driverId,
            latitude: trip.currentLatitude,
            longitude: trip.currentLongitude,
          );
    } catch (error, stackTrace) {
      _lastSentAt = lastSent;
      AppLogger.error('Falha ao reenviar a posição', error, stackTrace);
    }
  }

  /// Se a leitura [position] do GPS é confiável para mover o ônibus.
  ///
  /// Descarta leituras imprecisas, saltos impossíveis para um ônibus e a
  /// oscilação do GPS com o ônibus parado. Se o sinal fica ruim por mais de
  /// [kGpsStaleAfter], aceita leituras menos precisas para o ônibus não
  /// ficar travado.
  bool _isReliable(Position position) {
    final DateTime now = DateTime.now();
    if (position.accuracy <= kGpsMaxAccuracyMeters) {
      _lastAccurateAt = now;
    } else {
      final DateTime? lastAccurate = _lastAccurateAt;
      final bool poorSignal = lastAccurate == null ||
          now.difference(lastAccurate) > kGpsStaleAfter;
      if (!poorSignal || position.accuracy > kGpsMaxAccuracyStaleMeters) {
        return false;
      }
    }

    final Position? last = _lastReliable;
    final DateTime? lastAt = _lastReliableAt;
    if (last == null || lastAt == null) return true;

    final double meters = MapUtils.distanceInKm(
          LatLng(last.latitude, last.longitude),
          LatLng(position.latitude, position.longitude),
        ) *
        1000;
    final double seconds =
        math.max(now.difference(lastAt).inMilliseconds / 1000, 0.5);
    if (meters / seconds > kGpsMaxSpeedMps) return _confirmsJump(position);
    _jumpCandidate = null;
    _jumpConfirmations = 0;
    if (meters < kGpsMinMoveMeters &&
        position.speed < kGpsMovingSpeedMps) {
      return false;
    }
    return true;
  }

  /// Um salto grande isolado é erro do GPS e é ignorado. Mas, se as
  /// leituras seguintes continuam juntas no lugar novo, o GPS foi mesmo
  /// reposicionado (saída de túnel, simulação recomeçando a linha) e a
  /// nova posição é aceita depois de [kGpsJumpConfirmations] leituras.
  bool _confirmsJump(Position position) {
    final Position? candidate = _jumpCandidate;
    final bool together = candidate != null &&
        MapUtils.distanceInKm(
              LatLng(candidate.latitude, candidate.longitude),
              LatLng(position.latitude, position.longitude),
            ) *
            1000 <=
            kGpsJumpClusterMeters;
    _jumpConfirmations = together ? _jumpConfirmations + 1 : 1;
    _jumpCandidate = position;
    if (_jumpConfirmations < kGpsJumpConfirmations) return false;
    _jumpCandidate = null;
    _jumpConfirmations = 0;
    return true;
  }

  void _stopTransmission() {
    _lastReliable = null;
    _lastReliableAt = null;
    _lastAccurateAt = null;
    _jumpCandidate = null;
    _jumpConfirmations = 0;
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _heartbeat?.cancel();
    _heartbeat = null;
    _lastSentAt = null;
  }
}

/// Provider do [DriverTripController].
final NotifierProvider<DriverTripController, DriverTripState>
    driverTripControllerProvider =
    NotifierProvider<DriverTripController, DriverTripState>(
  DriverTripController.new,
);