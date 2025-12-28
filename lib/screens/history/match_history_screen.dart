import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/match_history_service.dart';
import '../../services/auth_service.dart';
import '../../models/match_history_model.dart';
import '../../models/game_model.dart';
import '../../theme/app_theme.dart';
import '../replay/replay_screen.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  GameMode? _filterMode;
  GameVariant? _filterVariant;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthService>();
    final history = context.read<MatchHistoryService>();

    if (auth.currentUser != null) {
      await history.loadUserHistory(auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Partidas'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'ai') _filterMode = GameMode.ai;
                else if (value == 'pvp') _filterMode = GameMode.pvp;
                else if (value == 'online') _filterMode = GameMode.online;
                else if (value == 'american') _filterVariant = GameVariant.american;
                else if (value == 'brazilian') _filterVariant = GameVariant.brazilian;
                else if (value == 'clear') {
                  _filterMode = null;
                  _filterVariant = null;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'ai', child: Text('Apenas vs IA')),
              const PopupMenuItem(value: 'pvp', child: Text('Apenas PvP Local')),
              const PopupMenuItem(value: 'online', child: Text('Apenas Online')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'american', child: Text('Americana')),
              const PopupMenuItem(value: 'brazilian', child: Text('Brasileira')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear', child: Text('Limpar Filtros')),
            ],
          ),
        ],
      ),
      body: Consumer2<MatchHistoryService, AuthService>(
        builder: (context, history, auth, _) {
          if (history.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (auth.currentUser == null) {
            return const Center(child: Text('Faça login para ver seu histórico'));
          }

          var matches = history.userHistory;

          // Aplicar filtros
          if (_filterMode != null) {
            matches = matches.where((m) => m.mode == _filterMode).toList();
          }
          if (_filterVariant != null) {
            matches = matches.where((m) => m.variant == _filterVariant).toList();
          }

          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma partida encontrada',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // Estatísticas
          final stats = history.getUserStats(auth.currentUser!.uid);

          return Column(
            children: [
              // Estatísticas
              _StatsCard(stats: stats),

              // Lista de partidas
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return _MatchHistoryCard(
                      match: match,
                      userId: auth.currentUser!.uid,
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

class _StatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Text(
            'Estatísticas Gerais',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                label: 'Partidas',
                value: stats['totalGames'].toString(),
                icon: Icons.sports_esports,
                color: Colors.blue,
              ),
              _StatItem(
                label: 'Vitórias',
                value: stats['wins'].toString(),
                icon: Icons.emoji_events,
                color: Colors.green,
              ),
              _StatItem(
                label: 'Derrotas',
                value: stats['losses'].toString(),
                icon: Icons.close,
                color: Colors.red,
              ),
              _StatItem(
                label: 'Taxa de Vitória',
                value: '${stats['winRate'].toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: AppColors.accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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

class _MatchHistoryCard extends StatelessWidget {
  final MatchHistory match;
  final String userId;

  const _MatchHistoryCard({
    required this.match,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isWinner = match.isWinner(userId);
    final isDraw = match.isDraw;

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReplayScreen(match: match),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDraw
                        ? Colors.grey
                        : (isWinner ? Colors.green : Colors.red),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isDraw ? 'EMPATE' : (isWinner ? 'VITÓRIA' : 'DERROTA'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  match.variant == GameVariant.american ? 'Americana' : 'Brasileira',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(match.playedAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Jogadores
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.player1Name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (match.player1Rating != null)
                        Text(
                          'Rating: ${match.player1Rating}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const Text('vs', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        match.player2Name ?? 'Oponente',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      if (match.player2Rating != null)
                        Text(
                          'Rating: ${match.player2Rating}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MatchStat(
                  icon: Icons.timer,
                  label: _formatDuration(match.duration),
                ),
                _MatchStat(
                  icon: Icons.timeline,
                  label: '${match.totalMoves} movimentos',
                ),
                _MatchStat(
                  icon: Icons.sports_esports,
                  label: match.mode == GameMode.ai
                      ? 'vs IA'
                      : (match.mode == GameMode.online ? 'Online' : 'Local'),
                ),
                const Icon(
                  Icons.play_circle_outline,
                  color: AppColors.accent,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hoje';
    if (diff.inDays == 1) return 'Ontem';
    if (diff.inDays < 7) return '${diff.inDays} dias atrás';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }
    return '${duration.inSeconds}s';
  }
}

class _MatchStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MatchStat({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
