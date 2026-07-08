import 'package:connectivity_plus/connectivity_plus.dart';

/// Contrato de verificação de conectividade.
abstract interface class NetworkInfo {
  /// Retorna `true` se o dispositivo possui alguma conexão de rede ativa.
  Future<bool> get isConnected;

  /// Stream que emite o estado de conectividade a cada mudança.
  Stream<bool> get onStatusChange;
}

/// Implementação de [NetworkInfo] baseada no package connectivity_plus.
final class NetworkInfoImpl implements NetworkInfo {
  /// Cria a implementação recebendo a instância de [Connectivity].
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );
  }
}
