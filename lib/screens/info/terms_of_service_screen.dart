import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
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
            title: '1. Acceptance of Terms',
            content: '''By accessing and using Master Checkers AI ("the App"), you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.

These terms constitute a legally binding agreement between you and the App developers.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '2. User Accounts',
            content: '''Account Creation:
• You must provide accurate and complete information
• You are responsible for maintaining account security
• You must be at least 13 years old to create an account
• One person may not maintain multiple accounts
• Accounts are personal and non-transferable

Account Security:
• Keep your password confidential
• Notify us immediately of any unauthorized access
• You are responsible for all activities under your account

We reserve the right to suspend or terminate accounts that violate these terms.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '3. User Conduct',
            content: '''You agree NOT to:

• Cheat, hack, or use unauthorized tools
• Harass, abuse, or harm other players
• Create offensive or inappropriate usernames
• Intentionally disconnect or abandon games
• Share accounts or engage in account selling
• Attempt to exploit bugs or vulnerabilities
• Use automated bots or scripts
• Impersonate other users or staff
• Spam or send unsolicited messages
• Upload malicious content or viruses

Violations may result in:
• Warning or temporary suspension
• Permanent account ban
• Rating penalties
• Legal action (in severe cases)''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '4. Game Rules and Fair Play',
            content: '''Players must:
• Play fairly and follow game rules
• Complete games in good faith
• Respect opponents and maintain sportsmanship
• Accept mandatory captures as per game rules
• Not intentionally stall or delay games

Cheating includes:
• Using external analysis tools during games
• Receiving outside assistance during matches
• Exploiting software bugs for advantage
• Coordinating with opponents to manipulate ratings

We employ detection systems and review suspicious activity.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '5. Intellectual Property',
            content: '''All content in the App, including:
• Game design and mechanics
• Graphics, icons, and visual elements
• Code and software
• Text and documentation
• Trademarks and branding

...are owned by the App developers or licensors and protected by copyright laws.

You may NOT:
• Copy, modify, or distribute the App
• Reverse engineer or decompile the software
• Use our trademarks without permission
• Create derivative works

You retain ownership of any content you create (usernames, profiles), but grant us license to use it within the App.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '6. Online Multiplayer',
            content: '''Online features are provided "as is" and may:
• Experience downtime or maintenance
• Have latency or connection issues
• Be modified or discontinued

We are NOT responsible for:
• Lost games due to connection problems
• Rating changes from disconnections
• Opponent behavior or conduct
• Technical issues beyond our control

Players experiencing persistent connection issues should:
• Check their internet connection
• Contact support if problems continue
• Avoid ranked play during network instability''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '7. Ratings and Rankings',
            content: '''The rating system:
• Uses standard ELO-based calculations
• Updates after completed games
• May be adjusted for game abandonment
• Can be reset in case of cheating

We reserve the right to:
• Adjust ratings for fairness
• Reset ratings if necessary
• Remove invalid or fraudulent games
• Modify the rating algorithm

Rankings are for entertainment and competitive purposes only and carry no real-world value.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '8. Content and Communication',
            content: '''You are responsible for all communications and content you create, including:
• Usernames and profile information
• Messages to other players
• Game challenges and invitations

We reserve the right to:
• Monitor communications for violations
• Remove inappropriate content
• Ban users for offensive behavior
• Report illegal activity to authorities

Do not share personal information with other users.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '9. Service Availability',
            content: '''We strive to provide reliable service but:

• Do not guarantee 100% uptime
• May perform maintenance without notice
• May modify or discontinue features
• May shut down services with reasonable notice

We are NOT liable for:
• Service interruptions
• Data loss during outages
• Inconvenience from downtime
• Changes to features or functionality''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '10. Disclaimer of Warranties',
            content: '''THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING:

• Merchantability
• Fitness for a particular purpose
• Non-infringement
• Accuracy or reliability
• Uninterrupted or error-free operation

We do not guarantee:
• Bug-free software
• Compatibility with all devices
• Specific results or outcomes
• Permanent availability of features''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '11. Limitation of Liability',
            content: '''To the maximum extent permitted by law, we are NOT liable for:

• Indirect, incidental, or consequential damages
• Loss of data, profits, or opportunities
• Damages from unauthorized access
• Third-party conduct or content
• Any damages exceeding \$10 USD

This applies even if we were advised of potential damages.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '12. Privacy',
            content: '''Your use of the App is also governed by our Privacy Policy. By using the App, you consent to our data practices as described in the Privacy Policy.

Key privacy points:
• We collect minimal necessary data
• We do not sell your information
• We use industry-standard security
• You can delete your account anytime

Please review the full Privacy Policy for details.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '13. Modifications to Terms',
            content: '''We may modify these Terms at any time by:

• Posting updated Terms in the App
• Updating the "Last updated" date
• Notifying users of material changes

Continued use after changes constitutes acceptance. If you disagree with changes, stop using the App and delete your account.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '14. Termination',
            content: '''We may terminate or suspend your access:

• For violations of these Terms
• For fraudulent or abusive behavior
• For extended inactivity
• At our discretion for any reason

Upon termination:
• Your account access will be revoked
• Game data may be deleted
• You must cease using the App
• These Terms survive termination where applicable''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '15. Governing Law',
            content: '''These Terms are governed by and construed in accordance with applicable local laws, without regard to conflict of law provisions.

Disputes will be resolved through:
• Good faith negotiation
• Mediation (if applicable)
• Binding arbitration (where permitted)
• Local courts as a last resort

You waive the right to class-action lawsuits.''',
          ),
          const SizedBox(height: 20),

          _buildSection(
            title: '16. Contact and Support',
            content: '''For questions about these Terms:

• Use the in-app support feature
• Visit our GitHub repository
• Contact us via provided email

We aim to respond within 5-7 business days.''',
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
              'By using Master Checkers AI, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
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
