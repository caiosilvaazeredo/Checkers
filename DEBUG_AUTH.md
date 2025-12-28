# Debug de Autenticação - Master Checkers

## Problema Atual

Login com email/senha e Google Sign-In não estão funcionando.

## Investigação Passo a Passo

### 1. Abrir DevTools do Navegador

1. Com o app aberto no Chrome, pressione **F12**
2. Vá na aba **Console**
3. Certifique-se de que está mostrando **todos os níveis** de log (não filtre Errors apenas)

### 2. Limpar Console e Tentar Cadastro

1. Clique com botão direito no console → **Clear console**
2. No app, tente criar uma nova conta:
   - Username: `teste123`
   - Email: `teste123@teste.com`
   - Password: `senha123`
3. Clique em **Sign Up**

**Observe o console:**
- Há algum erro em vermelho?
- Qual é a última mensagem antes de parar?
- Há alguma mensagem sobre Firebase Auth?

### 3. Verificar Network Tab

1. No DevTools, vá na aba **Network**
2. Clique em **Clear** para limpar
3. Tente fazer cadastro novamente
4. Procure por requisições para:
   - `identitytoolkit.googleapis.com` (Firebase Auth)
   - `firebaseio.com` (Realtime Database)

**Verificar status:**
- ✅ 200 = Sucesso
- ❌ 400/403/500 = Erro

### 4. Teste Manual via Console

Teste diretamente via JavaScript no console do navegador:

```javascript
// Teste 1: Verificar se Firebase está inicializado
console.log('Firebase Apps:', firebase.apps.length);

// Teste 2: Tentar criar usuário
firebase.auth().createUserWithEmailAndPassword('teste456@teste.com', 'senha123')
  .then(result => {
    console.log('✅ Usuário criado com sucesso!', result);
    console.log('UID:', result.user.uid);
  })
  .catch(error => {
    console.error('❌ Erro ao criar usuário:', error.code, error.message);
  });

// Teste 3: Verificar usuário atual
firebase.auth().onAuthStateChanged(user => {
  if (user) {
    console.log('✅ Usuário logado:', user.email, user.uid);
  } else {
    console.log('❌ Nenhum usuário logado');
  }
});
```

### 5. Verificar Regras do Database

1. Firebase Console → Realtime Database → **Rules**
2. Verifique se as regras permitem escrita

**Regras para desenvolvimento (temporário):**
```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null"
  }
}
```

**⚠️ ATENÇÃO:** Estas regras são MUITO permissivas. Use apenas para testar.

### 6. Cenários Possíveis e Soluções

#### Cenário A: Erro 400 "INVALID_EMAIL"
**Causa:** Email inválido
**Solução:** Use um email válido (ex: `teste@teste.com`)

#### Cenário B: Erro 400 "WEAK_PASSWORD"
**Causa:** Senha muito fraca
**Solução:** Use senha com pelo menos 6 caracteres

#### Cenário C: Erro 400 "EMAIL_EXISTS"
**Causa:** Email já cadastrado
**Solução:** Use outro email ou delete o usuário no Firebase Console

#### Cenário D: Erro 403 "PERMISSION_DENIED"
**Causa:** Regras do database bloqueando escrita
**Solução:** Ajuste as regras do database

#### Cenário E: Sem erros, mas nada acontece
**Causa:** Erro sendo capturado silenciosamente
**Solução:** Adicione logs no código (próxima seção)

### 7. Adicionar Logs no Código (se necessário)

Se precisarmos debugar mais profundamente, posso adicionar logs no `auth_service.dart`:

```dart
Future<bool> registerWithEmail(String email, String password, String username) async {
  try {
    print('🔍 DEBUG: Iniciando registro...');
    print('🔍 DEBUG: Email: $email');

    _isLoading = true;
    _error = null;
    notifyListeners();

    print('🔍 DEBUG: Chamando createUserWithEmailAndPassword...');
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    print('🔍 DEBUG: Usuário criado! UID: ${credential.user?.uid}');

    if (credential.user != null) {
      final user = AppUser(
        uid: credential.user!.uid,
        email: email,
        username: username,
      );

      print('🔍 DEBUG: Salvando no database...');
      await _db.ref('users/${user.uid}').set(user.toMap());

      print('🔍 DEBUG: Usuário salvo com sucesso!');
      _currentUser = user;
    }
    return true;
  } on FirebaseAuthException catch (e) {
    print('❌ DEBUG: Erro Firebase Auth: ${e.code} - ${e.message}');
    _error = _getErrorMessage(e.code);
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    print('❌ DEBUG: Erro genérico: $e');
    _error = 'An error occurred: $e';
    _isLoading = false;
    notifyListeners();
    return false;
  }
}
```

## O Que Enviar Para Mim

Para eu te ajudar melhor, me envie:

1. **Mensagens do Console** (após tentar cadastrar):
   - Copie TODAS as mensagens do console (Ctrl+A no console, Ctrl+C)

2. **Network Tab** (após tentar cadastrar):
   - Screenshot ou lista das requisições com status code

3. **Mensagem de erro** (se aparecer no app):
   - Qual mensagem aparece na tela?

4. **Resultado dos testes manuais** (do passo 4):
   - Copie a saída do console após executar os comandos

## Ação Imediata

1. **Crie o usuário mestre via Firebase Console** (veja CREATE_MASTER_USER.md)
2. **Execute os testes acima** e me envie os resultados
3. Com esses dados, vou identificar exatamente onde está o problema
