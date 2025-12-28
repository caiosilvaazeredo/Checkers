# Troubleshooting - Master Checkers

## Problema: Não consigo fazer cadastro nem login

### Causa Provável
As configurações do Firebase estão usando valores placeholder. O arquivo `lib/firebase_options.dart` precisa ser configurado com um projeto Firebase real.

### Solução
1. Siga o guia completo em [FIREBASE_SETUP.md](FIREBASE_SETUP.md)
2. Ou execute o script automatizado: `bash setup_firebase.sh`

### Sintomas
- App carrega mas não aceita login
- Erros de autenticação
- Stack trace mostrando muitos rebuilds de widgets
- Possível erro: "API key not found" ou "Invalid project configuration"

---

## Stack Trace Longo com Rebuilds

Se você está vendo um stack trace muito longo com várias chamadas de `mount`, `rebuild`, `performRebuild`, etc., isso geralmente indica:

### Causas Comuns

1. **Firebase não configurado** (mais comum)
   - O app está tentando autenticar mas o Firebase não responde
   - Solução: Configure o Firebase corretamente

2. **Loop infinito de rebuild**
   - Um widget está chamando `setState()` dentro do `build()`
   - Verifique se não há chamadas de `notifyListeners()` em lugares errados

3. **Problema de Provider**
   - Verificar se os Providers estão corretamente configurados no `main.dart`
   - Já está correto no projeto atual

### Como Diagnosticar

Execute o app com mais logs:
```bash
flutter run --verbose
```

Procure por erros específicos no console que aparecem antes do stack trace.

---

## Erro: "ClientID not set" - Google Sign-In Web

### Erro Completo
```
Assertion failed: appClientId != null
"ClientID not set. Either set it on a <meta name="google-signin-client_id" content="CLIENT_ID" /> tag,
or pass clientId when initializing GoogleSignIn"
```

### Causa
O Google Sign-In na Web requer uma configuração adicional no arquivo `web/index.html`. Esta configuração não é necessária para Android/iOS, apenas para Web.

### Solução

