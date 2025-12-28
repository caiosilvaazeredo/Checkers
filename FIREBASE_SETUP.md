# Guia de Configuração do Firebase - Master Checkers

## Problema Identificado
As configurações atuais do Firebase são valores placeholder. Você precisa configurar um projeto real no Firebase.

## Passo a Passo Completo

### 1. Criar Projeto no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Clique em "Adicionar projeto" ou "Create a project"
3. Nome do projeto: **Master Checkers** (ou o nome que preferir)
4. Aceite os termos e continue
5. Desabilite o Google Analytics (opcional para este projeto)
6. Clique em "Criar projeto"

### 2. Configurar Authentication

1. No menu lateral, vá em **Build** > **Authentication**
2. Clique em "Get started"
3. Ative os seguintes métodos de login:

   **a) Email/Password:**
   - Clique em "Email/Password"
   - Ative a primeira opção (Email/Password)
   - OPCIONAL: Ative também "Email link (passwordless sign-in)"
   - Salve

   **b) Google Sign-In:**
   - Clique em "Google"
   - Ative o toggle
   - Escolha um email de suporte do projeto
   - Salve

### 3. Configurar Realtime Database

1. No menu lateral, vá em **Build** > **Realtime Database**
2. Clique em "Create Database"
3. Escolha a localização (ex: `us-central1` ou mais próximo de você)
4. Selecione **"Start in test mode"** (vamos ajustar as regras depois)
5. Clique em "Enable"

### 4. Configurar Regras de Segurança do Database

Na aba "Rules" do Realtime Database, substitua as regras por:

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "games": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "leaderboard": {
      ".read": "auth != null",
      ".write": false
    },
    "friends": {
      "$uid": {
        ".read": "auth != null && auth.uid == $uid",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

### 5. Instalar FlutterFire CLI

Execute os seguintes comandos no terminal:

```bash
# Instalar FlutterFire CLI globalmente
dart pub global activate flutterfire_cli

# Verificar instalação
flutterfire --version
```

**IMPORTANTE:** Se o comando `flutterfire` não for encontrado, adicione ao PATH:

```bash
# Para Linux/Mac, adicione ao ~/.bashrc ou ~/.zshrc:
export PATH="$PATH":"$HOME/.pub-cache/bin"

# Depois execute:
source ~/.bashrc  # ou source ~/.zshrc
```

### 6. Configurar Firebase no Projeto Flutter

Execute na raiz do projeto:

```bash
# Login no Firebase (vai abrir o browser)
firebase login

# Configurar o projeto Flutter com Firebase
flutterfire configure
```

Durante a configuração:
1. Selecione o projeto Firebase que você criou
2. Escolha as plataformas: **Android**, **iOS**, **Web**
3. O comando vai gerar automaticamente o arquivo `lib/firebase_options.dart` com as configurações corretas

### 7. Configurar Android (Adicional)

Se for usar no Android:

1. No Firebase Console, vá em **Project Settings** (ícone de engrenagem)
2. Na seção "Your apps", clique no ícone do Android
3. Registre o app com o package name: `com.example.master_checkers`
4. Baixe o arquivo `google-services.json`
5. Coloque em `android/app/google-services.json`

### 8. Configurar iOS (Adicional)

Se for usar no iOS:

1. No Firebase Console, na seção "Your apps", clique no ícone do iOS
2. Registre o app com o bundle ID: `com.example.masterCheckers`
3. Baixe o arquivo `GoogleService-Info.plist`
4. Adicione ao projeto iOS no Xcode

### 9. Testar a Configuração

Execute o app:

```bash
flutter run
```

Tente:
1. Criar uma conta com email/senha
2. Fazer login com a conta criada
3. Testar login com Google (se estiver em dispositivo real ou emulador configurado)

## Solução de Problemas

### Erro "API key not found"
- Execute novamente `flutterfire configure`
- Verifique se o arquivo `firebase_options.dart` foi atualizado

### Erro no Google Sign-In
- Adicione a SHA-1 fingerprint no Firebase Console (Android)
- Para debug SHA-1:
  ```bash
  cd android
  ./gradlew signingReport
  ```

### Erro de permissão no Database
- Verifique se as regras de segurança foram configuradas corretamente
- No modo de teste, as regras permitem acesso por 30 dias

### Erro "No Firebase App has been created"
- Verifique se `Firebase.initializeApp()` está sendo chamado no `main.dart`
- Já está configurado no projeto

## Resumo dos Comandos

```bash
# 1. Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# 2. Login no Firebase
firebase login

# 3. Configurar projeto
flutterfire configure

# 4. Executar app
flutter run
```

## Próximos Passos Após Configuração

Após configurar com sucesso:
1. As regras do Database devem ser ajustadas para produção
2. Configure índices se necessário para queries complexas
3. Adicione tratamento de erros mais robusto
4. Configure Analytics (opcional)

## Links Úteis

- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Authentication](https://firebase.google.com/docs/auth)
- [Realtime Database](https://firebase.google.com/docs/database)
