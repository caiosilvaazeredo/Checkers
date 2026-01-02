import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../models/game_model.dart';
import '../models/lan_game_model.dart';

/// Serviço de jogo LAN - Similar ao sistema do Mario Party
/// Permite descobrir e conectar a jogos na rede local sem ranking
class LanGameService extends ChangeNotifier {
  static const int discoveryPort = 45123;
  static const int gamePortStart = 45124;
  static const String multicastAddress = '224.0.0.251';

  LanConnectionStatus _status = LanConnectionStatus.disconnected;
  List<LanGameAdvertisement> _availableGames = [];
  String? _currentGameId;
  String? _hostIp;
  int? _gamePort;
  ServerSocket? _gameServer;
  Socket? _gameSocket;
  RawDatagramSocket? _discoverySocket;
  Timer? _advertisementTimer;
  Timer? _cleanupTimer;

  String _playerName = 'Jogador';
  GameVariant _selectedVariant = GameVariant.american;
  PlayerColor? _myColor;
  bool _isHost = false;

  GameState? _gameState;
  final StreamController<Move> _moveController = StreamController<Move>.broadcast();
  final StreamController<String> _disconnectController = StreamController<String>.broadcast();

  // Getters
  LanConnectionStatus get status => _status;
  List<LanGameAdvertisement> get availableGames => List.unmodifiable(_availableGames);
  String? get currentGameId => _currentGameId;
  PlayerColor? get myColor => _myColor;
  bool get isHost => _isHost;
  GameState? get gameState => _gameState;
  Stream<Move> get moveStream => _moveController.stream;
  Stream<String> get disconnectStream => _disconnectController.stream;

  void setPlayerName(String name) {
    _playerName = name;
  }

  void setVariant(GameVariant variant) {
    _selectedVariant = variant;
  }

  /// Inicia o servidor de descoberta e anuncia o jogo
  Future<bool> hostGame() async {
    try {
      _status = LanConnectionStatus.hosting;
      notifyListeners();

      // Gera ID único para o jogo
      _currentGameId = const Uuid().v4();
      _isHost = true;
      _myColor = PlayerColor.red; // Host sempre é vermelho

      // Obtém IP local
      final networkInfo = NetworkInfo();
      final wifiIp = await networkInfo.getWifiIP();

      if (wifiIp == null) {
        throw Exception('Não foi possível obter o IP local. Verifique se está conectado ao Wi-Fi.');
      }

      _hostIp = wifiIp;

      // Inicia servidor de jogo
      _gamePort = gamePortStart;
      _gameServer = await ServerSocket.bind(InternetAddress.anyIPv4, _gamePort!);

      debugPrint('🎮 Servidor de jogo iniciado em $_hostIp:$_gamePort');

      // Aguarda conexão do oponente
      _gameServer!.listen((socket) async {
        debugPrint('👤 Oponente conectado: ${socket.remoteAddress.address}');
        _gameSocket = socket;
        _stopAdvertising();

        // Envia confirmação de entrada
        _sendMessage(LanMessage(
          type: LanMessageType.joinAccepted,
          data: {'color': PlayerColor.white.name},
        ));

        // Escuta mensagens do oponente
        _listenToSocket(socket);

        // Atualiza status
        _status = LanConnectionStatus.connected;
        notifyListeners();

        // Inicia o jogo
        _initializeGameState();
      });

      // Inicia descoberta multicast
      await _startDiscovery();

      // Inicia timer para anunciar o jogo periodicamente
      _startAdvertising();

      return true;
    } catch (e) {
      debugPrint('❌ Erro ao hospedar jogo: $e');
      await cleanup();
      return false;
    }
  }

