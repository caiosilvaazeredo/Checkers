import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../info/tutorial_screen.dart';
import '../info/about_screen.dart';
import '../info/privacy_policy_screen.dart';
import '../info/terms_of_service_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthService>().signOut();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.accent,
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.username,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Stats Grid
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
                          Expanded(child: _StatCard(title: 'Rating', value: '${user.rating}')),
                          const SizedBox(width: 16),
                          Expanded(child: _StatCard(title: 'Games', value: '${user.gamesPlayed}')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _StatCard(title: 'Wins', value: '${user.wins}', color: AppColors.accent)),
                          const SizedBox(width: 16),
                          Expanded(child: _StatCard(title: 'Losses', value: '${user.losses}', color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _StatCard(title: 'Draws', value: '${user.draws}', color: Colors.orange)),
                          const SizedBox(width: 16),
                          Expanded(child: _StatCard(title: 'Win Rate', value: '${user.winRate.toStringAsFixed(1)}%')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Member since
                Text(
                  'Member since ${_formatDate(user.createdAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Info & Help Section
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
                        'Information & Help',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MenuButton(
                        icon: Icons.school,
                        title: 'How to Play',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TutorialScreen()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MenuButton(
                        icon: Icons.info_outline,
                        title: 'About',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MenuButton(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy Policy',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _MenuButton(
                        icon: Icons.description_outlined,
                        title: 'Terms of Service',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _StatCard({required this.title, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
