import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App Logo/Icon
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.casino,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // App Name and Version
          const Text(
            'Master Checkers AI',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Description
          _buildSection(
            context,
            title: 'About the Game',
            content: 'Master Checkers AI is a modern take on the classic board game of Checkers (Draughts). '
                'Play against advanced AI, challenge friends online, or enjoy local multiplayer. '
                'Experience both American and Brazilian variants with beautiful graphics and smooth gameplay.',
          ),
          const SizedBox(height: 20),

          // Features
          _buildSection(
            context,
            title: 'Features',
            content: '''• Play vs AI with multiple difficulty levels
• Online multiplayer with matchmaking
• Challenge friends to online games
• Local Pass & Play mode
• American and Brazilian Checkers variants
• Global leaderboards and player rankings
• Friend system and social features
• Beautiful dark theme UI
• Move history tracking''',
          ),
          const SizedBox(height: 20),

          // Credits
          _buildSection(
            context,
            title: 'Credits',
            content: '''Developed with ❤️ using Flutter

Technologies:
• Flutter & Dart
• Firebase Authentication
• Firebase Realtime Database
• Google Sign-In
• Provider State Management

Special Thanks:
• The Flutter team
• Firebase team
• Open source community''',
          ),
          const SizedBox(height: 20),

          // Legal Links
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Legal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                  child: const Text('Privacy Policy'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TermsOfServiceScreen(),
                      ),
                    );
                  },
                  child: const Text('Terms of Service'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Contact/Support
          _buildSection(
            context,
            title: 'Support',
            content: 'For support, feedback, or bug reports, please contact us or visit our GitHub repository.\n\n'
                '© 2024 Master Checkers AI. All rights reserved.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
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
}
