import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/line.dart';
import '../../controllers/lines_controller.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common/app_snackbar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/lines/line_card.dart';
import '../../widgets/lines/line_search_bar.dart';

/// Tela de Linhas: busca e listagem das linhas disponíveis (RF08).
class LinesPage extends ConsumerWidget {
  /// Cria a tela de linhas.
  const LinesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<LinesState>>(linesControllerProvider,
        (AsyncValue<LinesState>? previous, AsyncValue<LinesState> next) {
      final String? error = next.valueOrNull?.errorMessage;
      if (error != null) {
        AppSnackbar.showError(context, error);
        ref.read(linesControllerProvider.notifier).clearError();
      }
    });

    final AsyncValue<LinesState> stateAsync =
        ref.watch(linesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Linhas e Trajetos')),
      body: stateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => EmptyState(
          icon: Icons.wifi_off,
          title: 'Não foi possível carregar',
          message: error.toString(),
        ),
        data: (LinesState state) {
          final List<Line> lines = state.filteredLines;
          return Column(
            children: <Widget>[
              LineSearchBar(
                onChanged:
                    ref.read(linesControllerProvider.notifier).search,
              ),
              Expanded(
                child: lines.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off,
                        title: 'Nenhuma linha encontrada',
                        message:
                            'Verifique o termo pesquisado e tente novamente.',
                      )
                    : ListView.builder(
                        itemCount: lines.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Line line = lines[index];
                          return LineCard(
                            line: line,
                            onTap: () {
                              ref
                                  .read(linesControllerProvider.notifier)
                                  .selectLine(line);
                              Navigator.of(context).pushNamed(
                                kLineDetailsRoute,
                                arguments: line,
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
