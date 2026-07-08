/// Perfis de acesso do sistema (API_SPEC: UserRole).
enum UserRole {
  /// Motorista: transmite localização GPS durante o trajeto.
  driver('driver'),

  /// Passageiro: acompanha os ônibus no mapa em tempo real.
  passenger('passenger');

  const UserRole(this.value);

  /// Valor persistido no Firebase (FIREBASE_SCHEMA: roles).
  final String value;

  /// Converte o valor persistido de volta para o enum.
  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (UserRole role) => role.value == value,
      orElse: () => UserRole.passenger,
    );
  }

  /// Nome do perfil exibido ao usuário.
  String get label =>
      this == UserRole.driver ? 'Motorista' : 'Passageiro';
}
