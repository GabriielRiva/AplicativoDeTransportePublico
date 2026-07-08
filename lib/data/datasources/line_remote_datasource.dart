import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../core/constants/firebase_paths.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/line_model.dart';

/// Datasource do nó lines/ do Realtime Database.
class LineRemoteDatasource {
  /// Cria o datasource recebendo a instância de [FirebaseDatabase].
  const LineRemoteDatasource(this._database);

  final FirebaseDatabase _database;

  /// Lê todas as linhas cadastradas.
  Future<List<LineModel>> getLines() async {
    try {
      final DataSnapshot snapshot = await _database.ref(kLinesPath).get();
      final Object? raw = snapshot.value;
      if (raw is! Map<Object?, Object?>) return <LineModel>[];

      final List<LineModel> lines = <LineModel>[];
      raw.forEach((Object? key, Object? value) {
        if (key == null || value is! Map<Object?, Object?>) return;
        lines.add(
          LineModel.fromJson(
            key.toString(),
            Map<String, dynamic>.from(value),
          ),
        );
      });
      return lines;
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar linhas', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar as linhas. Tente novamente.',
      );
    }
  }

  /// Lê uma linha específica por identificador.
  Future<LineModel> getLineById(String lineId) async {
    try {
      final DataSnapshot snapshot =
          await _database.ref('$kLinesPath/$lineId').get();
      final Object? value = snapshot.value;
      if (!snapshot.exists || value is! Map<Object?, Object?>) {
        throw const DatabaseException('Linha não encontrada.');
      }
      return LineModel.fromJson(lineId, Map<String, dynamic>.from(value));
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('Falha ao carregar linha', error, stackTrace);
      throw const DatabaseException(
        'Não foi possível carregar a linha. Tente novamente.',
      );
    }
  }
}
