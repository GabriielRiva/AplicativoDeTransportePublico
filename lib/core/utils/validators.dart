import '../constants/app_constants.dart';

/// Validações de formulário do TranCity (PROJECT_RULES: sempre validar).
abstract final class Validators {
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

  static final RegExp _digitsOnlyRegex = RegExp(r'^\d+$');

  /// Valida campo obrigatório genérico.
  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field é obrigatório.';
    }
    return null;
  }

  /// Valida o formato do e-mail.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu e-mail.';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  /// Valida a senha (mínimo de [kMinPasswordLength] caracteres).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe sua senha.';
    }
    if (value.length < kMinPasswordLength) {
      return 'A senha deve ter ao menos $kMinPasswordLength caracteres.';
    }
    return null;
  }

  /// Valida a confirmação de senha comparando com [password].
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirme sua senha.';
    }
    if (value != password) {
      return 'As senhas não coincidem.';
    }
    return null;
  }

  /// Valida o nome completo (ao menos nome e sobrenome).
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe seu nome completo.';
    }
    if (value.trim().split(' ').length < 2) {
      return 'Informe nome e sobrenome.';
    }
    return null;
  }

  /// Valida o número da CNH (exclusivo do perfil motorista).
  static String? cnh(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o número da CNH.';
    }
    final String digits = value.trim();
    if (digits.length != kCnhLength || !_digitsOnlyRegex.hasMatch(digits)) {
      return 'A CNH deve conter $kCnhLength dígitos.';
    }
    return null;
  }
}
