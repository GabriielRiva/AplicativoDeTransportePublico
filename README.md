# TranCity

Aplicativo Android de rastreamento em tempo real dos ônibus do transporte
público de Chapecó-SC. Protótipo acadêmico desenvolvido como Trabalho de
Conclusão de Curso — Ciências da Computação (Unochapecó).

## Stack

Flutter + Dart · Firebase Authentication · Firebase Realtime Database ·
Google Maps SDK · Riverpod · Geolocator · Material Design 3

## Arquitetura

Clean Architecture (core / domain / data / presentation) com MVVM,
Repository Pattern e injeção de dependência via Riverpod.

## Como executar

1. Instalar Flutter 3.x e rodar `flutter doctor`.
2. Na raiz do projeto: `flutter create .` (gera as pastas de plataforma)
   e depois `flutter pub get`.
3. Seguir `docs/ANDROID_SETUP.md` para configurar Firebase e Google Maps.
4. Publicar as regras de `database.rules.json` no Realtime Database.
5. `flutter run` com um dispositivo/emulador Android 8.0+.

## Perfis

- **Motorista:** seleciona linha e ônibus, inicia o trajeto e transmite a
  localização GPS a cada 5 segundos (RNF05).
- **Passageiro:** acompanha os ônibus no mapa em tempo real e consulta
  linhas, rotas, paradas e horários.

## Testes

```
flutter test
```

Os testes unitários cobrem validações de formulário, cálculo
geográfico (Haversine/ETA), serialização dos models, implementações
de repository e as regras de negócio dos usecases (login, cadastro,
início/encerramento de trajeto, transmissão de GPS e ônibus próximos).

## Dados simulados

Importar `seed/firebase_seed.json` no Realtime Database conforme
`docs/FIREBASE_SEED.md` (RNF08 — dados de linhas, rotas e horários
simulados).
