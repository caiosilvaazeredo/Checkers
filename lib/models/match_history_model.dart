import 'game_model.dart';

class MatchHistory {
  final String matchId;
  final GameMode mode;
  final GameVariant variant;
  final DateTime playedAt;
  final Duration duration;

  // Jogadores
  final String player1Id;
  final String player1Name;
  final int? player1Rating;
  final String? player2Id;
  final String? player2Name;
  final int? player2Rating;

  // Resultado
  final String? winnerId;
  final String winnerName;
  final String? loserId;
  final String? loserName;
  final String endReason; // checkmate, resignation, timeout, draw

  // Estatísticas
  final int totalMoves;
  final List<String> moveHistory;
  final int player1Captures;
  final int player2Captures;

  const MatchHistory({
    required this.matchId,
    required this.mode,
    required this.variant,
    required this.playedAt,
    required this.duration,
    required this.player1Id,
    required this.player1Name,
    this.player1Rating,
    this.player2Id,
    this.player2Name,
    this.player2Rating,
    this.winnerId,
    required this.winnerName,
    this.loserId,
    this.loserName,
    required this.endReason,
    required this.totalMoves,
    required this.moveHistory,
    this.player1Captures = 0,
    this.player2Captures = 0,
  });

  bool isWinner(String userId) => winnerId == userId;
  bool isDraw => winnerId == null && endReason == 'draw';

  Map<String, dynamic> toMap() => {
    'matchId': matchId,
    'mode': mode.toString().split('.').last,
    'variant': variant.toString().split('.').last,
    'playedAt': playedAt.toIso8601String(),
    'duration': duration.inSeconds,
    'player1Id': player1Id,
    'player1Name': player1Name,
    'player1Rating': player1Rating,
    'player2Id': player2Id,
    'player2Name': player2Name,
    'player2Rating': player2Rating,
    'winnerId': winnerId,
    'winnerName': winnerName,
    'loserId': loserId,
    'loserName': loserName,
    'endReason': endReason,
    'totalMoves': totalMoves,
    'moveHistory': moveHistory,
    'player1Captures': player1Captures,
    'player2Captures': player2Captures,
  };

  factory MatchHistory.fromMap(Map<String, dynamic> map) => MatchHistory(
    matchId: map['matchId'] ?? '',
    mode: GameMode.values.firstWhere(
      (e) => e.toString().split('.').last == map['mode'],
      orElse: () => GameMode.ai,
    ),
    variant: GameVariant.values.firstWhere(
      (e) => e.toString().split('.').last == map['variant'],
      orElse: () => GameVariant.american,
    ),
    playedAt: map['playedAt'] != null
        ? DateTime.parse(map['playedAt'])
        : DateTime.now(),
    duration: Duration(seconds: map['duration'] ?? 0),
    player1Id: map['player1Id'] ?? '',
    player1Name: map['player1Name'] ?? 'Player 1',
    player1Rating: map['player1Rating'],
    player2Id: map['player2Id'],
    player2Name: map['player2Name'],
    player2Rating: map['player2Rating'],
    winnerId: map['winnerId'],
    winnerName: map['winnerName'] ?? 'Unknown',
    loserId: map['loserId'],
    loserName: map['loserName'],
    endReason: map['endReason'] ?? 'unknown',
    totalMoves: map['totalMoves'] ?? 0,
    moveHistory: List<String>.from(map['moveHistory'] ?? []),
    player1Captures: map['player1Captures'] ?? 0,
    player2Captures: map['player2Captures'] ?? 0,
  );
}
