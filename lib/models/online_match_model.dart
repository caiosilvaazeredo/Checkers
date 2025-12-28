import 'game_model.dart';

enum MatchStatus {
  waiting,     // Aguardando segundo jogador
  active,      // Partida em andamento
  completed,   // Partida finalizada
  abandoned    // Partida abandonada
}

enum MatchEndReason {
  checkmate,   // Vitória por eliminação de peças
  resignation, // Desistência
  timeout,     // Timeout
  draw         // Empate acordado
}

class PlayerInfo {
  final String uid;
  final String username;
  final int rating;
  final PlayerColor color;

  const PlayerInfo({
    required this.uid,
    required this.username,
    required this.rating,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'username': username,
    'rating': rating,
    'color': color.toString().split('.').last,
  };

  factory PlayerInfo.fromMap(Map<String, dynamic> map) => PlayerInfo(
    uid: map['uid'] ?? '',
    username: map['username'] ?? 'Player',
    rating: map['rating'] ?? 1200,
    color: PlayerColor.values.firstWhere(
      (e) => e.toString().split('.').last == map['color'],
      orElse: () => PlayerColor.red,
    ),
  );
}

class OnlineMatch {
  final String matchId;
  final PlayerInfo? redPlayer;
  final PlayerInfo? whitePlayer;
  final MatchStatus status;
  final GameVariant variant;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime lastMoveAt;

  // Estado do jogo
  final List<List<String?>> board; // Serializado como string (ex: "red-man", "white-king")
  final PlayerColor currentTurn;
  final List<String> moveHistory;
  final String? winner; // UID do vencedor
  final MatchEndReason? endReason;

  // Controle de tempo
  final int? redPlayerTimeMs;
  final int? whitePlayerTimeMs;

  OnlineMatch({
    required this.matchId,
    this.redPlayer,
    this.whitePlayer,
    this.status = MatchStatus.waiting,
    this.variant = GameVariant.american,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
    DateTime? lastMoveAt,
    List<List<String?>>? board,
    this.currentTurn = PlayerColor.red,
    this.moveHistory = const [],
    this.winner,
    this.endReason,
    this.redPlayerTimeMs,
    this.whitePlayerTimeMs,
  }) : createdAt = createdAt ?? DateTime.now(),
       lastMoveAt = lastMoveAt ?? DateTime.now(),
       board = board ?? _createInitialBoard();

  static List<List<String?>> _createInitialBoard() {
    final board = List.generate(8, (_) => List<String?>.filled(8, null));

    // Peças vermelhas (linhas 0-2)
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[row][col] = 'red-man';
        }
      }
    }

    // Peças brancas (linhas 5-7)
    for (int row = 5; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        if ((row + col) % 2 == 1) {
          board[row][col] = 'white-man';
        }
      }
    }

    return board;
  }

  bool get isWaiting => status == MatchStatus.waiting;
  bool get isActive => status == MatchStatus.active;
  bool get isCompleted => status == MatchStatus.completed || status == MatchStatus.abandoned;
  bool get needsSecondPlayer => redPlayer == null || whitePlayer == null;

  String? getPlayerUid(PlayerColor color) {
    if (color == PlayerColor.red) return redPlayer?.uid;
    return whitePlayer?.uid;
  }

  PlayerInfo? getPlayerInfo(PlayerColor color) {
    if (color == PlayerColor.red) return redPlayer;
    return whitePlayer;
  }

  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'redPlayer': redPlayer?.toMap(),
    'whitePlayer': whitePlayer?.toMap(),
    'status': status.toString().split('.').last,
    'variant': variant.toString().split('.').last,
    'createdAt': createdAt.toIso8601String(),
    'startedAt': startedAt?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'lastMoveAt': lastMoveAt.toIso8601String(),
    'board': board,
    'currentTurn': currentTurn.toString().split('.').last,
    'moveHistory': moveHistory,
    'winner': winner,
    'endReason': endReason?.toString().split('.').last,
    'redPlayerTimeMs': redPlayerTimeMs,
    'whitePlayerTimeMs': whitePlayerTimeMs,
  };

  factory OnlineMatch.fromMap(Map<String, dynamic> map) => OnlineMatch(
    matchId: map['matchId'] ?? '',
    redPlayer: map['redPlayer'] != null
        ? PlayerInfo.fromMap(Map<String, dynamic>.from(map['redPlayer']))
        : null,
    whitePlayer: map['whitePlayer'] != null
        ? PlayerInfo.fromMap(Map<String, dynamic>.from(map['whitePlayer']))
        : null,
    status: MatchStatus.values.firstWhere(
      (e) => e.toString().split('.').last == map['status'],
      orElse: () => MatchStatus.waiting,
    ),
    variant: GameVariant.values.firstWhere(
      (e) => e.toString().split('.').last == map['variant'],
      orElse: () => GameVariant.american,
    ),
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : DateTime.now(),
    startedAt: map['startedAt'] != null
        ? DateTime.parse(map['startedAt'])
        : null,
    completedAt: map['completedAt'] != null
        ? DateTime.parse(map['completedAt'])
        : null,
    lastMoveAt: map['lastMoveAt'] != null
        ? DateTime.parse(map['lastMoveAt'])
        : DateTime.now(),
    board: (map['board'] as List?)
        ?.map((row) => List<String?>.from(row))
        .toList() ?? OnlineMatch._createInitialBoard(),
    currentTurn: PlayerColor.values.firstWhere(
      (e) => e.toString().split('.').last == map['currentTurn'],
      orElse: () => PlayerColor.red,
    ),
    moveHistory: List<String>.from(map['moveHistory'] ?? []),
    winner: map['winner'],
    endReason: map['endReason'] != null
        ? MatchEndReason.values.firstWhere(
            (e) => e.toString().split('.').last == map['endReason'],
          )
        : null,
    redPlayerTimeMs: map['redPlayerTimeMs'],
    whitePlayerTimeMs: map['whitePlayerTimeMs'],
  );

  OnlineMatch copyWith({
    PlayerInfo? redPlayer,
    PlayerInfo? whitePlayer,
    MatchStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? lastMoveAt,
    List<List<String?>>? board,
    PlayerColor? currentTurn,
    List<String>? moveHistory,
    String? winner,
    MatchEndReason? endReason,
    int? redPlayerTimeMs,
    int? whitePlayerTimeMs,
  }) => OnlineMatch(
    matchId: matchId,
    redPlayer: redPlayer ?? this.redPlayer,
    whitePlayer: whitePlayer ?? this.whitePlayer,
    status: status ?? this.status,
    variant: variant,
    createdAt: createdAt,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt ?? this.completedAt,
    lastMoveAt: lastMoveAt ?? this.lastMoveAt,
    board: board ?? this.board,
    currentTurn: currentTurn ?? this.currentTurn,
    moveHistory: moveHistory ?? this.moveHistory,
    winner: winner ?? this.winner,
    endReason: endReason ?? this.endReason,
    redPlayerTimeMs: redPlayerTimeMs ?? this.redPlayerTimeMs,
    whitePlayerTimeMs: whitePlayerTimeMs ?? this.whitePlayerTimeMs,
  );
}
