import 'package:flutter/material.dart';

/// Campo de senha com alternância de visibilidade (UI_SPEC: Login).
///
/// O toggle de visibilidade é estado efêmero de interface, por isso é
/// mantido localmente; nenhuma regra de negócio reside aqui.
class PasswordField extends StatefulWidget {
  /// Cria o campo de senha.
  const PasswordField({
    required this.controller,
    super.key,
    this.hint = 'Senha',
    this.validator,
    this.textInputAction = TextInputAction.done,
  });

  /// Controlador do valor digitado.
  final TextEditingController controller;

  /// Texto de dica exibido no campo.
  final String hint;

  /// Validação executada pelo Form.
  final String? Function(String?)? validator;

  /// Ação do botão de confirmação do teclado.
  final TextInputAction textInputAction;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
          tooltip: _obscure ? 'Mostrar senha' : 'Ocultar senha',
        ),
      ),
    );
  }
}
