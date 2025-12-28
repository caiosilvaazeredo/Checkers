# Configuração Firebase no Windows - Guia Completo

## ⚠️ IMPORTANTE: Arquivo Service Account

O arquivo `checkers-27bb3-firebase-adminsdk-fbsvc-ce0a4d6d02.json` é uma **chave de service account**.

**NÃO COLOQUE ESTE ARQUIVO NO SEU PROJETO FLUTTER!**

- ❌ Não adicione ao código do app
- ❌ Não commit no git (é secreto!)
- ✅ Use apenas para operações de backend/servidor
- ✅ Guarde em local seguro no seu computador

## Passo 1: Instalar FlutterFire CLI

Abra o PowerShell (pode ser como usuário normal) e execute:

```powershell
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli
```

## Passo 2: Adicionar ao PATH (Importante!)

Você precisa adicionar o diretório do Dart pub cache ao PATH do Windows.

### Opção A: Temporário (só para esta sessão do PowerShell)

```powershell
$env:Path += ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin"
```

### Opção B: Permanente (Recomendado)

Execute no PowerShell como **Administrador**:

```powershell
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\AppData\Local\Pub\Cache\bin", "User")
```

**Depois feche e abra um NOVO PowerShell** para as mudanças terem efeito.

### Opção C: Manual via Interface Gráfica

1. Pressione `Windows + R`
2. Digite `sysdm.cpl` e pressione Enter
3. Vá em **Avançado** → **Variáveis de Ambiente**
4. Em "Variáveis do usuário", selecione **Path** e clique em **Editar**
5. Clique em **Novo** e adicione: `%USERPROFILE%\AppData\Local\Pub\Cache\bin`
6. Clique OK em tudo
7. Feche e abra o PowerShell

## Passo 3: Verificar Instalação

Abra um NOVO PowerShell e verifique:

```powershell
# Verificar se FlutterFire CLI está disponível
flutterfire --version

# Deve mostrar algo como: FlutterFire CLI 0.x.x
```

Se ainda não funcionar, tente:

```powershell
# Verificar onde está instalado
Get-ChildItem "$env:USERPROFILE\AppData\Local\Pub\Cache\bin" | Select-Object Name
```

## Passo 4: Configurar Firebase no Projeto

No PowerShell, navegue até a pasta do projeto:

```powershell
cd D:\Github\Checkers
```

Você já fez login no Firebase (✅ já feito), agora execute:

```powershell
# Configurar FlutterFire
flutterfire configure
```

### Durante a configuração você verá:

1. **Selecionar projeto Firebase:**
   - Use as setas ↑ ↓ para navegar
   - Selecione seu projeto `checkers-27bb3`
   - Pressione Enter

2. **Selecionar plataformas:**
   - Use Espaço para marcar/desmarcar
   - Marque: `android`, `ios`, `web`
   - Pressione Enter

3. **O comando vai:**
   - Atualizar `lib/firebase_options.dart` com as configurações REAIS
   - Gerar configurações corretas para cada plataforma

## Passo 5: Configurar Google Sign-In para Web

Depois de executar `flutterfire configure`, você precisa adicionar a meta tag do Google Sign-In.

### 5.1: Obter o Client ID Web

