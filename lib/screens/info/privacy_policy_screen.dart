import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Last updated: ${DateTime.now().year}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          _buildSection(
            title: '1. Information We Collect',
            content: '''We collect the following types of information:

• Account Information: Email address, username, and password (securely hashed)
• Profile Data: User rating, game statistics, win/loss records
• Game Data: Move history, game results, and gameplay preferences
• Social Features: Friends list and friend requests
• Authentication Data: OAuth tokens from Google Sign-In (if used)

We do NOT collect:
• Personal identifying information beyond what's necessary
• Payment information (the app is free)
• Device location data
• Browsing history or activity outside the app''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '2. How We Use Your Information',
            content: '''Your information is used to:

• Provide and maintain the game services
• Create and manage your player account
• Enable online multiplayer features
• Calculate and display rankings and statistics
• Connect you with friends and opponents
• Improve the game experience
• Authenticate your identity securely
• Send important service notifications

We do NOT:
• Sell your personal information to third parties
• Use your data for advertising purposes
• Share your information without your consent
• Track you across other apps or websites''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '3. Data Storage and Security',
            content: '''Your data is stored securely using Firebase services:

• Firebase Authentication: Industry-standard secure authentication
• Firebase Realtime Database: Encrypted data transmission
• Secure password hashing: Passwords are never stored in plain text
• Access Controls: Strict database security rules

While we implement robust security measures, no internet transmission is 100% secure. We cannot guarantee absolute security but take all reasonable precautions.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '4. Third-Party Services',
            content: '''We use the following third-party services:

• Firebase (Google): Authentication, database, and hosting
• Google Sign-In: Optional OAuth authentication

These services have their own privacy policies:
• Firebase Privacy: https://firebase.google.com/support/privacy
• Google Privacy: https://policies.google.com/privacy

We recommend reviewing these policies to understand how they handle your data.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '5. Data Sharing',
            content: '''We share minimal information with other players:

Visible to other players:
• Your username
• Your rating and game statistics
• Your online status (when playing)
• Game history (in ongoing/completed games)

NOT visible to other players:
• Your email address
• Your password
• Your device information
• Your IP address

We do not sell, trade, or rent your personal information to third parties.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '6. Your Rights',
            content: '''You have the right to:

• Access your personal data
• Correct inaccurate information
• Delete your account and associated data
• Export your game data
• Opt-out of optional features
• Withdraw consent at any time

To exercise these rights, please contact us through the app or our support channels.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '7. Children\'s Privacy',
            content: '''Our service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us immediately, and we will delete such information.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '8. Data Retention',
            content: '''We retain your data as long as your account is active or as needed to provide services. You may request account deletion at any time.

Upon account deletion:
• Personal information is permanently deleted within 30 days
• Game statistics may be retained anonymously for historical records
• Backup systems may retain data for up to 90 days''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '9. Changes to This Policy',
            content: '''We may update this Privacy Policy from time to time. We will notify users of any material changes by:

• Updating the "Last updated" date
• Showing an in-app notification
• Requiring re-acceptance of updated terms (for major changes)

Your continued use of the app after changes constitutes acceptance of the updated policy.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '10. Contact Us',
            content: '''If you have questions about this Privacy Policy or our data practices, please contact us:

• Through the app's support feature
• Via our GitHub repository
• By email (if provided in the app)

We will respond to privacy inquiries within 30 days.''',
          ),
          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Text(
              'By using Master Checkers AI, you acknowledge that you have read and understood this Privacy Policy.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Column(
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
    );
  }
}
