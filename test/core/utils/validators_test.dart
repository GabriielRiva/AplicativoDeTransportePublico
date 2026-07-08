import 'package:flutter_test/flutter_test.dart';
import 'package:trancity/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('aceita e-mail válido', () {
      expect(Validators.email('gabriel@unochapeco.edu.br'), isNull);
    });

    test('rejeita e-mail sem domínio', () {
      expect(Validators.email('gabriel@'), isNotNull);
    });

    test('rejeita campo vazio', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });
  });

  group('Validators.password', () {
    test('aceita senha com 6 ou mais caracteres', () {
      expect(Validators.password('123456'), isNull);
    });

    test('rejeita senha curta', () {
      expect(Validators.password('12345'), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('aceita senhas iguais', () {
      expect(Validators.confirmPassword('senha123', 'senha123'), isNull);
    });

    test('rejeita senhas diferentes', () {
      expect(
        Validators.confirmPassword('senha123', 'outra456'),
        isNotNull,
      );
    });
  });

  group('Validators.fullName', () {
    test('aceita nome e sobrenome', () {
      expect(Validators.fullName('Gabriel Riva'), isNull);
    });

    test('rejeita nome único', () {
      expect(Validators.fullName('Gabriel'), isNotNull);
    });
  });

  group('Validators.cnh', () {
    test('aceita CNH com 11 dígitos', () {
      expect(Validators.cnh('12345678901'), isNull);
    });

    test('rejeita CNH com tamanho inválido', () {
      expect(Validators.cnh('12345'), isNotNull);
    });

    test('rejeita CNH com letras', () {
      expect(Validators.cnh('12345abc901'), isNotNull);
    });
  });
}
