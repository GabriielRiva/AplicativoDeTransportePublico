# Configuracao Android — TranCity

Passos a executar UMA vez, depois de rodar `flutter create .` na raiz do projeto.

## 1. android/app/build.gradle

Dentro de `defaultConfig`, ajustar:

```gradle
defaultConfig {
    applicationId "com.trancity.app"
    minSdkVersion 26          // Android 8.0 (Oreo) — RNF06
    targetSdkVersion flutter.targetSdkVersion
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName

    // Chave do Google Maps lida de android/local.properties
    manifestPlaceholders = [MAPS_API_KEY: project.findProperty("MAPS_API_KEY") ?: ""]
}
```

No final do arquivo, adicionar o plugin do Firebase:

```gradle
apply plugin: 'com.google.gms.google-services'
```

## 2. android/build.gradle (raiz)

No bloco `dependencies` do `buildscript`:

```gradle
classpath 'com.google.gms:google-services:4.4.2'
```

## 3. android/local.properties

Adicionar a chave criada no Google Cloud Console (nunca commitar):

```
MAPS_API_KEY=SUA_CHAVE_AQUI
```

## 4. AndroidManifest.xml

Substituir `android/app/src/main/AndroidManifest.xml` pelo arquivo
deste pacote (ja contem as permissoes de localizacao e o meta-data do Maps).

## 5. Firebase

1. Criar o projeto **TranCity** no Firebase Console.
2. Adicionar app Android com o pacote `com.trancity.app`.
3. Baixar `google-services.json` para `android/app/`.
4. Ativar **Authentication → E-mail/senha**.
5. Criar **Realtime Database** e publicar as regras de `database.rules.json`.