  /// Inicia a descoberta de jogos na rede local
  Future<void> discoverGames() async {
    try {
      _status = LanConnectionStatus.discovering;
      _availableGames.clear();
      notifyListeners();

      await _startDiscovery();

      // Timer para limpar jogos expirados
      _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _availableGames.removeWhere((game) => game.isExpired());
        notifyListeners();
      });
    } catch (e) {
      debugPrint('❌ Erro ao descobrir jogos: $e');
      _status = LanConnectionStatus.disconnected;
      notifyListeners();
    }
  }

  /// Conecta a um jogo específico
  Future<bool> joinGame(LanGameAdvertisement game) async {
    try {
      _status = LanConnectionStatus.connecting;
      notifyListeners();

      _currentGameId = game.gameId;
      _isHost = false;
      _myColor = PlayerColor.white; // Guest sempre é branco
      _selectedVariant = game.variant;

      // Conecta ao servidor do jogo
      _gameSocket = await Socket.connect(game.hostIp, game.port);
      debugPrint('🔌 Conectado ao jogo: ${game.hostName}');

      // Envia solicitação de entrada
      _sendMessage(LanMessage(
        type: LanMessageType.joinRequest,
        data: {'playerName': _playerName},
      ));

      // Escuta mensagens do host
      _listenToSocket(_gameSocket!);

      _status = LanConnectionStatus.connected;
      notifyListeners();

      // Fecha descoberta
      await _stopDiscovery();

      return true;
    } catch (e) {
      debugPrint('❌ Erro ao entrar no jogo: $e');
      await cleanup();
      return false;
    }
  }

  /// Inicia a descoberta multicast
  Future<void> _startDiscovery() async {
    _discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
    _discoverySocket!.broadcastEnabled = true;
    _discoverySocket!.multicastLoopback = false;

    // Join multicast group
    try {
      _discoverySocket!.joinMulticast(InternetAddress(multicastAddress));
    } catch (e) {
      debugPrint('⚠️ Aviso: Não foi possível entrar no grupo multicast: $e');
    }

    _discoverySocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _discoverySocket!.receive();
        if (datagram != null) {
          try {
            final message = utf8.decode(datagram.data);
            final json = jsonDecode(message) as Map<String, dynamic>;
            final lanMessage = LanMessage.fromJson(json);

            if (lanMessage.type == LanMessageType.gameAdvertisement) {
              final game = LanGameAdvertisement.fromJson(lanMessage.data);

              // Ignora nosso próprio anúncio
              if (game.gameId == _currentGameId) return;

              // Atualiza ou adiciona jogo
              final index = _availableGames.indexWhere((g) => g.gameId == game.gameId);
              if (index >= 0) {
                _availableGames[index] = game;
              } else {
                _availableGames.add(game);
              }
              notifyListeners();
            }
          } catch (e) {
            debugPrint('⚠️ Erro ao processar pacote de descoberta: $e');
          }
        }
      }
    });
  }

  /// Inicia o anúncio periódico do jogo
  void _startAdvertising() {
    _advertisementTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _advertiseGame();
    });
  }

  /// Anuncia o jogo via multicast
  void _advertiseGame() {
    if (_discoverySocket == null || _currentGameId == null) return;

    final advertisement = LanGameAdvertisement(
      gameId: _currentGameId!,
      hostName: _playerName,
      hostIp: _hostIp!,
      port: _gamePort!,
      variant: _selectedVariant,
      timestamp: DateTime.now(),
    );

    final message = LanMessage(
      type: LanMessageType.gameAdvertisement,
      data: advertisement.toJson(),
    );

    final data = utf8.encode(jsonEncode(message.toJson()));
    _discoverySocket!.send(data, InternetAddress(multicastAddress), discoveryPort);
  }

  /// Para o anúncio do jogo
  void _stopAdvertising() {
    _advertisementTimer?.cancel();
    _advertisementTimer = null;
  }

  /// Para a descoberta
  Future<void> _stopDiscovery() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _discoverySocket?.close();
    _discoverySocket = null;
  }

  /// Escuta mensagens do socket
  void _listenToSocket(Socket socket) {
    socket.listen(
      (data) {
        try {
          final message = utf8.decode(data);
          final lines = message.split('\n').where((l) => l.trim().isNotEmpty);

          for (final line in lines) {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final lanMessage = LanMessage.fromJson(json);
            _handleMessage(lanMessage);
          }
        } catch (e) {
          debugPrint('⚠️ Erro ao processar mensagem: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Erro no socket: $error');
        _handleDisconnect();
      },
      onDone: () {
        debugPrint('🔌 Conexão encerrada');
        _handleDisconnect();
      },
    );
  }

  /// Processa mensagem recebida
  void _handleMessage(LanMessage message) {
    switch (message.type) {
      case LanMessageType.joinAccepted:
        debugPrint('✅ Entrada aceita no jogo');
        _initializeGameState();
        break;

      case LanMessageType.gameStart:
        debugPrint('🎮 Jogo iniciado');
        break;

      case LanMessageType.move:
        final fromRow = message.data['fromRow'] as int;
        final fromCol = message.data['fromCol'] as int;
        final toRow = message.data['toRow'] as int;
        final toCol = message.data['toCol'] as int;

        final move = Move(
          from: Position(fromRow, fromCol),
          to: Position(toRow, toCol),
        );

        _applyMove(move);
        _moveController.add(move);
        break;

      case LanMessageType.resign:
        debugPrint('🏳️ Oponente desistiu');
        _disconnectController.add('resign');
        break;

      case LanMessageType.disconnect:
        debugPrint('🔌 Oponente desconectou');
        _handleDisconnect();
        break;

      default:
        break;
    }
  }

  /// Envia uma mensagem
  void _sendMessage(LanMessage message) {
    if (_gameSocket == null) return;

    try {
      _gameSocket!.write(message.toJsonString());
    } catch (e) {
      debugPrint('❌ Erro ao enviar mensagem: $e');
    }
  }

  /// Envia um movimento e aplica localmente
  void sendMove(Move move) {
    // Aplica movimento localmente
    _applyMove(move);

    // Envia para o oponente
    _sendMessage(LanMessage(
      type: LanMessageType.move,
      data: {
        'fromRow': move.from.row,
        'fromCol': move.from.col,
        'toRow': move.to.row,
        'toCol': move.to.col,
      },
    ));
  }

  /// Aplica um movimento ao estado do jogo
  void _applyMove(Move move) {
    if (_gameState == null) return;

    final newBoard = List.generate(
      8,
      (r) => List.generate(8, (c) => _gameState!.board[r][c]),
    );

    final piece = newBoard[move.from.row][move.from.col];
    if (piece == null) return;

    // Move a peça
    newBoard[move.to.row][move.to.col] = piece;
    newBoard[move.from.row][move.from.col] = null;

    // Verifica captura
    final rowDiff = (move.to.row - move.from.row).abs();
    final colDiff = (move.to.col - move.from.col).abs();
    bool isCapture = false;

    if (rowDiff == 2 && colDiff == 2) {
      // É uma captura
      final capturedRow = (move.from.row + move.to.row) ~/ 2;
      final capturedCol = (move.from.col + move.to.col) ~/ 2;
      newBoard[capturedRow][capturedCol] = null;
      isCapture = true;
    }

    // Verifica promoção
    Piece? movedPiece = newBoard[move.to.row][move.to.col];
    if (movedPiece != null && !movedPiece.isKing) {
      if ((movedPiece.color == PlayerColor.red && move.to.row == 7) ||
          (movedPiece.color == PlayerColor.white && move.to.row == 0)) {
        newBoard[move.to.row][move.to.col] = movedPiece.promote();
      }
    }

    // Adiciona ao histórico
    final notation = move.toNotation();
    final newHistory = List<String>.from(_gameState!.history)..add(notation);

    // Alterna turno
    final newTurn = _gameState!.turn == PlayerColor.red
        ? PlayerColor.white
        : PlayerColor.red;

    // Verifica vitória
    PlayerColor? winner;
    if (!_hasValidMoves(newBoard, newTurn)) {
      winner = _gameState!.turn; // Quem moveu por último vence
    }

    _gameState = GameState(
      board: newBoard,
      turn: newTurn,
      history: newHistory,
      variant: _gameState!.variant,
      mode: GameMode.lan,
      winner: winner,
    );

    notifyListeners();
  }

  /// Verifica se um jogador tem movimentos válidos
  bool _hasValidMoves(List<List<Piece?>> board, PlayerColor color) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece == null || piece.color != color) continue;

        // Verifica movimentos simples
        final forward = color == PlayerColor.red ? 1 : -1;
        final dirs = piece.isKing
            ? [[-1, -1], [-1, 1], [1, -1], [1, 1]]
            : [[forward, -1], [forward, 1]];

        for (final dir in dirs) {
          final newR = r + dir[0];
          final newC = c + dir[1];

          if (newR >= 0 && newR < 8 && newC >= 0 && newC < 8) {
            if (board[newR][newC] == null) return true;

            // Verifica capturas
            final jumpR = r + dir[0] * 2;
            final jumpC = c + dir[1] * 2;
            if (jumpR >= 0 && jumpR < 8 && jumpC >= 0 && jumpC < 8) {
              if (board[newR][newC]?.color != color &&
                  board[jumpR][jumpC] == null) {
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  /// Desiste do jogo
  void resign() {
    _sendMessage(LanMessage(
      type: LanMessageType.resign,
      data: {},
    ));
    _disconnectController.add('resign');
  }

  /// Inicializa o estado do jogo
  void _initializeGameState() {
    _gameState = GameState(
      board: _createInitialBoard(),
      variant: _selectedVariant,
      mode: GameMode.lan,
    );
    notifyListeners();
  }

  /// Cria o tabuleiro inicial
  List<List<Piece?>> _createInitialBoard() {
    final board = List.generate(8, (_) => List<Piece?>.filled(8, null));

    // Peças vermelhas (top)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[row][col] = const Piece(color: PlayerColor.red);
        }
      }
    }

    // Peças brancas (bottom)
    for (int row = 5; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[row][col] = const Piece(color: PlayerColor.white);
        }
      }
    }

    return board;
  }

  /// Trata desconexão
  void _handleDisconnect() {
    _disconnectController.add('disconnect');
    cleanup();
  }

  /// Limpa recursos
  Future<void> cleanup() async {
    _stopAdvertising();
    await _stopDiscovery();

    _gameSocket?.close();
    _gameSocket = null;

    _gameServer?.close();
    _gameServer = null;

    _status = LanConnectionStatus.disconnected;
    _currentGameId = null;
    _gameState = null;
    _myColor = null;
    _isHost = false;

    notifyListeners();
  }

  @override
  void dispose() {
    cleanup();
    _moveController.close();
    _disconnectController.close();
    super.dispose();
  }
}
