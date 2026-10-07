import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trip.dart';
import '../providers/bus_providers.dart';
import '../providers/firebase_providers.dart';

/// Uma posição nova de um ônibus recebida pelo app do passageiro.
class UpdateSample {
  /// Cria a amostra.
  const UpdateSample({
    required this.tripId,
    required this.lineId,
    required this.receivedAt,
    required this.serverIntervalMs,
    required this.receiveIntervalMs,
    required this.latencyMs,
  });

  /// Trajeto (motorista) que enviou a posição.
  final String tripId;

  /// Linha do ônibus.
  final String lineId;

  /// Momento em que o passageiro recebeu a posição (relógio do aparelho).
  final DateTime receivedAt;

  /// Tempo entre esta posição e a anterior, pelo horário do servidor:
  /// o intervalo de envio do motorista (RNF05).
  final int serverIntervalMs;

  /// Tempo entre esta posição e a anterior, pelo relógio do passageiro:
  /// o intervalo percebido por quem acompanha o ônibus.
  final int receiveIntervalMs;

  /// Tempo entre a gravação no servidor e a chegada no passageiro.
  final int latencyMs;
}

/// Estado da medição de atualização.
class UpdateMetricsState {
  /// Cria o estado.
  const UpdateMetricsState({
    required this.startedAt,
    this.samples = const <UpdateSample>[],
  });

  /// Início da medição.
  final DateTime startedAt;

  /// Amostras registradas (as mais recentes, até um limite).
  final List<UpdateSample> samples;
}

/// Mede, no aparelho do passageiro, de quanto em quanto tempo chegam
/// posições novas de cada ônibus em circulação, para comprovar o RNF05
/// (localização atualizada em no máximo 5 segundos).
///
/// Usa o horário do servidor gravado em cada posição (updatedAt): a
/// diferença entre duas posições seguidas do mesmo ônibus é o intervalo
/// de envio, sem depender do relógio dos aparelhos.
class UpdateMetricsController extends Notifier<UpdateMetricsState> {
  /// Quantidade máxima de amostras guardadas (as mais antigas saem).
  static const int _maxSamples = 5000;

  /// Última posição recebida de cada ônibus.
  final Map<String, ({DateTime updatedAt, DateTime receivedAt})> _last =
      <String, ({DateTime updatedAt, DateTime receivedAt})>{};

  /// Diferença (ms) entre o relógio do servidor e o do aparelho.
  int _serverOffsetMs = 0;

  @override
  UpdateMetricsState build() {
    ref.listen<AsyncValue<int>>(serverTimeOffsetProvider,
        (AsyncValue<int>? previous, AsyncValue<int> next) {
      _serverOffsetMs = next.valueOrNull ?? _serverOffsetMs;
    });
    ref.listen<AsyncValue<List<Trip>>>(activeBusesProvider,
        (AsyncValue<List<Trip>>? previous, AsyncValue<List<Trip>> next) {
      final List<Trip>? trips = next.valueOrNull;
      if (trips != null) _record(trips);
    });
    return UpdateMetricsState(startedAt: DateTime.now());
  }

  void _record(List<Trip> trips) {
    final DateTime now = DateTime.now();
    // Ônibus que saíram de circulação recomeçam a medição quando voltarem.
    _last.removeWhere(
      (String id, _) => !trips.any((Trip trip) => trip.id == id),
    );

    final List<UpdateSample> added = <UpdateSample>[];
    for (final Trip trip in trips) {
      final DateTime? updatedAt = trip.updatedAt;
      if (updatedAt == null) continue;
      final ({DateTime updatedAt, DateTime receivedAt})? last =
          _last[trip.id];
      if (last != null && !updatedAt.isAfter(last.updatedAt)) continue;
      _last[trip.id] = (updatedAt: updatedAt, receivedAt: now);
      if (last == null) continue;
      added.add(
        UpdateSample(
          tripId: trip.id,
          lineId: trip.lineId,
          receivedAt: now,
          serverIntervalMs:
              updatedAt.difference(last.updatedAt).inMilliseconds,
          receiveIntervalMs: now.difference(last.receivedAt).inMilliseconds,
          latencyMs: now.millisecondsSinceEpoch +
              _serverOffsetMs -
              updatedAt.millisecondsSinceEpoch,
        ),
      );
    }
    if (added.isEmpty) return;

    final List<UpdateSample> samples = <UpdateSample>[
      ...state.samples,
      ...added,
    ];
    state = UpdateMetricsState(
      startedAt: state.startedAt,
      samples: samples.length > _maxSamples
          ? samples.sublist(samples.length - _maxSamples)
          : samples,
    );
  }

  /// Apaga as amostras e recomeça a medição a partir de agora.
  void reset() {
    _last.clear();
    state = UpdateMetricsState(startedAt: DateTime.now());
  }

  /// Amostras em CSV (separado por ponto e vírgula, para abrir direto no
  /// Excel em português).
  String toCsv() {
    final StringBuffer csv = StringBuffer(
      'linha;trajeto;recebido_em;intervalo_envio_ms;'
      'intervalo_recebimento_ms;latencia_ms\n',
    );
    for (final UpdateSample sample in state.samples) {
      csv.writeln(
        '${sample.lineId};${sample.tripId};'
        '${sample.receivedAt.toIso8601String()};'
        '${sample.serverIntervalMs};${sample.receiveIntervalMs};'
        '${sample.latencyMs}',
      );
    }
    return csv.toString();
  }
}

/// Provider da medição de atualização (RNF05). Fica ativo enquanto a home
/// do passageiro estiver aberta.
final NotifierProvider<UpdateMetricsController, UpdateMetricsState>
    updateMetricsProvider =
    NotifierProvider<UpdateMetricsController, UpdateMetricsState>(
  UpdateMetricsController.new,
);
