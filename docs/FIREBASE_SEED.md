# Dados Simulados — TranCity (RNF08)

O arquivo `seed/firebase_seed.json` contém os dados simulados do
protótipo: 3 linhas, 21 paradas, 18 horários e 4 ônibus, inspirados
nos wireframes do TCC (L101 Centro/Ecoparque, Efapi e H. Regional).

## Como importar no Firebase Console

1. Abrir o projeto no Firebase Console → **Realtime Database**.
2. Na aba **Dados**, clicar no menu **⋮** (canto superior direito).
3. Escolher **Importar JSON** e selecionar `seed/firebase_seed.json`.

> **Atenção:** a importação na raiz **substitui todo o conteúdo** do
> banco. Importe o seed ANTES de criar usuários pelo aplicativo.
> Se já houver usuários cadastrados, importe o JSON individualmente
> em cada nó (`lines`, `stops`, `schedules`, `buses`), abrindo o nó
> correspondente antes de usar Importar JSON.

## Regras e índices

Publicar o arquivo `database.rules.json` na aba **Regras**. Ele já
inclui os índices `.indexOn: ["lineId"]` exigidos pelas consultas
de paradas, horários e ônibus por linha.

## Fluxo de validação (Metodologia de Testes do TCC)

1. Importar o seed e publicar as regras.
2. Cadastrar um usuário **Motorista** e um **Passageiro** pelo app.
3. No motorista: selecionar a linha L101, o ônibus #1430 e Iniciar
   Trajeto.
4. No passageiro: acompanhar o marcador verde no mapa, com
   atualização automática a cada 5 segundos (RNF05).
