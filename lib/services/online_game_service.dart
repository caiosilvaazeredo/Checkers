import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/game_model.dart';
import '../models/user_model.dart';

enum OnlineGameStatus { waiting, active, finished }
enum MatchmakingStatus { idle, searching, found, inGame }

class OnlinePlayer {
  final String uid;
  final String username;
  final int rating;
  final bool connected;

  OnlinePlayer({
    required this.uid,
    required this.username,
    required this.rating,
    this.connected = true,
  });

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'username': username,
        'rating': rating,
        'connected': connected,
      };

  factory OnlinePlayer.fromMap(Map<String, dynamic> map) => OnlinePlayer(
        uid: map['uid'] as String,
        username: map['username'] as String,
        rating: map['rating'] as int? ?? 1200,
        connected: map['connected'] as bool? ?? true,
      );
}

class OnlineGame {
  final String gameId;
  final OnlinePlayer redPlayer;
  final OnlinePlayer whitePlayer;
  final GameState gameState;
  final OnlineGameStatus status;
  final String? winner;
  final DateTime createdAt;
  final DateTime? lastMove;

  OnlineGame({
    required this.gameId,
    required this.redPlayer,
    required this.whitePlayer,
    required this.gameState,
    required this.status,
    this.winner,
    required this.createdAt,
    this.lastMove,
  });

  Map<String, dynamic> toMap() => {
        'gameId': gameId,
        'players': {
          'red': redPlayer.toMap(),
          'white': whitePlayer.toMap(),
        },
        'gameState': _gameStateToMap(gameState),
        'status': status.name,
        'winner': winner,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'lastMove': lastMove?.millisecondsSinceEpoch,
      };

  static Map<String, dynamic> _gameStateToMap(GameState state) {
    return {
      'board': state.board
          .map((row) => row
              .map((piece) => piece == null
                  ? null
                  : {
                      'color': piece.color.name,
                      'type': piece.type.name,
                    })
              .toList())
          .toList(),
      'turn': state.turn.name,
      'history': state.history,
      'variant': state.variant.name,
      'winner': state.winner?.name,
    };
  }