1. Vá para [Firebase Console](https://console.firebase.google.com/)
2. Selecione seu projeto `checkers-27bb3`
3. Vá em **⚙️ Project Settings**
4. Role até **Your apps** e clique no app **Web**
5. Copie o **Web client ID** do Google Sign-In

OU

1. Vá para [Google Cloud Console](https://console.cloud.google.com/)
2. Selecione o projeto
3. Menu → **APIs & Services** → **Credentials**
4. Em "OAuth 2.0 Client IDs", copie o **Client ID** do tipo **Web application**

### 5.2: Adicionar ao web/index.html

Abra o arquivo `web/index.html` e adicione dentro da tag `<head>`, ANTES do `<title>`:

```html
<!-- Google Sign-In Client ID -->
<meta name="google-signin-client_id" content="SEU_CLIENT_ID_AQUI.apps.googleusercontent.com">
```

**Exemplo completo do head:**

```html
<head>
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="Master Checkers AI - Play checkers">

  <!-- Google Sign-In Client ID - ADICIONE ESTA LINHA -->
  <meta name="google-signin-client_id" content="953618224657-abc123xyz.apps.googleusercontent.com">

  <!-- iOS meta tags & icons -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="master_checkers">

  <title>Master Checkers AI</title>
  <link rel="manifest" href="manifest.json">
</head>
```

## Passo 6: Limpar Cache e Executar

```powershell
# Limpar build anterior
flutter clean

# Instalar dependências
flutter pub get

# Executar no navegador
flutter run -d chrome
```

## Verificação Final

Após executar os passos acima, você deve ter:

- ✅ FlutterFire CLI instalado e no PATH
- ✅ `flutterfire configure` executado com sucesso
- ✅ `lib/firebase_options.dart` com valores REAIS (não placeholder)
- ✅ `web/index.html` com a meta tag do Google Client ID
- ✅ App rodando sem erros

## Solução de Problemas

### Erro: "flutterfire não é reconhecido"

**Causa:** PATH não configurado ou PowerShell não foi reaberto.

**Solução:**
1. Feche TODOS os PowerShells abertos
2. Abra um NOVO PowerShell
3. Verifique: `flutterfire --version`
4. Se ainda não funcionar, adicione ao PATH novamente (ver Passo 2)

### Erro: "ClientID not set" na Web

**Causa:** Meta tag do Google Sign-In não configurada no `web/index.html`.

**Solução:**
1. Obtenha o Client ID (Passo 5.1)
2. Adicione ao `web/index.html` (Passo 5.2)
3. Execute `flutter clean` e `flutter run -d chrome` novamente

### Erros 400 do Firebase Auth

**Causa:** `firebase_options.dart` ainda tem valores placeholder.

**Solução:**
1. Execute `flutterfire configure` novamente
2. Verifique se o arquivo foi atualizado:
   ```powershell
   Get-Content lib\firebase_options.dart
   ```
3. Os valores NÃO devem conter "d8f8e8c8a8b8c8d8e8f8g8"

### Google Sign-In funciona no mobile mas não na Web

**Causa:** Configuração específica da Web não foi feita.

**Solução:**
- Verifique a meta tag no `web/index.html`
- Verifique se o Client ID é do tipo **Web application**
- Não use o Client ID do Android ou iOS

## Estrutura do Projeto após Configuração

```
Checkers/
├── lib/
│   └── firebase_options.dart  ← Atualizado com valores REAIS
├── web/
│   └── index.html             ← Com meta tag do Google Client ID
├── android/
│   └── app/
│       └── google-services.json  ← Gerado automaticamente (Android)
└── ios/
    └── Runner/
        └── GoogleService-Info.plist  ← Gerado automaticamente (iOS)
```

## Comandos Úteis

```powershell
# Verificar versão do Flutter
flutter --version

# Verificar versão do Dart
dart --version

# Verificar FlutterFire CLI
flutterfire --version

# Ver lista de projetos Firebase
firebase projects:list

# Ver status do projeto
firebase use

# Limpar tudo e recompilar
flutter clean
flutter pub get
flutter run
```

## Links Úteis

- [Firebase Console](https://console.firebase.google.com/)
- [Google Cloud Console](https://console.cloud.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Google Sign-In para Web](https://developers.google.com/identity/sign-in/web/sign-in)

## Próximos Passos

Após tudo configurado:

1. Teste cadastro com email/senha
2. Teste login com email/senha
3. Teste Google Sign-In
4. Configure o Gemini API para o AI opponent (próximo passo)

## Segurança

**Nunca faça commit de:**
- ❌ `*-firebase-adminsdk-*.json` (service account keys)
- ❌ Arquivos `.env` com chaves de API
- ❌ `google-services.json` com dados sensíveis

**Sempre faça commit de:**
- ✅ `firebase_options.dart` (configurações públicas do cliente)
- ✅ `pubspec.yaml`
- ✅ Código fonte
