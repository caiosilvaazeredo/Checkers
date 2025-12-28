import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/leaderboard_service.dart';
import '../../theme/app_theme.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LeaderboardService>().loadLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<LeaderboardService>().loadLeaderboard(),
          ),
        ],
      ),
      body: Consumer<LeaderboardService>(
        builder: (context, service, _) {
          if (service.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (service.leaderboard.isEmpty) {
            return const Center(
              child: Text('No players yet', style: TextStyle(color: AppColors.textSecondary)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: service.leaderboard.length,
            itemBuilder: (context, i) {
              final user = service.leaderboard[i];
              final rank = i + 1;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _buildRankBadge(rank),
                  title: Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${user.gamesPlayed} games · ${user.winRate.toStringAsFixed(1)}% win rate',
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user.rating}',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData? icon;
    
    switch (rank) {
      case 1:
        color = Colors.amber;
        icon = Icons.emoji_events;
        break;
      case 2:
        color = Colors.grey.shade400;
        icon = Icons.emoji_events;
        break;
      case 3:
        color = Colors.brown.shade400;
        icon = Icons.emoji_events;
        break;
      default:
        color = AppColors.textSecondary;
        icon = null;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: icon != null
            ? Icon(icon, color: color, size: 20)
            : Text(
                '$rank',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
