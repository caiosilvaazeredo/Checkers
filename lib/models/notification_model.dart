enum NotificationType {
  friendRequest,
  matchInvite,
  matchFound,
  gameEnded,
  achievement,
  tournamentStart,
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'type': type.toString().split('.').last,
    'title': title,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
    id: map['id'] ?? '',
    userId: map['userId'] ?? '',
    type: NotificationType.values.firstWhere(
      (e) => e.toString().split('.').last == map['type'],
      orElse: () => NotificationType.gameEnded,
    ),
    title: map['title'] ?? '',
    message: map['message'] ?? '',
    timestamp: map['timestamp'] != null
        ? DateTime.parse(map['timestamp'])
        : DateTime.now(),
    isRead: map['isRead'] ?? false,
    data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
  );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    userId: userId,
    type: type,
    title: title,
    message: message,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
    data: data,
  );
}
