import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_model.dart';

class NotificationService extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final Uuid _uuid = const Uuid();

  List<AppNotification> _notifications = [];
  StreamSubscription? _notificationSubscription;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Escutar notificações do usuário
  void listenToNotifications(String userId) {
    _notificationSubscription?.cancel();
    _notificationSubscription = _db
        .ref('notifications/$userId')
        .orderByChild('timestamp')
        .limitToLast(50)
        .onValue
        .listen((event) {
      if (event.snapshot.exists) {
        final notifMap = Map<String, dynamic>.from(event.snapshot.value as Map);
        _notifications = notifMap.values
            .map((data) => AppNotification.fromMap(Map<String, dynamic>.from(data)))
            .toList();

        // Ordenar por data decrescente
        _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        _notifications = [];
      }
      notifyListeners();
    });
  }

  // Enviar notificação
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = AppNotification(
        id: notificationId,
        userId: userId,
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.now(),
        data: data,
      );

      await _db.ref('notifications/$userId/$notificationId')
          .set(notification.toMap());
    } catch (e) {
      debugPrint('Erro ao enviar notificação: $e');
    }
  }

  // Marcar notificação como lida
  Future<void> markAsRead(String userId, String notificationId) async {
    try {
      await _db.ref('notifications/$userId/$notificationId')
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Erro ao marcar notificação como lida: $e');
    }
  }

  // Marcar todas como lidas
  Future<void> markAllAsRead(String userId) async {
    try {
      for (final notification in _notifications.where((n) => !n.isRead)) {
        await markAsRead(userId, notification.id);
      }
    } catch (e) {
      debugPrint('Erro ao marcar todas como lidas: $e');
    }
  }

  // Deletar notificação
  Future<void> deleteNotification(String userId, String notificationId) async {
    try {
      await _db.ref('notifications/$userId/$notificationId').remove();
    } catch (e) {
      debugPrint('Erro ao deletar notificação: $e');
    }
  }

  // Limpar todas as notificações
  Future<void> clearAll(String userId) async {
    try {
      await _db.ref('notifications/$userId').remove();
    } catch (e) {
      debugPrint('Erro ao limpar notificações: $e');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }
}
