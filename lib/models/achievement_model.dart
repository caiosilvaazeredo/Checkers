import 'package:flutter/material.dart';

enum AchievementType {
  firstWin,
  winStreak5,
  winStreak10,
  master100Games,
  perfectGame,
  comebackKing,
  socialButterfly,
  chatMaster,
  speedDemon,
  tactician,
}

class Achievement {
  final AchievementType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int points;

  const Achievement({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.points,
  });

  static const List<Achievement> allAchievements = [
    Achievement(
      type: AchievementType.firstWin,
      title: 'Primeira Vitória',
      description: 'Vença sua primeira partida',
      icon: Icons.emoji_events,
      color: Colors.amber,
      points: 10,
    ),
    Achievement(
      type: AchievementType.winStreak5,
      title: 'Sequência de 5',
      description: 'Vença 5 partidas seguidas',
      icon: Icons.whatshot,
      color: Colors.orange,
      points: 50,
    ),
    Achievement(
      type: AchievementType.winStreak10,
      title: 'Imbatível',
      description: 'Vença 10 partidas seguidas',
      icon: Icons.local_fire_department,
      color: Colors.deepOrange,
      points: 100,
    ),
    Achievement(
      type: AchievementType.master100Games,
      title: 'Mestre das Damas',
      description: 'Jogue 100 partidas',
      icon: Icons.star,
      color: Colors.purple,
      points: 100,
    ),
    Achievement(
      type: AchievementType.perfectGame,
      title: 'Jogo Perfeito',
      description: 'Vença sem perder peças',
      icon: Icons.diamond,
      color: Colors.cyan,
      points: 75,
    ),
    Achievement(
      type: AchievementType.comebackKing,
      title: 'Rei da Virada',
      description: 'Vença estando em desvantagem',
      icon: Icons.trending_up,
      color: Colors.green,
      points: 50,
    ),
    Achievement(
      type: AchievementType.socialButterfly,
      title: 'Borboleta Social',
      description: 'Adicione 10 amigos',
      icon: Icons.people,
      color: Colors.pink,
      points: 30,
    ),
    Achievement(
      type: AchievementType.chatMaster,
      title: 'Conversador',
      description: 'Envie 100 mensagens no chat',
      icon: Icons.chat,
      color: Colors.blue,
      points: 25,
    ),
    Achievement(
      type: AchievementType.speedDemon,
      title: 'Relâmpago',
      description: 'Vença em menos de 5 minutos',
      icon: Icons.flash_on,
      color: Colors.yellow,
      points: 40,
    ),
    Achievement(
      type: AchievementType.tactician,
      title: 'Tático',
      description: 'Faça uma sequência de 5 capturas em um movimento',
      icon: Icons.psychology,
      color: Colors.indigo,
      points: 60,
    ),
  ];

  static Achievement? getAchievement(AchievementType type) {
    try {
      return allAchievements.firstWhere((a) => a.type == type);
    } catch (e) {
      return null;
    }
  }
}

class UserAchievement {
  final AchievementType type;
  final DateTime unlockedAt;
  final int progress;
  final int target;

  const UserAchievement({
    required this.type,
    required this.unlockedAt,
    this.progress = 0,
    this.target = 1,
  });

  bool get isUnlocked => progress >= target;

  Map<String, dynamic> toMap() => {
    'type': type.toString().split('.').last,
    'unlockedAt': unlockedAt.toIso8601String(),
    'progress': progress,
    'target': target,
  };

  factory UserAchievement.fromMap(Map<String, dynamic> map) => UserAchievement(
    type: AchievementType.values.firstWhere(
      (e) => e.toString().split('.').last == map['type'],
    ),
    unlockedAt: map['unlockedAt'] != null
        ? DateTime.parse(map['unlockedAt'])
        : DateTime.now(),
    progress: map['progress'] ?? 0,
    target: map['target'] ?? 1,
  );
}
