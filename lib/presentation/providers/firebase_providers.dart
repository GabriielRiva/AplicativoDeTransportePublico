import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Instância única do Firebase Authentication.
final Provider<FirebaseAuth> firebaseAuthProvider =
    Provider<FirebaseAuth>((Ref ref) => FirebaseAuth.instance);

/// Instância única do Firebase Realtime Database.
final Provider<FirebaseDatabase> firebaseDatabaseProvider =
    Provider<FirebaseDatabase>((Ref ref) => FirebaseDatabase.instance);

/// Diferença (ms) entre o relógio do servidor do Firebase e o do aparelho,
/// usada para medir o atraso de entrega das posições (RNF05).
final StreamProvider<int> serverTimeOffsetProvider =
    StreamProvider<int>((Ref ref) {
  return ref
      .watch(firebaseDatabaseProvider)
      .ref('.info/serverTimeOffset')
      .onValue
      .map(
        (DatabaseEvent event) =>
            (event.snapshot.value as num?)?.toInt() ?? 0,
      );
});
