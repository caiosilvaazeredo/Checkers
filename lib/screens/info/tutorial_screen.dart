import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Play'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSection(
            context,
            icon: Icons.info_outline,
            title: 'Game Objective',
            content: 'Capture all of your opponent\'s pieces or block them so they cannot move. The player who achieves this wins the game!',
          ),
          const SizedBox(height: 20),

          _buildSection(
            context,
            icon: Icons.casino_outlined,
            title: 'Basic Rules',
            content: '''• Pieces move diagonally on dark squares only
• Regular pieces (men) can only move forward
• Captures are mandatory - you must capture if possible
• Multiple captures in a sequence are possible
• When a piece reaches the opposite end, it becomes a King''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            context,
            icon: Icons.workspace_premium,
            title: 'Kings',
            content: '''• Kings are more powerful than regular pieces
• Kings can move diagonally in all directions (forward and backward)
• Kings can capture in all diagonal directions
• Kings are marked with a crown/heart icon''',
          ),
          const SizedBox(height: 20),

          _buildVariantSection(
            context,
            title: 'American Checkers',
            icon: '🇺🇸',
            rules: [
              'Played on an 8x8 board',
              'Regular pieces move forward diagonally',
              'Captures are made by jumping over opponent pieces',
              'Kings move one square at a time',
              'Most popular variant in North America',
            ],
          ),
          const SizedBox(height: 20),

          _buildVariantSection(
            context,
            title: 'Brazilian Checkers',
            icon: '🇧🇷',
            rules: [
              'Also played on an 8x8 board',
              'Men can capture backwards (more flexible)',
              'Kings can "fly" - move multiple squares diagonally',
              'Kings can land anywhere after a jump',
              'More dynamic and complex gameplay',
            ],
          ),
          const SizedBox(height: 20),

          _buildSection(
            context,
            icon: Icons.tips_and_updates,
            title: 'Pro Tips',
            content: '''• Control the center of the board early
• Try to advance one side while defending the other
• Don't rush to king your pieces - timing matters
• Keep your back row protected when possible
• Trading pieces when ahead is often advantageous
• Kings are worth about 1.5x regular pieces''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            context,
            icon: Icons.psychology,
            title: 'Strategy Fundamentals',
            content: '''• Maintain piece mobility - don't block yourself
• Create piece chains for defensive strength
• Force your opponent into bad positions
• Calculate forced captures ahead of time
• In the endgame, activity is more important than material''',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSection(
    BuildContext context, {
    required String title,
    required String icon,
    required List<String> rules,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        rule,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
