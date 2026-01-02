import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game_model.dart';
import '../models/lan_game_model.dart';
import 'lan_backend.dart';
import 'firebase_lan_backend.dart';
import 'native_lan_backend.dart';

/// Serviço de jogo LAN - Similar ao sistema do Mario Party
/// Permite descobrir e conectar a jogos na rede local sem ranking
/// Usa Firebase como backend na web e sockets nativos em outras plataformas
class LanGameService extends ChangeNotifier {
  late final LanBackend _backend;

  LanConnectionStatus _status = LanConnectionStatus.disconnected;
  List<LanGameAdvertisement> _availableGames = [];
  String? _currentGameId;

  String _playerName = 'Jogador';
  GameVariant _selectedVariant = GameVariant.american;
  PlayerColor? _myColor;
  bool _isHost = false;

  GameState? _gameState;
  final StreamController<Move> _moveController = StreamController<Move>.broadcast();
  final StreamController<String> _disconnectController = StreamController<String>.broadcast();

  StreamSubscription? _gamesSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _disconnectSubscription;

  LanGameService() {
    // Seleciona backend baseado na plataforma
    if (kIsWeb) {
      debugPrint('🌐 Usando Firebase LAN backend (web)');
      _backend = FirebaseLanBackend();
    } else {
      debugPrint('📱 Usando Native LAN backend (mobile/desktop)');
      _backend = NativeLanBackend();
    }

    _setupBackendListeners();
  }

  void _setupBackendListeners() {
    // Escuta jogos disponíveis
    _gamesSubscription = _backend.gamesStream.listen((games) {
      _availableGames = games;
      notifyListeners();
    });

    // Escuta mensagens
    _messagesSubscription = _backend.messagesStream.listen((message) {
      _handleMessage(message);
    });

    // Escuta desconexões
    _disconnectSubscription = _backend.disconnectStream.listen((reason) {
      debugPrint('🔌 Desconectado: $reason');
      _disconnectController.add(reason);
      cleanup();
    });
  }

  // Getters
  LanConnectionStatus get status => _status;
  List<LanGameAdvertisement> get availableGames => List.unmodifiable(_availableGames);
  String? get currentGameId => _currentGameId;
  PlayerColor? get myColor => _myColor;
  bool get isHost => _isHost;
  GameState? get gameState => _gameState;
  Stream<Move> get moveStream => _moveController.stream;
  Stream<String> get disconnectStream => _disconnectController.stream;

  /// Verifica se a plataforma atual suporta multiplayer LAN
  /// Agora sempre retorna true, pois Firebase permite LAN na web
  bool get isPlatformSupported => true;

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

      final success = await _backend.hostGame(
        gameId: _currentGameId!,
        hostName: _playerName,
        variant: _selectedVariant,
      );

      if (success) {
        debugPrint('🎮 Jogo hospedado com sucesso: $_currentGameId');
        // Aguardar conexão do jogador para mudar para status "connected"
        // O status será atualizado quando receber joinRequest
        return true;
      } else {
        await cleanup();
        return false;
      }
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

      await _backend.discoverGames();
      debugPrint('🔍 Descoberta de jogos iniciada');
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

      final success = await _backend.joinGame(
        game: game,
        playerName: _playerName,
      );

      if (success) {
        // Aguarda confirmação do host
        // O status será atualizado quando receber joinAccepted
        return true;
      } else {
        await cleanup();
        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro ao entrar no jogo: $e');
      await cleanup();
      return false;
    }
  }

  /// Processa mensagem recebida
  void _handleMessage(LanMessage message) {
    switch (message.type) {
      case LanMessageType.joinRequest:
        debugPrint('👤 Jogador solicitou entrada');
        // Host aceita automaticamente
        if (_isHost) {
          _status = LanConnectionStatus.connected;
          notifyListeners();
          _initializeGameState();
        }
        break;

      case LanMessageType.joinAccepted:
        debugPrint('✅ Entrada aceita no jogo');
        _status = LanConnectionStatus.connected;
        notifyListeners();
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
        _disconnectController.add('disconnect');
        break;

      default:
        break;
    }
  }

  /// Envia um movimento e aplica localmente
  void sendMove(Move move) {
    // Aplica movimento localmente
    _applyMove(move);

    // Envia para o oponente
    _backend.sendMessage(LanMessage(
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
    _backend.sendMessage(LanMessage(
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

  /// Limpa recursos
  Future<void> cleanup() async {
    await _backend.stopDiscovery();
    await _backend.cleanup();

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
    _gamesSubscription?.cancel();
    _messagesSubscription?.cancel();
    _disconnectSubscription?.cancel();
    _moveController.close();
    _disconnectController.close();
    _backend.dispose();
    super.dispose();
  }
}
