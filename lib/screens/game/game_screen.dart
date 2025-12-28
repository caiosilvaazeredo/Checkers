import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../services/game_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/checkers_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Checkers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _showResignDialog(context),
          ),
        ],
      ),
      body: Consumer<GameService>(
        builder: (context, game, _) {
          final state = game.gameState;
          if (state == null) {
            return const Center(child: Text('No game in progress'));
          }

          return Column(
            children: [
              // Top player info
              _PlayerBar(
                name: state.mode == GameMode.ai ? 'Gemini AI' : 'White',
                isActive: state.turn == PlayerColor.white,
                color: PlayerColor.white,
              ),
              
              // Board
              Expanded(
                child: Center(
                  child: CheckersBoard(
                    gameState: state,
                    onSquareTap: game.selectSquare,
                    isThinking: game.isAiThinking,
                  ),
                ),
              ),
              
              // AI Explanation
              if (game.aiExplanation != null && state.mode == GameMode.ai)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          game.aiExplanation!,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Bottom player info
              _PlayerBar(
                name: 'You',
                isActive: state.turn == PlayerColor.red,
                color: PlayerColor.red,
              ),
              
              // Move history
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.history.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        '${(i ~/ 2) + 1}. ${state.history[i]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: AppColors.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Winner dialog
              if (state.winner != null)
                _buildWinnerOverlay(context, state.winner!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWinnerOverlay(BuildContext context, PlayerColor winner) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winner == PlayerColor.red ? AppColors.pieceRed : AppColors.accent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            winner == PlayerColor.red ? '🎉 You Win!' : 'AI Wins',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<GameService>().resetGame();
                  Navigator.pop(context);
                },
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GameService>().resign();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final String name;
  final bool isActive;
  final PlayerColor color;

  const _PlayerBar({
    required this.name,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color == PlayerColor.red
                  ? AppColors.pieceRed
                  : AppColors.pieceWhite,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
