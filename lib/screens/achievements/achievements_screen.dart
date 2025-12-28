import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/achievement_service.dart';
import '../../services/auth_service.dart';
import '../../models/achievement_model.dart';
import '../../theme/app_theme.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final auth = context.read<AuthService>();
    final achievementService = context.read<AchievementService>();

    if (auth.currentUser != null) {
      await achievementService.loadUserAchievements(auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conquistas'),
        elevation: 0,
      ),
      body: Consumer2<AchievementService, AuthService>(
        builder: (context, achievementService, auth, _) {
          if (auth.currentUser == null) {
            return const Center(
              child: Text('Faça login para ver suas conquistas'),
            );
          }

          if (achievementService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final userAchievements = achievementService.userAchievements;
          final totalPoints = achievementService.totalPoints;
          final unlockedCount = userAchievements.where((a) => a.isUnlocked).length;

          return Column(
            children: [
              // Header com estatísticas
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(
                          icon: Icons.emoji_events,
                          value: '$unlockedCount/${Achievement.allAchievements.length}',
                          label: 'Desbloqueadas',
                          color: Colors.amber,
                        ),
                        _StatColumn(
                          icon: Icons.stars,
                          value: totalPoints.toString(),
                          label: 'Pontos Totais',
                          color: AppColors.accent,
                        ),
                        _StatColumn(
                          icon: Icons.trending_up,
                          value: '${((unlockedCount / Achievement.allAchievements.length) * 100).toStringAsFixed(0)}%',
                          label: 'Progresso',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de conquistas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: Achievement.allAchievements.length,
                  itemBuilder: (context, index) {
                    final achievement = Achievement.allAchievements[index];
                    final userAchievement = userAchievements.firstWhere(
                      (a) => a.type == achievement.type,
                      orElse: () => UserAchievement(
                        type: achievement.type,
                        unlockedAt: DateTime.now(),
                        progress: 0,
                        target: 1,
                      ),
                    );

                    return _AchievementCard(
                      achievement: achievement,
                      userAchievement: userAchievement,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final UserAchievement userAchievement;

  const _AchievementCard({
    required this.achievement,
    required this.userAchievement,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = userAchievement.isUnlocked;
    final progress = userAchievement.progress;
    final target = userAchievement.target;
    final progressPercent = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isUnlocked
                    ? achievement.color.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                color: isUnlocked ? achievement.color : Colors.grey,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: achievement.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${achievement.points} pts',
                          style: TextStyle(
                            color: achievement.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),

                  // Progresso ou data de desbloqueio
                  if (isUnlocked) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Desbloqueada em ${_formatDate(userAchievement.unlockedAt)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else if (target > 1) ...[
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progresso: $progress / $target',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${(progressPercent * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progressPercent,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(achievement.color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Icon(
                          Icons.lock,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Bloqueada',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
