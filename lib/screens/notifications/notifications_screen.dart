import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../models/notification_model.dart';
import '../../theme/app_theme.dart';
import '../matchmaking/matchmaking_screen.dart';
import '../friends/friends_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    final notificationService = context.read<NotificationService>();

    if (auth.currentUser != null) {
      notificationService.listenToNotifications(auth.currentUser!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        elevation: 0,
        actions: [
          Consumer2<NotificationService, AuthService>(
            builder: (context, notificationService, auth, _) {
              final hasUnread = notificationService.notifications
                  .any((n) => !n.isRead);

              if (!hasUnread) return const SizedBox();

              return TextButton.icon(
                onPressed: () async {
                  if (auth.currentUser != null) {
                    await notificationService.markAllAsRead(auth.currentUser!.uid);
                  }
                },
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Marcar todas lidas'),
              );
            },
          ),
        ],
      ),
      body: Consumer2<NotificationService, AuthService>(
        builder: (context, notificationService, auth, _) {
          if (auth.currentUser == null) {
            return const Center(
              child: Text('Faça login para ver suas notificações'),
            );
          }

          final notifications = notificationService.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma notificação',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(
                notification: notification,
                userId: auth.currentUser!.uid,
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final String userId;

  const _NotificationCard({
    required this.notification,
    required this.userId,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.matchInvite:
        return Icons.mail;
      case NotificationType.matchFound:
        return Icons.sports_esports;
      case NotificationType.gameEnded:
        return Icons.flag;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.tournamentStart:
        return Icons.military_tech;
    }
  }

  Color _getColor() {
    switch (notification.type) {
      case NotificationType.friendRequest:
        return Colors.blue;
      case NotificationType.matchInvite:
        return Colors.purple;
      case NotificationType.matchFound:
        return Colors.green;
      case NotificationType.gameEnded:
        return Colors.orange;
      case NotificationType.achievement:
        return Colors.amber;
      case NotificationType.tournamentStart:
        return Colors.red;
    }
  }

  void _handleTap(BuildContext context) {
    final notificationService = context.read<NotificationService>();

    // Marcar como lida
    if (!notification.isRead) {
      notificationService.markAsRead(userId, notification.id);
    }

    // Navegar baseado no tipo
    switch (notification.type) {
      case NotificationType.friendRequest:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FriendsScreen()),
        );
        break;
      case NotificationType.matchInvite:
      case NotificationType.matchFound:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MatchmakingScreen()),
        );
        break;
      case NotificationType.achievement:
        // Poderia navegar para tela de conquistas
        break;
      case NotificationType.gameEnded:
      case NotificationType.tournamentStart:
        // Ações futuras
        break;
    }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final diff = now.difference(notification.timestamp);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';

    return '${notification.timestamp.day}/${notification.timestamp.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? AppColors.surface
          : AppColors.surface.withOpacity(0.95),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIcon(), color: _getColor(), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Consumer<NotificationService>(
                builder: (context, service, _) => IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => service.deleteNotification(userId, notification.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
