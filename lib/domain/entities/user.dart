import 'enums/user_role.dart';

/// Usuário base do sistema (API_SPEC: User).
class User {
  /// Cria um usuário com os atributos comuns aos dois perfis.
  const User({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  /// Identificador único gerado pelo Firebase Authentication.
  final String uid;

  /// Nome completo do usuário.
  final String name;

  /// E-mail de acesso.
  final String email;

  /// Perfil de acesso (motorista ou passageiro).
  final UserRole role;

  /// Data de criação da conta.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) => other is User && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}
