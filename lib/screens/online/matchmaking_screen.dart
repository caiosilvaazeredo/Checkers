import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../services/auth_service.dart';
import '../../services/online_game_service.dart';
import '../../theme/app_theme.dart';
import '../game/game_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  final GameVariant variant;

  const MatchmakingScreen({super.key, required this.variant});

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start matchmaking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startMatchmaking();
    });
  }

  void _startMatchmaking() async {
    final auth = context.read<AuthService>();
    final onlineGame = context.read<OnlineGameService>();

    if (auth.currentUser == null) return;

    setState(() => _isSearching = true);

    await onlineGame.startMatchmaking(auth.currentUser!, widget.variant);

    // Listen for game found
    onlineGame.addListener(_checkGameFound);
  }

  void _checkGameFound() {
    final onlineGame = context.read<OnlineGameService>();

    if (onlineGame.matchmakingStatus == MatchmakingStatus.found ||
        onlineGame.matchmakingStatus == MatchmakingStatus.inGame) {
      // Game found! Navigate to game screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const GameScreen()),
        );
      }
    }
  }

  void _cancelMatchmaking() async {
    final auth = context.read<AuthService>();
    final onlineGame = context.read<OnlineGameService>();

    if (auth.currentUser == null) return;

    await onlineGame.cancelMatchmaking(auth.currentUser!.uid);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    context.read<OnlineGameService>().removeListener(_checkGameFound);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onlineGame = context.watch<OnlineGameService>();
    final auth = context.watch<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finding Opponent'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancelMatchmaking,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated search indicator
              RotationTransition(
                turns: _animationController,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.search,
                    size: 60,
                    color: AppColors.accent,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Status text
              Text(
                _getStatusText(onlineGame.matchmakingStatus),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Info text
              Text(
                'Variant: ${widget.variant.name.toUpperCase()}\n'
                'Your rating: ${auth.currentUser?.rating ?? 1200}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Tips card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber.shade300,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Did you know?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getRandomTip(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelMatchmaking,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.accent),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(MatchmakingStatus status) {
    switch (status) {
      case MatchmakingStatus.searching:
        return 'Searching for opponent...';
      case MatchmakingStatus.found:
        return 'Opponent found!';
      case MatchmakingStatus.inGame:
        return 'Starting game...';
      default:
        return 'Preparing...';
    }
  }

  String _getRandomTip() {
    final tips = [
      'In American Checkers, regular pieces can only move forward, but kings can move in all diagonal directions.',
      'In Brazilian Checkers, men can capture backwards, and kings can fly across multiple squares.',
      'Always look for forced captures - you must take them if available!',
      'Getting a king is powerful - it can move in all diagonal directions.',
      'Control the center of the board to limit your opponent\'s options.',
      'Try to keep your back row protected to prevent your opponent from kinging pieces.',
      'Trading pieces when you\'re ahead is often a good strategy.',
      'Kings are worth about 1.5 times the value of a regular piece.',
    ];
    tips.shuffle();
    return tips.first;
  }
}
