import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/match_history_model.dart';
import '../models/online_match_model.dart';
import '../models/game_model.dart';
import 'achievement_service.dart';

class MatchHistoryService extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final AchievementService _achievementService;

  MatchHistoryService(this._achievementService);

  List<MatchHistory> _userHistory = [];
  bool _isLoading = false;
  String? _error;

  List<MatchHistory> get userHistory => _userHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Salvar partida online no histórico
  Future<void> saveOnlineMatch(OnlineMatch match, Duration duration) async {
    try {
      if (!match.isCompleted) return;

      final player1Captures = _countCaptures(match.board, 'white');
      final player2Captures = _countCaptures(match.board, 'red');

      final history = MatchHistory(
        matchId: match.matchId,
        mode: GameMode.online,
        variant: match.variant,
        playedAt: match.completedAt ?? DateTime.now(),
        duration: duration,
        player1Id: match.redPlayer!.uid,
        player1Name: match.redPlayer!.username,
        player1Rating: match.redPlayer!.rating,
        player2Id: match.whitePlayer?.uid,
        player2Name: match.whitePlayer?.username,
        player2Rating: match.whitePlayer?.rating,
        winnerId: match.winner,
        winnerName: _getWinnerName(match),
        loserId: _getLoserId(match),
        loserName: _getLoserName(match),
        endReason: match.endReason?.toString().split('.').last ?? 'unknown',
        totalMoves: match.moveHistory.length,
        moveHistory: match.moveHistory,
        player1Captures: player1Captures,
        player2Captures: player2Captures,
      );

      // Salvar no histórico de ambos os jogadores
      await _db.ref('match_history/${match.redPlayer!.uid}/${match.matchId}')
          .set(history.toMap());

      if (match.whitePlayer != null) {
        await _db.ref('match_history/${match.whitePlayer!.uid}/${match.matchId}')
            .set(history.toMap());
      }

      // Salvar no histórico global
      await _db.ref('global_match_history/${match.matchId}')
          .set(history.toMap());

      // Disparar verificação de conquistas para ambos os jogadores
      if (match.redPlayer != null) {
        await _checkAchievementsForPlayer(
          userId: match.redPlayer!.uid,
          won: match.winner == match.redPlayer!.uid,
          duration: duration,
          history: history,
        );
      }

      if (match.whitePlayer != null) {
        await _checkAchievementsForPlayer(
          userId: match.whitePlayer!.uid,
          won: match.winner == match.whitePlayer!.uid,
          duration: duration,
          history: history,
        );
      }

    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Salvar partida local (AI ou PvP)
  Future<void> saveLocalMatch({
    required String userId,
    required String username,
    required GameMode mode,
    required GameVariant variant,
    required DateTime startTime,
    required List<String> moveHistory,
    required PlayerColor? winner,
    int? userRating,
  }) async {
    try {
      final matchId = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final duration = DateTime.now().difference(startTime);

      final captures = _countCapturesFromMoves(moveHistory);

      final history = MatchHistory(
        matchId: matchId,
        mode: mode,
        variant: variant,
        playedAt: DateTime.now(),
        duration: duration,
        player1Id: userId,
        player1Name: username,
        player1Rating: userRating,
        player2Name: mode == GameMode.ai ? 'Gemini AI' : 'Oponente Local',
        winnerId: winner == PlayerColor.red ? userId : 'opponent',
        winnerName: winner == PlayerColor.red ? username : (mode == GameMode.ai ? 'Gemini AI' : 'Oponente'),
        loserId: winner == PlayerColor.red ? 'opponent' : userId,
        loserName: winner == PlayerColor.red ? (mode == GameMode.ai ? 'Gemini AI' : 'Oponente') : username,
        endReason: 'checkmate',
        totalMoves: moveHistory.length,
        moveHistory: moveHistory,
        player1Captures: captures,
        player2Captures: 0, // Simplificado para partidas locais
      );

      await _db.ref('match_history/$userId/$matchId').set(history.toMap());

      // Disparar verificação de conquistas
      await _checkAchievementsForPlayer(
        userId: userId,
        won: winner == PlayerColor.red,
        duration: duration,
        history: history,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Carregar histórico do usuário
  Future<void> loadUserHistory(String userId, {int limit = 50}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _db
          .ref('match_history/$userId')
          .orderByChild('playedAt')
          .limitToLast(limit)
          .get();

      if (snapshot.exists) {
        final historyMap = Map<String, dynamic>.from(snapshot.value as Map);
        _userHistory = historyMap.values
            .map((data) => MatchHistory.fromMap(Map<String, dynamic>.from(data)))
            .toList();

        // Ordenar por data decrescente
        _userHistory.sort((a, b) => b.playedAt.compareTo(a.playedAt));
      } else {
        _userHistory = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filtrar histórico
  List<MatchHistory> filterHistory({
    GameMode? mode,
    GameVariant? variant,
    bool? wonOnly,
  }) {
    var filtered = _userHistory;

    if (mode != null) {
      filtered = filtered.where((h) => h.mode == mode).toList();
    }

    if (variant != null) {
      filtered = filtered.where((h) => h.variant == variant).toList();
    }

    return filtered;
  }

  // Estatísticas
  Map<String, dynamic> getUserStats(String userId) {
    final totalGames = _userHistory.length;
    final wins = _userHistory.where((h) => h.isWinner(userId)).length;
    final losses = _userHistory.where((h) => !h.isWinner(userId) && !h.isDraw).length;
    final draws = _userHistory.where((h) => h.isDraw).length;
    final winRate = totalGames > 0 ? (wins / totalGames * 100) : 0;

    final totalMoves = _userHistory.fold<int>(0, (sum, h) => sum + h.totalMoves);
    final avgMovesPerGame = totalGames > 0 ? (totalMoves / totalGames) : 0;

    return {
      'totalGames': totalGames,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winRate': winRate,
      'avgMovesPerGame': avgMovesPerGame,
    };
  }

  String _getWinnerName(OnlineMatch match) {
    if (match.winner == null) return 'Empate';
    if (match.winner == match.redPlayer?.uid) return match.redPlayer!.username;
    if (match.winner == match.whitePlayer?.uid) return match.whitePlayer!.username;
    return 'Unknown';
  }

  String? _getLoserId(OnlineMatch match) {
    if (match.winner == null) return null;
    if (match.winner == match.redPlayer?.uid) return match.whitePlayer?.uid;
    return match.redPlayer?.uid;
  }

  String? _getLoserName(OnlineMatch match) {
    if (match.winner == null) return null;
    if (match.winner == match.redPlayer?.uid) return match.whitePlayer?.username;
    return match.redPlayer?.username;
  }

  int _countCaptures(List<List<String?>> board, String colorToCount) {
    // Contar peças capturadas (12 iniciais - peças restantes)
    int piecesRemaining = 0;
    for (final row in board) {
      for (final cell in row) {
        if (cell != null && cell.startsWith(colorToCount)) {
          piecesRemaining++;
        }
      }
    }
    return 12 - piecesRemaining;
  }

  int _countCapturesFromMoves(List<String> moves) {
    // Simplificado: contar movimentos que parecem capturas (contém 'x')
    return moves.where((m) => m.contains('x')).length;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Verificar conquistas para um jogador após partida
  Future<void> _checkAchievementsForPlayer({
    required String userId,
    required bool won,
    required Duration duration,
    required MatchHistory history,
  }) async {
    try {
      // Obter estatísticas atualizadas do jogador
      await loadUserHistory(userId);
      final stats = getUserStats(userId);
      final gamesPlayed = stats['totalGames'] as int;

      // Calcular sequência de vitórias
      int consecutiveWins = 0;
      for (final match in _userHistory.reversed) {
        if (match.isWinner(userId)) {
          consecutiveWins++;
        } else {
          break;
        }
      }

      // Contar peças perdidas
      final piecesLost = history.player1Id == userId
          ? history.player1Captures
          : history.player2Captures ?? 0;

      // Disparar verificação de conquistas
      await _achievementService.checkMatchAchievements(
        userId: userId,
        won: won,
        gamesPlayed: gamesPlayed,
        consecutiveWins: consecutiveWins,
        matchDuration: duration,
        piecesLost: piecesLost,
      );
    } catch (e) {
      debugPrint('Erro ao verificar conquistas: $e');
    }
  }
}
