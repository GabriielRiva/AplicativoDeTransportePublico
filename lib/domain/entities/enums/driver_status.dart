/// Status do motorista/trajeto (API_SPEC: DriverStatus).
enum DriverStatus {
  /// Motorista desconectado.
  offline('offline'),

  /// Motorista autenticado, sem trajeto ativo.
  online('online'),

  /// Linha e ônibus selecionados, aguardando início do trajeto.
  waiting('waiting'),

  /// Trajeto ativo com transmissão de GPS.
  tripStarted('trip_started'),

  /// Trajeto encerrado pelo motorista.
  tripFinished('trip_finished');

  const DriverStatus(this.value);

  /// Valor persistido no Firebase (FIREBASE_SCHEMA: status).
  final String value;

  /// Converte o valor persistido de volta para o enum.
  static DriverStatus fromValue(String value) {
    return DriverStatus.values.firstWhere(
      (DriverStatus status) => status.value == value,
      orElse: () => DriverStatus.offline,
    );
  }

  /// Texto do status exibido ao usuário (Tela do Motorista).
  String get label => switch (this) {
        DriverStatus.offline => 'Offline',
        DriverStatus.online => 'Online',
        DriverStatus.waiting => 'Aguardando Início',
        DriverStatus.tripStarted => 'Em Trajeto',
        DriverStatus.tripFinished => 'Trajeto Encerrado',
      };

  /// Indica se há um trajeto em andamento.
  bool get isActive => this == DriverStatus.tripStarted;
}
