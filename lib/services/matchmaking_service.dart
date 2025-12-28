import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/online_match_model.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';

class MatchmakingService extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  OnlineMatch? _currentMatch;
  bool _isSearching = false;
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _matchSubscription;
  StreamSubscription? _queueSubscription;

  OnlineMatch? get currentMatch => _currentMatch;
  bool get isSearching => _isSearching;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Entrar na fila de matchmaking
  Future<void> joinMatchmakingQueue({
    required AppUser user,
    GameVariant variant = GameVariant.american,
  }) async {
    try {
      _isSearching = true;
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Primeiro, procurar por partidas disponíveis
      final availableMatch = await _findAvailableMatch(variant, user.rating);

      if (availableMatch != null) {
        // Encontrou uma partida, juntar-se a ela
        await _joinMatch(availableMatch, user);
      } else {
        // Não encontrou, criar nova partida e entrar na fila
        await _createAndWaitForMatch(user, variant);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isSearching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Procurar partida disponível na fila
  Future<OnlineMatch?> _findAvailableMatch(GameVariant variant, int userRating) async {
    try {
      final snapshot = await _db.ref('matches')
          .orderByChild('status')
          .equalTo(MatchStatus.waiting.toString().split('.').last)
          .get();

      if (!snapshot.exists) return null;

      final matches = <OnlineMatch>[];
      for (final child in snapshot.children) {
        final matchData = Map<String, dynamic>.from(child.value as Map);
        final match = OnlineMatch.fromMap(matchData);

        // Verificar se é a variante correta e se está esperando jogador
        if (match.variant == variant && match.needsSecondPlayer) {
          // Verificar diferença de rating (matchmaking justo)
          final opponentRating = match.redPlayer?.rating ?? match.whitePlayer?.rating ?? 1200;
          final ratingDiff = (userRating - opponentRating).abs();

          if (ratingDiff <= 300) { // Diferença máxima de 300 pontos
            matches.add(match);
          }
        }
      }

      // Retornar a partida mais antiga (FIFO)
      if (matches.isNotEmpty) {
        matches.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return matches.first;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // Criar nova partida e aguardar oponente
  Future<void> _createAndWaitForMatch(AppUser user, GameVariant variant) async {
    final matchId = _uuid.v4();
    final playerColor = PlayerColor.red; // Criador sempre começa como vermelho

    final playerInfo = PlayerInfo(
      uid: user.uid,
      username: user.username,
      rating: user.rating,
      color: playerColor,
    );

    final match = OnlineMatch(
      matchId: matchId,
      redPlayer: playerInfo,
      variant: variant,
      status: MatchStatus.waiting,
    );

    // Salvar partida no Firebase
    await _db.ref('matches/$matchId').set(match.toMap());

    // Adicionar referência para o usuário
    await _db.ref('user_matches/${user.uid}/$matchId').set({
      'matchId': matchId,
      'status': MatchStatus.waiting.toString().split('.').last,
      'lastUpdate': DateTime.now().toIso8601String(),
    });

    // Adicionar à fila de matchmaking
    await _db.ref('matchmaking_queue/${user.uid}').set({
      'uid': user.uid,
      'username': user.username,
      'rating': user.rating,
      'variant': variant.toString().split('.').last,
      'matchId': matchId,
      'timestamp': ServerValue.timestamp,
    });

    // Escutar mudanças na partida
    _listenToMatch(matchId);
  }

  // Juntar-se a uma partida existente
  Future<void> _joinMatch(OnlineMatch match, AppUser user) async {
    try {
      final playerColor = match.redPlayer == null ? PlayerColor.red : PlayerColor.white;

      final playerInfo = PlayerInfo(
        uid: user.uid,
        username: user.username,
        rating: user.rating,
        color: playerColor,
      );

      // Atualizar a partida com o segundo jogador
      final updates = <String, dynamic>{
        if (playerColor == PlayerColor.red) 'redPlayer': playerInfo.toMap(),
        if (playerColor == PlayerColor.white) 'whitePlayer': playerInfo.toMap(),
        'status': MatchStatus.active.toString().split('.').last,
        'startedAt': DateTime.now().toIso8601String(),
      };

      await _db.ref('matches/${match.matchId}').update(updates);

      // Adicionar referência para o usuário
      await _db.ref('user_matches/${user.uid}/${match.matchId}').set({
        'matchId': match.matchId,
        'status': MatchStatus.active.toString().split('.').last,
        'lastUpdate': DateTime.now().toIso8601String(),
      });

      // Remover o oponente da fila de matchmaking
      final opponentUid = match.redPlayer?.uid ?? match.whitePlayer?.uid;
      if (opponentUid != null) {
        await _db.ref('matchmaking_queue/$opponentUid').remove();
      }

      // Escutar mudanças na partida
      _listenToMatch(match.matchId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Escutar mudanças em uma partida
  void _listenToMatch(String matchId) {
    _matchSubscription?.cancel();
    _matchSubscription = _db.ref('matches/$matchId').onValue.listen((event) {
      if (event.snapshot.exists) {
        final matchData = Map<String, dynamic>.from(event.snapshot.value as Map);
        _currentMatch = OnlineMatch.fromMap(matchData);

        if (_currentMatch!.status == MatchStatus.active) {
          _isSearching = false;
        }

        notifyListeners();
      }
    });
  }

  // Sair da fila de matchmaking
  Future<void> leaveQueue(String userId) async {
    try {
      _isSearching = false;
      _matchSubscription?.cancel();

      // Remover da fila
      await _db.ref('matchmaking_queue/$userId').remove();

      // Se criou uma partida mas ninguém entrou, deletar
      if (_currentMatch != null && _currentMatch!.status == MatchStatus.waiting) {
        await _db.ref('matches/${_currentMatch!.matchId}').remove();
        await _db.ref('user_matches/$userId/${_currentMatch!.matchId}').remove();
      }

      _currentMatch = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fazer um movimento na partida
  Future<bool> makeMove({
    required String matchId,
    required Position from,
    required Position to,
    required bool isCapture,
    Position? capturedPos,
    required List<List<String?>> newBoard,
    required PlayerColor nextTurn,
    String? winner,
  }) async {
    try {
      final move = Move(
        from: from,
        to: to,
        isCapture: isCapture,
        capturedPos: capturedPos,
      );

      final moveNotation = move.toNotation();
      final currentHistory = _currentMatch?.moveHistory ?? [];
      final updatedHistory = [...currentHistory, moveNotation];

      final updates = <String, dynamic>{
        'board': newBoard,
        'currentTurn': nextTurn.toString().split('.').last,
        'moveHistory': updatedHistory,
        'lastMoveAt': DateTime.now().toIso8601String(),
      };

      if (winner != null) {
        updates['winner'] = winner;
        updates['status'] = MatchStatus.completed.toString().split('.').last;
        updates['endReason'] = MatchEndReason.checkmate.toString().split('.').last;
        updates['completedAt'] = DateTime.now().toIso8601String();
      }

      await _db.ref('matches/$matchId').update(updates);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Desistir da partida
  Future<void> resignMatch(String matchId, String userId) async {
    try {
      await _db.ref('matches/$matchId').update({
        'status': MatchStatus.completed.toString().split('.').last,
        'endReason': MatchEndReason.resignation.toString().split('.').last,
        'winner': _currentMatch!.redPlayer!.uid == userId
            ? _currentMatch!.whitePlayer!.uid
            : _currentMatch!.redPlayer!.uid,
        'completedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Enviar convite para amigo
  Future<bool> sendFriendInvite({
    required AppUser sender,
    required String friendUid,
    GameVariant variant = GameVariant.american,
  }) async {
    try {
      final matchId = _uuid.v4();
      final inviteId = _uuid.v4();

      final playerInfo = PlayerInfo(
        uid: sender.uid,
        username: sender.username,
        rating: sender.rating,
        color: PlayerColor.red,
      );

      // Criar partida privada
      final match = OnlineMatch(
        matchId: matchId,
        redPlayer: playerInfo,
        variant: variant,
        status: MatchStatus.waiting,
      );

      await _db.ref('matches/$matchId').set(match.toMap());

      // Adicionar referência para o criador
      await _db.ref('user_matches/${sender.uid}/$matchId').set({
        'matchId': matchId,
        'status': MatchStatus.waiting.toString().split('.').last,
        'lastUpdate': DateTime.now().toIso8601String(),
      });

      // Enviar convite
      await _db.ref('match_invites/$friendUid/$inviteId').set({
        'inviteId': inviteId,
        'senderId': sender.uid,
        'senderUsername': sender.username,
        'matchId': matchId,
        'variant': variant.toString().split('.').last,
        'timestamp': ServerValue.timestamp,
      });

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Aceitar convite de amigo
  Future<bool> acceptFriendInvite({
    required AppUser user,
    required String matchId,
    required String inviteId,
  }) async {
    try {
      // Buscar a partida
      final matchSnapshot = await _db.ref('matches/$matchId').get();
      if (!matchSnapshot.exists) return false;

      final matchData = Map<String, dynamic>.from(matchSnapshot.value as Map);
      final match = OnlineMatch.fromMap(matchData);

      // Juntar-se à partida
      await _joinMatch(match, user);

      // Remover convite
      await _db.ref('match_invites/${user.uid}/$inviteId').remove();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Recusar convite
  Future<void> declineInvite(String userId, String inviteId, String matchId) async {
    try {
      await _db.ref('match_invites/$userId/$inviteId').remove();
      // Opcionalmente, deletar a partida se ninguém entrou
      final matchSnapshot = await _db.ref('matches/$matchId').get();
      if (matchSnapshot.exists) {
        final matchData = Map<String, dynamic>.from(matchSnapshot.value as Map);
        final match = OnlineMatch.fromMap(matchData);
        if (match.status == MatchStatus.waiting) {
          await _db.ref('matches/$matchId').remove();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Buscar partidas ativas do usuário
  Future<List<OnlineMatch>> getUserActiveMatches(String userId) async {
    try {
      final userMatchesSnapshot = await _db.ref('user_matches/$userId').get();
      if (!userMatchesSnapshot.exists) return [];

      final matchIds = <String>[];
      for (final child in userMatchesSnapshot.children) {
        final matchData = Map<String, dynamic>.from(child.value as Map);
        if (matchData['status'] == MatchStatus.active.toString().split('.').last) {
          matchIds.add(matchData['matchId']);
        }
      }

      final matches = <OnlineMatch>[];
      for (final matchId in matchIds) {
        final matchSnapshot = await _db.ref('matches/$matchId').get();
        if (matchSnapshot.exists) {
          final matchData = Map<String, dynamic>.from(matchSnapshot.value as Map);
          matches.add(OnlineMatch.fromMap(matchData));
        }
      }

      return matches;
    } catch (e) {
      return [];
    }
  }

  // Carregar uma partida específica
  Future<void> loadMatch(String matchId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _db.ref('matches/$matchId').get();
      if (snapshot.exists) {
        final matchData = Map<String, dynamic>.from(snapshot.value as Map);
        _currentMatch = OnlineMatch.fromMap(matchData);
        _listenToMatch(matchId);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    _queueSubscription?.cancel();
    super.dispose();
  }
}
