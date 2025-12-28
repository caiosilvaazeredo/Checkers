# Guia: Criar Usuário Mestre no Firebase

## Método 1: Criar Usuário Diretamente no Firebase Console (Mais Rápido)

### Passo 1: Criar Conta de Autenticação

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto **checkers-27bb3**
3. No menu lateral, vá em **Build** → **Authentication**
4. Clique na aba **Users**
5. Clique no botão **Add user**
6. Preencha:
   - **Email:** `admin@checkers.com`
   - **Password:** `admin123`
7. Clique em **Add user**

### Passo 2: Copiar o UID do Usuário

1. Ainda na tela de **Users**, você verá o usuário recém-criado
2. **Copie o UID** (User UID) - será algo como: `a1b2c3d4e5f6g7h8i9j0k1l2`

### Passo 3: Criar Dados do Usuário no Realtime Database

1. No menu lateral, vá em **Build** → **Realtime Database**
2. Você verá a estrutura do database (provavelmente vazio)
3. Clique no **+** ao lado de `checkers-27bb3-default-rtdb` (raiz do database)
4. Crie a seguinte estrutura:

   ```
   Name: users
   Value: (deixe vazio, vai criar outro nível)
   ```
   Clique no **+**

5. Dentro de `users`, clique no **+** novamente:
   ```
   Name: COLE_O_UID_AQUI (ex: a1b2c3d4e5f6g7h8i9j0k1l2)
   Value: (deixe vazio, vai criar os campos)
   ```

6. Dentro do UID do usuário, adicione os seguintes campos (clique no **+** para cada um):

   | Nome | Tipo | Valor |
   |------|------|-------|
   | uid | string | COLE_O_UID_AQUI (mesmo do passo anterior) |
   | email | string | admin@checkers.com |
   | username | string | Admin |
   | rating | number | 1000 |
   | gamesPlayed | number | 0 |
   | wins | number | 0 |
   | losses | number | 0 |
   | draws | number | 0 |

**Exemplo visual da estrutura:**
```
users/
  └─ a1b2c3d4e5f6g7h8i9j0k1l2/
       ├─ uid: "a1b2c3d4e5f6g7h8i9j0k1l2"
       ├─ email: "admin@checkers.com"
       ├─ username: "Admin"
       ├─ rating: 1000
       ├─ gamesPlayed: 0
       ├─ wins: 0
       ├─ losses: 0
       └─ draws: 0
```

### Passo 4: Testar Login

1. Volte para o app Flutter
2. Use as credenciais:
   - **Email:** `admin@checkers.com`
   - **Password:** `admin123`
3. Clique em **Log In**

## Método 2: Criar via Script (Alternativo)

Se você tiver acesso ao Firebase Admin SDK, pode criar o usuário via script. Mas o método acima é mais rápido.

## Verificar Regras de Segurança do Database

Se ainda não funcionar, verifique as regras:

1. Vá em **Realtime Database** → **Rules**
2. Use estas regras (APENAS PARA DESENVOLVIMENTO):

```json
{
  "rules": {
    ".read": "auth != null",
    ".write": "auth != null",
    "users": {
      "$uid": {
        ".read": "auth != null",
        ".write": "auth != null && auth.uid == $uid"
      }
    }
  }
}
```

3. Clique em **Publish**

## Credenciais do Usuário Mestre

Após criar:
- **Email:** `admin@checkers.com`
- **Password:** `admin123`
- **Username:** Admin

## Troubleshooting

### Se não conseguir fazer login:

1. **Verifique o console do navegador:**
   - Pressione `F12` para abrir DevTools
   - Vá na aba **Console**
   - Procure por erros em vermelho
   - Me envie a mensagem de erro

2. **Verifique se o usuário foi criado:**
   - Firebase Console → Authentication → Users
   - Deve aparecer `admin@checkers.com`

3. **Verifique o Database:**
   - Firebase Console → Realtime Database
   - Deve existir: `users/UID_DO_USUARIO/`

4. **Teste direto no console do navegador:**
   - Pressione `F12`
   - Vá na aba **Console**
   - Digite e execute:
   ```javascript
   firebase.auth().signInWithEmailAndPassword('admin@checkers.com', 'admin123')
     .then(user => console.log('Login OK:', user))
     .catch(error => console.log('Erro:', error));
   ```

## Próximos Passos Após Login

Se o login funcionar, você poderá:
1. Navegar pelo app
2. Testar as funcionalidades
3. Ver os dados sendo salvos no Realtime Database
4. Podemos então investigar o problema do cadastro/login normal