  factory OnlineGame.fromMap(Map<String, dynamic> map) {
    return OnlineGame(
      gameId: map['gameId'] as String,
      redPlayer: OnlinePlayer.fromMap(
          Map<String, dynamic>.from(map['players']['red'])),
      whitePlayer: OnlinePlayer.fromMap(
          Map<String, dynamic>.from(map['players']['white'])),
      gameState: _gameStateFromMap(Map<String, dynamic>.from(map['gameState'])),
      status: OnlineGameStatus.values
          .firstWhere((s) => s.name == map['status']),
      winner: map['winner'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      lastMove: map['lastMove'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastMove'] as int)
          : null,
    );
  }

  static GameState _gameStateFromMap(Map<String, dynamic> map) {
    final boardList = map['board'] as List;
    final board = boardList.map((row) {
      final rowList = row as List;
      return rowList.map((cell) {
        if (cell == null) return null;
        final cellMap = cell as Map;
        return Piece(
          color: PlayerColor.values.firstWhere((c) => c.name == cellMap['color']),
          type: PieceType.values.firstWhere((t) => t.name == cellMap['type']),
        );
      }).toList();
    }).toList();

    return GameState(
      board: board,
      turn: PlayerColor.values.firstWhere((c) => c.name == map['turn']),
      history: List<String>.from(map['history'] ?? []),
      variant: GameVariant.values.firstWhere((v) => v.name == map['variant']),
      mode: GameMode.online,
      winner: map['winner'] != null
          ? PlayerColor.values.firstWhere((c) => c.name == map['winner'])
          : null,
    );
  }
}

class GameInvite {
  final String inviteId;
  final AppUser fromUser;
  final AppUser toUser;
  final GameVariant variant;
  final String status; // pending, accepted, declined
  final DateTime timestamp;

  GameInvite({
    required this.inviteId,
    required this.fromUser,
    required this.toUser,
    required this.variant,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'inviteId': inviteId,
        'fromUser': fromUser.toMap(),
        'toUser': toUser.toMap(),
        'variant': variant.name,
        'status': status,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory GameInvite.fromMap(Map<String, dynamic> map) {
    return GameInvite(
      inviteId: map['inviteId'] as String,
      fromUser: AppUser.fromMap(Map<String, dynamic>.from(map['fromUser'])),
      toUser: AppUser.fromMap(Map<String, dynamic>.from(map['toUser'])),
      variant: GameVariant.values.firstWhere((v) => v.name == map['variant']),
      status: map['status'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
    );
  }
}

class OnlineGameService extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final _uuid = const Uuid();

  MatchmakingStatus _matchmakingStatus = MatchmakingStatus.idle;
  OnlineGame? _currentGame;
  PlayerColor? _myColor;
  StreamSubscription? _gameListener;
  StreamSubscription? _matchmakingListener;
  List<GameInvite> _pendingInvites = [];
  StreamSubscription? _invitesListener;

  MatchmakingStatus get matchmakingStatus => _matchmakingStatus;
  OnlineGame? get currentGame => _currentGame;
  PlayerColor? get myColor => _myColor;
  List<GameInvite> get pendingInvites => _pendingInvites;

  // Start matchmaking
  Future<void> startMatchmaking(AppUser user, GameVariant variant) async {
    try {
      debugPrint('🔍 Starting matchmaking for ${user.username}...');
      _matchmakingStatus = MatchmakingStatus.searching;
      notifyListeners();

      // Add user to matchmaking queue
      await _db.ref('matchmaking_queue/${user.uid}').set({
        'uid': user.uid,
        'username': user.username,
        'rating': user.rating,
        'variant': variant.name,
        'timestamp': ServerValue.timestamp,
      });

      // Listen for match
      _matchmakingListener = _db
          .ref('matchmaking_queue')
          .onValue
          .listen((event) => _checkForMatch(user, variant));

      debugPrint('✅ Added to matchmaking queue');
    } catch (e) {
      debugPrint('❌ Error starting matchmaking: $e');
      _matchmakingStatus = MatchmakingStatus.idle;
      notifyListeners();
    }
  }

  Future<void> _checkForMatch(AppUser user, GameVariant variant) async {
    try {
      final snapshot = await _db.ref('matchmaking_queue').get();
      if (!snapshot.exists) return;

      final queueMap = Map<String, dynamic>.from(snapshot.value as Map);
      final players = queueMap.entries
          .where((e) =>
              e.key != user.uid &&
              e.value['variant'] == variant.name)
          .toList();

      if (players.isNotEmpty) {
        // Found a match!
        final opponent = players.first.value;
        debugPrint('🎮 Match found! vs ${opponent['username']}');

        // Remove both players from queue
        await _db.ref('matchmaking_queue/${user.uid}').remove();
        await _db.ref('matchmaking_queue/${opponent['uid']}').remove();

        // Create game (only the first player creates it to avoid duplicates)
        if (user.uid.compareTo(opponent['uid']) < 0) {
          await _createGame(user, opponent, variant);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking for match: $e');
    }
  }

  Future<void> _createGame(
      AppUser user, Map<String, dynamic> opponentData, GameVariant variant) async {
    try {
      final gameId = _uuid.v4();

      // Randomly assign colors
      final userIsRed = DateTime.now().millisecond % 2 == 0;
      final redPlayer = userIsRed
          ? OnlinePlayer(
              uid: user.uid, username: user.username, rating: user.rating)
          : OnlinePlayer(
              uid: opponentData['uid'],
              username: opponentData['username'],
              rating: opponentData['rating'] ?? 1200);
      final whitePlayer = userIsRed
          ? OnlinePlayer(
              uid: opponentData['uid'],
              username: opponentData['username'],
              rating: opponentData['rating'] ?? 1200)
          : OnlinePlayer(
              uid: user.uid, username: user.username, rating: user.rating);

      final initialBoard = _createInitialBoard();
      final gameState = GameState(
        board: initialBoard,
        variant: variant,
        mode: GameMode.online,
      );

      final game = OnlineGame(
        gameId: gameId,
        redPlayer: redPlayer,
        whitePlayer: whitePlayer,
        gameState: gameState,
        status: OnlineGameStatus.active,
        createdAt: DateTime.now(),
      );

      await _db.ref('active_games/$gameId').set(game.toMap());

      // Store game reference for both players
      await _db.ref('user_games/${user.uid}/$gameId').set(true);
      await _db.ref('user_games/${opponentData['uid']}/$gameId').set(true);

      debugPrint('✅ Game created: $gameId');
    } catch (e) {
      debugPrint('❌ Error creating game: $e');
    }
  }

  List<List<Piece?>> _createInitialBoard() {
    final board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) {
          if (r < 3) board[r][c] = const Piece(color: PlayerColor.white);
          if (r > 4) board[r][c] = const Piece(color: PlayerColor.red);
        }
      }
    }
    return board;
  }

  // Cancel matchmaking
  Future<void> cancelMatchmaking(String userId) async {
    try {
      await _db.ref('matchmaking_queue/$userId').remove();
      await _matchmakingListener?.cancel();
      _matchmakingListener = null;
      _matchmakingStatus = MatchmakingStatus.idle;
      notifyListeners();
      debugPrint('🚫 Matchmaking cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling matchmaking: $e');
    }
  }

  // Join game and listen for updates
  Future<void> joinGame(String gameId, String userId) async {
    try {
      debugPrint('🎮 Joining game: $gameId');

      final snapshot = await _db.ref('active_games/$gameId').get();
      if (!snapshot.exists) {
        debugPrint('❌ Game not found');
        return;
      }

      final gameData = Map<String, dynamic>.from(snapshot.value as Map);
      _currentGame = OnlineGame.fromMap(gameData);

      // Determine my color
      if (_currentGame!.redPlayer.uid == userId) {
        _myColor = PlayerColor.red;
      } else if (_currentGame!.whitePlayer.uid == userId) {
        _myColor = PlayerColor.white;
      }

      _matchmakingStatus = MatchmakingStatus.inGame;

      // Listen for game updates
      _gameListener = _db.ref('active_games/$gameId').onValue.listen((event) {
        if (event.snapshot.exists) {
          final gameData = Map<String, dynamic>.from(event.snapshot.value as Map);
          _currentGame = OnlineGame.fromMap(gameData);
          notifyListeners();
        }
      });

      // Mark as connected
      await _updatePlayerConnection(gameId, userId, true);

      notifyListeners();
      debugPrint('✅ Joined game as ${_myColor?.name}');
    } catch (e) {
      debugPrint('❌ Error joining game: $e');
    }
  }

  Future<void> _updatePlayerConnection(
      String gameId, String userId, bool connected) async {
    try {
      final snapshot = await _db.ref('active_games/$gameId').get();
      if (!snapshot.exists) return;

      final gameData = Map<String, dynamic>.from(snapshot.value as Map);
      final players = gameData['players'];

      if (players['red']['uid'] == userId) {
        await _db
            .ref('active_games/$gameId/players/red/connected')
            .set(connected);
      } else if (players['white']['uid'] == userId) {
        await _db
            .ref('active_games/$gameId/players/white/connected')
            .set(connected);
      }
    } catch (e) {
      debugPrint('❌ Error updating connection: $e');
    }
  }

  // Make a move
  Future<void> makeMove(Move move) async {
    if (_currentGame == null || _myColor == null) return;
    if (_currentGame!.gameState.turn != _myColor) return;

    try {
      debugPrint('📤 Sending move: ${move.toNotation()}');

      // Apply move locally (will be updated by listener)
      final newGameState = _applyMove(_currentGame!.gameState, move);

      await _db.ref('active_games/${_currentGame!.gameId}/gameState').set(
            OnlineGame._gameStateToMap(newGameState),
          );

      await _db
          .ref('active_games/${_currentGame!.gameId}/lastMove')
          .set(ServerValue.timestamp);

      debugPrint('✅ Move sent');
    } catch (e) {
      debugPrint('❌ Error making move: $e');
    }
  }

  GameState _applyMove(GameState state, Move move) {
    final newBoard = state.board.map((r) => r.toList()).toList();
    var piece = newBoard[move.from.row][move.from.col]!;

    newBoard[move.to.row][move.to.col] = piece;
    newBoard[move.from.row][move.from.col] = null;

    if (move.capturedPos != null) {
      newBoard[move.capturedPos!.row][move.capturedPos!.col] = null;
    }

    // Check for promotion
    if (piece.type == PieceType.man) {
      if ((piece.color == PlayerColor.red && move.to.row == 0) ||
          (piece.color == PlayerColor.white && move.to.row == 7)) {
        newBoard[move.to.row][move.to.col] = piece.promote();
      }
    }

    final newHistory = [...state.history, move.toNotation()];
    final nextTurn =
        state.turn == PlayerColor.red ? PlayerColor.white : PlayerColor.red;

    return GameState(
      board: newBoard,
      turn: nextTurn,
      history: newHistory,
      variant: state.variant,
      mode: GameMode.online,
    );
  }

  // Send game invite to friend
  Future<void> sendGameInvite(
      AppUser fromUser, AppUser toUser, GameVariant variant) async {
    try {
      final inviteId = _uuid.v4();
      final invite = GameInvite(
        inviteId: inviteId,
        fromUser: fromUser,
        toUser: toUser,
        variant: variant,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      await _db
          .ref('game_invites/${toUser.uid}/$inviteId')
          .set(invite.toMap());

      debugPrint('📧 Game invite sent to ${toUser.username}');
    } catch (e) {
      debugPrint('❌ Error sending invite: $e');
    }
  }

  // Listen for invites
  void listenForInvites(String userId) {
    _invitesListener = _db.ref('game_invites/$userId').onValue.listen((event) {
      if (event.snapshot.exists) {
        final invitesMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        _pendingInvites = invitesMap.entries
            .map((e) =>
                GameInvite.fromMap(Map<String, dynamic>.from(e.value as Map)))
            .where((invite) => invite.status == 'pending')
            .toList();
        notifyListeners();
      } else {
        _pendingInvites = [];
        notifyListeners();
      }
    });
  }

  // Accept invite
  Future<void> acceptInvite(GameInvite invite) async {
    try {
      // Update invite status
      await _db
          .ref('game_invites/${invite.toUser.uid}/${invite.inviteId}/status')
          .set('accepted');

      // Create game
      final gameId = _uuid.v4();
      final redPlayer = OnlinePlayer(
        uid: invite.fromUser.uid,
        username: invite.fromUser.username,
        rating: invite.fromUser.rating,
      );
      final whitePlayer = OnlinePlayer(
        uid: invite.toUser.uid,
        username: invite.toUser.username,
        rating: invite.toUser.rating,
      );

      final initialBoard = _createInitialBoard();
      final gameState = GameState(
        board: initialBoard,
        variant: invite.variant,
        mode: GameMode.online,
      );

      final game = OnlineGame(
        gameId: gameId,
        redPlayer: redPlayer,
        whitePlayer: whitePlayer,
        gameState: gameState,
        status: OnlineGameStatus.active,
        createdAt: DateTime.now(),
      );

      await _db.ref('active_games/$gameId').set(game.toMap());

      // Store game reference for both players
      await _db.ref('user_games/${invite.fromUser.uid}/$gameId').set(true);
      await _db.ref('user_games/${invite.toUser.uid}/$gameId').set(true);

      // Join the game
      await joinGame(gameId, invite.toUser.uid);

      debugPrint('✅ Invite accepted, game created: $gameId');
    } catch (e) {
      debugPrint('❌ Error accepting invite: $e');
    }
  }

  // Decline invite
  Future<void> declineInvite(GameInvite invite) async {
    try {
      await _db
          .ref('game_invites/${invite.toUser.uid}/${invite.inviteId}/status')
          .set('declined');
      debugPrint('🚫 Invite declined');
    } catch (e) {
      debugPrint('❌ Error declining invite: $e');
    }
  }

  // Leave game
  Future<void> leaveGame(String userId) async {
    if (_currentGame == null) return;

    try {
      await _updatePlayerConnection(_currentGame!.gameId, userId, false);
      await _gameListener?.cancel();
      _gameListener = null;
      _currentGame = null;
      _myColor = null;
      _matchmakingStatus = MatchmakingStatus.idle;
      notifyListeners();
      debugPrint('👋 Left game');
    } catch (e) {
      debugPrint('❌ Error leaving game: $e');
    }
  }

  // Get user's active games
  Future<List<OnlineGame>> getUserGames(String userId) async {
    try {
      final gamesSnapshot = await _db.ref('user_games/$userId').get();
      if (!gamesSnapshot.exists) return [];

      final gameIds = Map<String, dynamic>.from(gamesSnapshot.value as Map).keys;
      final games = <OnlineGame>[];

      for (final gameId in gameIds) {
        final gameSnapshot = await _db.ref('active_games/$gameId').get();
        if (gameSnapshot.exists) {
          final gameData = Map<String, dynamic>.from(gameSnapshot.value as Map);
          games.add(OnlineGame.fromMap(gameData));
        }
      }

      return games;
    } catch (e) {
      debugPrint('❌ Error getting user games: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _gameListener?.cancel();
    _matchmakingListener?.cancel();
    _invitesListener?.cancel();
    super.dispose();
  }
}
