import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_handler.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/line.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/entities/stop.dart';
import '../providers/usecase_providers.dart';

/// Estado imutável da tela de Linhas e Trajetos.
class LinesState {
  /// Cria o estado das linhas.
  const LinesState({
    this.allLines = const <Line>[],
    this.query = '',
    this.selectedLine,
    this.stops = const <Stop>[],
    this.schedules = const <Schedule>[],
    this.isLoadingDetails = false,
    this.errorMessage,
  });

  /// Todas as linhas cadastradas.
  final List<Line> allLines;

  /// Texto atual do campo de busca.
  final String query;

  /// Linha selecionada para exibição da rota detalhada.
  final Line? selectedLine;

  /// Paradas da linha selecionada, ordenadas pela rota (RF09).
  final List<Stop> stops;

  /// Horários da linha selecionada (RF10).
  final List<Schedule> schedules;

  /// Indica carregamento dos detalhes da linha.
  final bool isLoadingDetails;

  /// Mensagem de erro a exibir em Snackbar.
  final String? errorMessage;

  /// Linhas filtradas pela busca por nome ou número (UI_SPEC).
  List<Line> get filteredLines {
    if (query.trim().isEmpty) return allLines;
    final String term = query.trim().toLowerCase();
    return allLines
        .where(
          (Line line) =>
              line.name.toLowerCase().contains(term) ||
              line.number.toLowerCase().contains(term) ||
              line.description.toLowerCase().contains(term),
        )
        .toList();
  }

  /// Retorna uma cópia do estado alterando apenas os campos informados.
  LinesState copyWith({
    List<Line>? allLines,
    String? query,
    Line? selectedLine,
    List<Stop>? stops,
    List<Schedule>? schedules,
    bool? isLoadingDetails,
    String? errorMessage,
    bool clearSelection = false,
    bool clearError = false,
  }) {
    return LinesState(
      allLines: allLines ?? this.allLines,
      query: query ?? this.query,
      selectedLine:
          clearSelection ? null : (selectedLine ?? this.selectedLine),
      stops: clearSelection ? const <Stop>[] : (stops ?? this.stops),
      schedules:
          clearSelection ? const <Schedule>[] : (schedules ?? this.schedules),
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ViewModel da tela de Linhas e Trajetos (RF08/RF09/RF10).
class LinesController extends AsyncNotifier<LinesState> {
  @override
  Future<LinesState> build() async {
    final List<Line> lines = await ref.watch(getLinesProvider).call();
    return LinesState(allLines: lines);
  }

  /// Atualiza o termo de busca por nome ou número da linha.
  void search(String query) {
    final LinesState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue<LinesState>.data(current.copyWith(query: query));
  }

  /// Seleciona uma linha e carrega sua rota detalhada: paradas e
  /// horários, exibidos no painel "Rota Detalhada" (UI_SPEC).
  Future<void> selectLine(Line line) async {
    final LinesState? current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue<LinesState>.data(
      current.copyWith(
        selectedLine: line,
        isLoadingDetails: true,
        clearError: true,
      ),
    );

    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        ref.read(getLineStopsProvider).call(line.id),
        ref.read(getLineSchedulesProvider).call(line.id),
      ]);
      final LinesState? latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncValue<LinesState>.data(
        latest.copyWith(
          stops: results[0] as List<Stop>,
          schedules: results[1] as List<Schedule>,
          isLoadingDetails: false,
        ),
      );
    } catch (error, stackTrace) {
      AppLogger.error('Erro ao carregar detalhes da linha', error, stackTrace);
      final LinesState? latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncValue<LinesState>.data(
        latest.copyWith(
          isLoadingDetails: false,
          errorMessage: ErrorHandler.getUserMessage(error),
        ),
      );
    }
  }

  /// Limpa a linha selecionada, fechando o painel de rota detalhada.
  void clearSelection() {
    final LinesState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue<LinesState>.data(
      current.copyWith(clearSelection: true),
    );
  }

  /// Limpa a mensagem de erro após exibição na tela.
  void clearError() {
    final LinesState? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue<LinesState>.data(current.copyWith(clearError: true));
  }
}

/// Provider do [LinesController].
final AsyncNotifierProvider<LinesController, LinesState>
    linesControllerProvider =
    AsyncNotifierProvider<LinesController, LinesState>(LinesController.new);
