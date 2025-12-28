import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/achievement_model.dart';
import 'notification_service.dart';

class AchievementService extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final NotificationService _notificationService;

  List<UserAchievement> _userAchievements = [];
  bool _isLoading = false;

  AchievementService(this._notificationService);

  List<UserAchievement> get userAchievements => _userAchievements;
  bool get isLoading => _isLoading;
  int get totalPoints => _userAchievements
      .where((ua) => ua.isUnlocked)
      .fold(0, (sum, ua) {
        final achievement = Achievement.getAchievement(ua.type);
        return sum + (achievement?.points ?? 0);
      });

  // Carregar conquistas do usuário
  Future<void> loadUserAchievements(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final snapshot = await _db.ref('user_achievements/$userId').get();
      if (snapshot.exists) {
        final achievementsMap = Map<String, dynamic>.from(snapshot.value as Map);
        _userAchievements = achievementsMap.values
            .map((data) => UserAchievement.fromMap(Map<String, dynamic>.from(data)))
            .toList();
      } else {
        _userAchievements = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Erro ao carregar conquistas: $e');
      notifyListeners();
    }
  }

  // Verificar e desbloquear conquista
  Future<void> checkAndUnlockAchievement({
    required String userId,
    required AchievementType type,
    int progress = 1,
  }) async {
    try {
      // Verificar se já foi desbloqueada
      final existing = _userAchievements
          .where((ua) => ua.type == type && ua.isUnlocked)
          .firstOrNull;

      if (existing != null) return;

      final achievement = Achievement.getAchievement(type);
      if (achievement == null) return;

      final userAchievement = UserAchievement(
        type: type,
        unlockedAt: DateTime.now(),
        progress: progress,
        target: 1,
      );

      await _db.ref('user_achievements/$userId/${type.toString().split('.').last}')
          .set(userAchievement.toMap());

      // Enviar notificação
      await _notificationService.sendNotification(
        userId: userId,
        type: NotificationType.achievement,
        title: '🏆 Conquista Desbloqueada!',
        message: '${achievement.title} - ${achievement.points} pontos',
        data: {'achievementType': type.toString().split('.').last},
      );

      await loadUserAchievements(userId);
    } catch (e) {
      debugPrint('Erro ao desbloquear conquista: $e');
    }
  }

  // Verificar conquistas após partida
  Future<void> checkMatchAchievements({
    required String userId,
    required bool won,
    required int gamesPlayed,
    required int consecutiveWins,
    required Duration matchDuration,
    required int piecesLost,
  }) async {
    // Primeira vitória
    if (won && gamesPlayed == 1) {
      await checkAndUnlockAchievement(
        userId: userId,
        type: AchievementType.firstWin,
      );
    }

    // Sequência de vitórias
    if (consecutiveWins == 5) {
      await checkAndUnlockAchievement(
        userId: userId,
        type: AchievementType.winStreak5,
      );
    }

    if (consecutiveWins == 10) {
      await checkAndUnlockAchievement(
        userId: userId,
        type: AchievementType.winStreak10,
      );
    }

    // Mestre das Damas
    if (gamesPlayed == 100) {
      await checkAndUnlockAchievement(
        userId: userId,
        type: AchievementType.master100Games,
      );
    }

    // Jogo perfeito
    if (won && piecesLost == 0) {
      await checkAndUnlockAchievement(
        userId: userId,
        type: AchievementType.perfectGame,
      );
    }

    // Relâmpago
    if (won && matchDuration.inMinutes < 5) {
      await checkAndUnlockAchievement(
        userId: userId,
        type: AchievementType.speedDemon,
      );
    }
  }
}
