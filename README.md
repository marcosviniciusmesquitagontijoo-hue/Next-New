# Next IPTV — projeto inicial Flutter

Projeto-fonte Android para um player IPTV que usa API Xtream Codes. A URL do servidor fica predefinida e a tela de entrada mostra apenas usuário e senha.

## Importante
- Este é um **projeto-fonte inicial**, não um APK compilado.
- O ambiente desta sessão não tem Flutter instalado, então não foi possível compilar e testar o APK aqui.
- O app usa uma interface própria inspirada em players IPTV escuros; não reutiliza código, imagens ou recursos internos do Lotus APK.
- Use somente listas e conteúdos para os quais você tenha autorização.
- O servidor foi configurado como `http://wanvistorenv.top`. A API Xtream Codes padrão pode variar conforme o provedor.
- HTTP não criptografa as credenciais. Para produção, prefira HTTPS se o servidor oferecer.

## Como compilar no Windows
1. Instale Flutter SDK e Android Studio, incluindo Android SDK.
2. Abra o terminal na pasta do projeto.
3. Execute:
   ```bash
   flutter create --org com.next --project-name next_iptv . --platforms=android
   flutter pub get
   flutter run
   ```
4. Para gerar APK:
   ```bash
   flutter build apk --release
   ```
   O APK ficará em `build/app/outputs/flutter-apk/app-release.apk`.

Se `flutter create .` sobrescrever arquivos Android, mantenha a configuração de HTTP descrita em `android/app/src/main/AndroidManifest.xml`.

## Servidor
A URL base está em `lib/main.dart` na constante `serverBase`. O app chama `/player_api.php` com `username` e `password`.
