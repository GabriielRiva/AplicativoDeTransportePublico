import 'package:flutter/material.dart';

/// Campo de texto padrão do aplicativo com validação.
class AppTextField extends StatelessWidget {
  /// Cria o campo com [hint] e [icon] de prefixo.
  const AppTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    super.key,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
  });

  /// Controlador do valor digitado.
  final TextEditingController controller;

  /// Texto de dica exibido no campo.
  final String hint;

  /// Ícone de prefixo.
  final IconData icon;

  /// Validação executada pelo Form.
  final String? Function(String?)? validator;

  /// Tipo de teclado (e-mail, número...).
  final TextInputType? keyboardType;

  /// Ação do botão de confirmação do teclado.
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
    );
  }
}
