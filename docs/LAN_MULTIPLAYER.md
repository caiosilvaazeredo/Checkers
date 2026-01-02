# Jogo Local (LAN) - Sistema Multiplayer

## 📋 Visão Geral

O sistema de jogo LAN (Local Area Network) permite que jogadores na mesma rede Wi-Fi joguem damas juntos de forma casual, sem afetar seu ranking ou estatísticas online. Este sistema foi inspirado em jogos da Nintendo como Mario Party, onde os jogadores podem facilmente descobrir e se conectar a partidas na mesma rede local.

## ✨ Características

- **🎮 Jogo Casual**: Partidas não ranqueadas que não afetam seu rating
- **🔍 Descoberta Automática**: Encontre jogos disponíveis na rede local automaticamente
- **📡 UDP Multicast**: Usa descoberta multicast para anunciar e encontrar jogos
- **🔌 TCP Sockets**: Comunicação confiável via TCP para sincronização de jogo
- **🎯 Zero Configuração**: Não precisa digitar IPs ou configurar portas
- **⚡ Baixa Latência**: Comunicação direta peer-to-peer sem servidor central
- **🛡️ Offline**: Funciona completamente sem internet, apenas Wi-Fi local necessário

## 🎯 Como Usar

### Hospedar um Jogo

1. Abra o app e faça login
2. No menu principal, toque em **"Jogo Local (LAN)"**
3. Digite seu nome (opcional)
4. Selecione a variante do jogo (Americanas ou Brasileiras)
5. Toque em **"Hospedar Jogo"**
6. Aguarde outro jogador se conectar
7. O jogo inicia automaticamente quando alguém entrar!

### Entrar em um Jogo

1. Abra o app e faça login
2. No menu principal, toque em **"Jogo Local (LAN)"**
3. Digite seu nome (opcional)
4. Toque em **"Procurar Jogos"**
5. Aguarde a lista de jogos disponíveis aparecer
6. Toque em **"Entrar"** no jogo desejado
7. O jogo inicia automaticamente!

## 🔧 Detalhes Técnicos

### Arquitetura

```
┌─────────────────┐         ┌─────────────────┐
│   Host Device   │         │  Guest Device   │
│                 │         │                 │
│  ┌───────────┐  │         │  ┌───────────┐  │
│  │ LAN Game  │  │         │  │ LAN Game  │  │
│  │ Service   │  │         │  │ Service   │  │
│  └─────┬─────┘  │         │  └─────┬─────┘  │
│        │        │         │        │        │
│   UDP Multicast │◄────────┼────────┤ Discovery│
│   (Port 45123) │         │   Listener     │
│        │        │         │        │        │
│   TCP Server   │◄────────┼────────┤ TCP Client│
│   (Port 45124) │  Game   │   Connection   │
│                 │  Data   │                 │
└─────────────────┘         └─────────────────┘
```

### Portas de Rede

- **UDP 45123**: Descoberta de jogos via multicast (224.0.0.251)
- **TCP 45124**: Servidor de jogo do host

### Protocolo de Comunicação

#### Mensagens

1. **gameAdvertisement** (UDP Multicast)
   ```json
   {
     "type": "gameAdvertisement",
     "data": {
       "gameId": "uuid",
       "hostName": "Nome do Host",
       "hostIp": "192.168.1.100",
       "port": 45124,
       "variant": "american",
       "timestamp": "2024-01-01T00:00:00Z"
     }
   }
   ```

2. **joinRequest** (TCP)
   ```json
   {
     "type": "joinRequest",
     "data": {
       "playerName": "Nome do Jogador"
     }
   }
   ```

3. **joinAccepted** (TCP)
   ```json
   {
     "type": "joinAccepted",
     "data": {
       "color": "white"
     }
   }
   ```

4. **move** (TCP)
   ```json
   {
     "type": "move",
     "data": {
       "fromRow": 5,
       "fromCol": 0,
       "toRow": 4,
       "toCol": 1
     }
   }
   ```

5. **resign** (TCP)
   ```json
   {
     "type": "resign",
     "data": {}
   }
   ```

6. **disconnect** (TCP)
   ```json
   {
     "type": "disconnect",
     "data": {}
   }
   ```

### Fluxo de Conexão

#### Host

1. Gera ID único para o jogo (UUID)
2. Obtém IP local via Wi-Fi
3. Inicia servidor TCP na porta 45124
4. Inicia anúncio UDP multicast a cada 2 segundos
5. Aguarda conexão de guest
6. Aceita conexão e para anúncios
7. Envia `joinAccepted` com cor do jogador
8. Inicia jogo

#### Guest

1. Inicia escuta UDP multicast na porta 45123
2. Recebe anúncios de jogos disponíveis
3. Exibe lista de jogos na interface
4. Usuário seleciona jogo
5. Conecta ao IP:porta do host via TCP
6. Envia `joinRequest`
7. Recebe `joinAccepted`
8. Inicia jogo

