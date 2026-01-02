import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../services/auth_service.dart';
import '../../services/game_service.dart';
import '../../services/online_game_service.dart';
import '../../theme/app_theme.dart';
import '../game/game_screen.dart';
import '../friends/friends_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';
import '../online/matchmaking_screen.dart';
import '../lan/lan_lobby_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthService>();
      if (auth.currentUser != null) {
        context.read<OnlineGameService>().listenForInvites(auth.currentUser!.uid);
      }
    });
  }

  void _startGame(BuildContext context, GameMode mode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _GameSettingsSheet(mode: mode),
    );
  }

  void _showPendingInvites(BuildContext context) {
    final onlineGame = context.read<OnlineGameService>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Invites'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: onlineGame.pendingInvites.length,
            itemBuilder: (context, index) {
              final invite = onlineGame.pendingInvites[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Text(invite.fromUser.username[0].toUpperCase()),
                  ),
                  title: Text(invite.fromUser.username),
                  subtitle: Text(
                    '${invite.variant.name.toUpperCase()} Checkers\nRating: ${invite.fromUser.rating}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: AppColors.accent),
                        onPressed: () async {
                          await onlineGame.acceptInvite(invite);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GameScreen(),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await onlineGame.declineInvite(invite);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.username ?? "Player"}!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        'Rating: ${user?.rating ?? 1200}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.accent,
                      child: Text(
                        (user?.username ?? 'P')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Game invites indicator
              Consumer<OnlineGameService>(
                builder: (context, onlineGame, _) {
                  if (onlineGame.pendingInvites.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Material(
                      color: Colors.orange.shade900.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => _showPendingInvites(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.mail, color: Colors.orange),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${onlineGame.pendingInvites.length} pending game ${onlineGame.pendingInvites.length == 1 ? 'invite' : 'invites'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.orange),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Play Buttons
              Expanded(
                child: Column(
                  children: [
                    _MenuButton(
                      icon: Icons.smart_toy,
                      title: 'Play vs AI',
                      subtitle: 'Challenge Gemini AI',
                      color: AppColors.accent,
                      onTap: () => _startGame(context, GameMode.ai),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.people,
                      title: 'Pass & Play',
                      subtitle: 'Local multiplayer',
                      color: Colors.orange,
                      onTap: () => _startGame(context, GameMode.pvp),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.public,
                      title: 'Play Online',
                      subtitle: 'Find an opponent',
                      color: Colors.blue,
                      onTap: () => _startGame(context, GameMode.online),
                    ),
                    const SizedBox(height: 16),
                    _MenuButton(
                      icon: Icons.wifi,
                      title: 'Jogo Local (LAN)',
                      subtitle: 'Jogue na mesma rede - casual',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LanLobbyScreen()),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Secondary buttons
                    Row(
                      children: [
                        Expanded(
                          child: _SmallMenuButton(
                            icon: Icons.group,
                            title: 'Friends',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FriendsScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SmallMenuButton(
                            icon: Icons.leaderboard,
                            title: 'Leaderboard',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallMenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SmallMenuButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: AppColors.textSecondary),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameSettingsSheet extends StatefulWidget {
  final GameMode mode;
  const _GameSettingsSheet({required this.mode});

  @override
  State<_GameSettingsSheet> createState() => _GameSettingsSheetState();
}

class _GameSettingsSheetState extends State<_GameSettingsSheet> {
  GameVariant _variant = GameVariant.american;
  String _difficulty = 'hard';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Settings',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          
          const Text('Variant', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<GameVariant>(
            segments: const [
              ButtonSegment(value: GameVariant.american, label: Text('American')),
              ButtonSegment(value: GameVariant.brazilian, label: Text('Brazilian')),
            ],
            selected: {_variant},
            onSelectionChanged: (s) => setState(() => _variant = s.first),
          ),
          
          if (widget.mode == GameMode.ai) ...[
            const SizedBox(height: 16),
            const Text('Difficulty', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'easy', label: Text('Easy')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'hard', label: Text('Hard')),
              ],
              selected: {_difficulty},
              onSelectionChanged: (s) => setState(() => _difficulty = s.first),
            ),
          ],
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                if (widget.mode == GameMode.online) {
                  // Navigate to matchmaking screen for online games
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchmakingScreen(variant: _variant),
                    ),
                  );
                } else {
                  // Start local game (AI or PvP)
                  final game = context.read<GameService>();
                  game.setDifficulty(_difficulty);
                  game.startGame(_variant, widget.mode);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GameScreen()),
                  );
                }
              },
              child: const Text('Start Game'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