1. **Obter o Web Client ID:**

   **Opção A - Firebase Console:**
   - Vá para [Firebase Console](https://console.firebase.google.com/)
   - Selecione seu projeto
   - Vá em **⚙️ Project Settings** (ícone de engrenagem)
   - Role até **Your apps** e clique no app **Web**
   - Copie o **Web client ID** (algo como: `123456789-abc123.apps.googleusercontent.com`)

   **Opção B - Google Cloud Console:**
   - Vá para [Google Cloud Console](https://console.cloud.google.com/)
   - Selecione o projeto
   - Menu → **APIs & Services** → **Credentials**
   - Em "OAuth 2.0 Client IDs", copie o **Client ID** do tipo **Web application**

2. **Adicionar ao `web/index.html`:**

   Abra `web/index.html` e adicione dentro da tag `<head>`:

   ```html
   <meta name="google-signin-client_id" content="SEU_CLIENT_ID_AQUI.apps.googleusercontent.com">
   ```

   **Exemplo completo:**
   ```html
   <head>
     <base href="$FLUTTER_BASE_HREF">
     <meta charset="UTF-8">

     <!-- Google Sign-In Client ID -->
     <meta name="google-signin-client_id" content="123456789-abc123.apps.googleusercontent.com">

     <title>Master Checkers AI</title>
   </head>
   ```

3. **Limpar cache e recompilar:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -d chrome
   ```

### Notas Importantes

- ⚠️ Use o Client ID do tipo **Web application**, não o de Android ou iOS
- ⚠️ O Client ID é diferente para cada plataforma
- ✅ Você pode ver um arquivo de exemplo em `web/index.html.example`
- ✅ Este erro só afeta a plataforma Web, não afeta Android/iOS

### Verificação

Após adicionar a meta tag, você NÃO deve mais ver o erro ao clicar em "Continue with Google" na versão Web do app.

---

## Erro: "Failed to connect to Firebase"

### Verificações

1. **Internet ativa?**
   ```bash
   ping firebase.google.com
   ```

2. **Configuração correta?**
   - Verifique se `flutterfire configure` foi executado
   - Verifique se o projeto Firebase existe no console

3. **API Keys corretas?**
   - Abra `lib/firebase_options.dart`
   - Verifique se os valores não são placeholders

---

## Erro: Google Sign-In não funciona

### Android

1. **SHA-1 Fingerprint configurada?**
   ```bash
   cd android
   ./gradlew signingReport
   ```

2. Copie a SHA-1 do debug e adicione no Firebase Console:
   - Project Settings > Your apps > Android app
   - Add SHA-1 fingerprint

3. Baixe o novo `google-services.json` e substitua em `android/app/`

### iOS

1. **URL Schemes configurados?**
   - Abra o projeto no Xcode
   - Verifique se o URL Scheme do GoogleService-Info.plist está configurado

2. **Bundle ID correto?**
   - Deve ser: `com.example.masterCheckers`
   - Verifique no Firebase Console e no Xcode

---

## Erro: Database permission denied

### Causa
As regras de segurança do Realtime Database estão muito restritivas.

### Solução

1. Acesse Firebase Console > Realtime Database > Rules
2. Use as regras do [FIREBASE_SETUP.md](FIREBASE_SETUP.md#4-configurar-regras-de-segurança-do-database)
3. Ou para teste rápido (APENAS DESENVOLVIMENTO):
   ```json
   {
     "rules": {
       ".read": "auth != null",
       ".write": "auth != null"
     }
   }
   ```

**⚠️ ATENÇÃO:** Regras muito permissivas são inseguras para produção!

---

## Erro: "No Firebase App '[DEFAULT]' has been created"

### Verificação

1. Abra `lib/main.dart`
2. Verifique se há:
   ```dart
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
     runApp(const MasterCheckersApp());
   }
   ```

3. Se estiver correto, limpe o cache:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Erro: Build falha no Android

### Gradle Issues

1. **Verifique versões no `android/build.gradle`:**
   ```gradle
   dependencies {
       classpath 'com.android.tools.build:gradle:7.3.0'
       classpath 'com.google.gms:google-services:4.3.15'
   }
   ```

2. **Verifique `android/app/build.gradle`:**
   ```gradle
   android {
       compileSdkVersion 34

       defaultConfig {
           minSdkVersion 21
           targetSdkVersion 34
       }
   }
   ```

3. **Limpe o build:**
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   ```

---

## Erro: FlutterFire CLI não encontrado

### Linux/Mac

1. Instale:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Adicione ao PATH em `~/.bashrc` ou `~/.zshrc`:
   ```bash
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   ```

3. Recarregue:
   ```bash
   source ~/.bashrc  # ou source ~/.zshrc
   ```

### Windows

1. Instale:
   ```cmd
   dart pub global activate flutterfire_cli
   ```

2. Adicione ao PATH:
   - `%USERPROFILE%\AppData\Local\Pub\Cache\bin`

---

## Problema de Performance

### App lento ou travando

1. **Execute em modo release:**
   ```bash
   flutter run --release
   ```

2. **Verifique hot reload:**
   - Modo debug é mais lento
   - Use hot reload (r) em vez de hot restart (R)

3. **Profile o app:**
   ```bash
   flutter run --profile
   ```
   - Abra DevTools para ver performance

---

## Como Reportar Problemas

Se nenhuma solução acima funcionou:

1. **Colete informações:**
   ```bash
   flutter doctor -v > flutter_info.txt
   flutter run --verbose > app_log.txt 2>&1
   ```

2. **Informações necessárias:**
   - Versão do Flutter (`flutter --version`)
   - Sistema operacional
   - Stack trace completo
   - Passos para reproduzir o erro

3. **Onde reportar:**
   - Issues do GitHub do projeto
   - Stack Overflow com tag `flutter` e `firebase`

---

## Links Úteis

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Flutter DevTools](https://docs.flutter.dev/development/tools/devtools/overview)
- [Firebase Status](https://status.firebase.google.com/)
- [Flutter Issues](https://github.com/flutter/flutter/issues)

---

## Checklist de Configuração Completa

Use este checklist para verificar se tudo está configurado:

- [ ] Flutter instalado (`flutter doctor` sem erros críticos)
- [ ] Dependências instaladas (`flutter pub get`)
- [ ] Firebase CLI instalado (`firebase --version`)
- [ ] FlutterFire CLI instalado (`flutterfire --version`)
- [ ] Projeto Firebase criado no console
- [ ] Authentication habilitada (Email/Password + Google)
- [ ] Realtime Database criada
- [ ] Regras de segurança configuradas
- [ ] `flutterfire configure` executado com sucesso
- [ ] `lib/firebase_options.dart` NÃO contém valores placeholder
- [ ] App executa sem erros (`flutter run`)
- [ ] Consegue criar conta
- [ ] Consegue fazer login
- [ ] Consegue fazer logout

Se todos os itens estiverem marcados, sua configuração está completa! 🎉