### Sincronização de Jogo

- **Estado Inicial**: Ambos os jogadores inicializam o mesmo tabuleiro
- **Movimentos**: Cada movimento é enviado via TCP e aplicado em ambos os lados
- **Validação**: Lógica de jogo roda em ambos os dispositivos para validação
- **Detecção de Vitória**: Calculada localmente em ambos os dispositivos

### Classes Principais

#### `LanGameService`
Gerencia toda a lógica de rede e estado do jogo LAN.

**Principais Métodos:**
- `hostGame()`: Inicia servidor e anúncios
- `discoverGames()`: Inicia descoberta de jogos
- `joinGame(advertisement)`: Conecta a um jogo
- `sendMove(move)`: Envia movimento ao oponente
- `resign()`: Desiste do jogo
- `cleanup()`: Limpa recursos de rede

**Streams:**
- `moveStream`: Recebe movimentos do oponente
- `disconnectStream`: Notifica desconexões

#### `LanLobbyScreen`
Interface para hospedar ou entrar em jogos.

#### `LanGameAdvertisement`
Modelo de dados para anúncios de jogos na rede.

#### `LanMessage`
Modelo de dados para mensagens do protocolo.

## 🔍 Troubleshooting

### Jogos Não Aparecem na Lista

- ✅ Verifique se ambos os dispositivos estão na mesma rede Wi-Fi
- ✅ Certifique-se de que o firewall não está bloqueando portas UDP/TCP
- ✅ Toque em "Procurar Jogos" novamente para atualizar
- ✅ Verifique se o host ainda está aguardando jogadores

### Não Consegue Conectar ao Jogo

- ✅ Verifique se o host não cancelou a hospedagem
- ✅ Certifique-se de que as portas 45123 e 45124 não estão em uso
- ✅ Reinicie o app em ambos os dispositivos
- ✅ Verifique configurações de rede Wi-Fi (algumas redes corporativas bloqueiam comunicação peer-to-peer)

### Desconexão Durante o Jogo

- ✅ Verifique a estabilidade da conexão Wi-Fi
- ✅ Certifique-se de que nenhum dispositivo está entrando em modo de economia de energia
- ✅ Evite sair do app durante o jogo

### Permissões Necessárias

#### Android
Adicione ao `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### iOS
Adicione ao `Info.plist`:
```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Este app precisa acessar a rede local para encontrar jogos LAN.</string>
<key>NSBonjourServices</key>
<array>
    <string>_checkers._tcp</string>
</array>
```

## 🎨 Interface

### Tela de Lobby
- Campo de nome do jogador
- Seleção de variante (Americanas/Brasileiras)
- Botão "Hospedar Jogo"
- Botão "Procurar Jogos"
- Lista de jogos disponíveis (quando em modo descoberta)
- Badge "Casual - não afeta seu ranking"

### Tela de Jogo
- Badge "Casual" no título
- Indicador de Host/Guest nos perfis dos jogadores
- Mesmo tabuleiro e controles do modo online
- Mensagem de vitória com lembrete de jogo casual

## 📊 Diferenças em Relação ao Modo Online

| Característica | Online | LAN |
|----------------|--------|-----|
| Requer Internet | ✅ Sim | ❌ Não |
| Afeta Ranking | ✅ Sim | ❌ Não |
| Servidor Central | ✅ Firebase | ❌ Peer-to-peer |
| Descoberta | ✅ Matchmaking | ✅ Multicast |
| Latência | 🌐 Média | ⚡ Muito baixa |
| Histórico Salvo | ✅ Sim | ❌ Não |

## 🚀 Melhorias Futuras

- [ ] Suporte para mais de 2 jogadores (modo espectador)
- [ ] Chat de texto durante o jogo
- [ ] Histórico local de partidas LAN
- [ ] Bluetooth como alternativa ao Wi-Fi
- [ ] Reconexão automática em caso de queda
- [ ] Modo torneio LAN
- [ ] Customização de avatares para jogadores LAN

## 📝 Notas de Desenvolvimento

### Dependências
```yaml
network_info_plus: ^6.0.0  # Para obter IP local
```

### Arquivos Modificados/Criados
- `lib/models/game_model.dart` - Adicionado `GameMode.lan`
- `lib/models/lan_game_model.dart` - Novos modelos de dados LAN
- `lib/services/lan_game_service.dart` - Serviço principal LAN
- `lib/screens/lan/lan_lobby_screen.dart` - Interface de lobby
- `lib/screens/game/game_screen.dart` - Adicionado suporte para modo LAN
- `lib/screens/home/home_screen.dart` - Adicionado botão LAN
- `lib/main.dart` - Adicionado `LanGameService` ao Provider

---

**Desenvolvido com ❤️ para jogadores casuais que querem se divertir sem pressão de ranking!**
