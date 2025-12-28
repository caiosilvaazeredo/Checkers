class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderUsername;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderUsername,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
    'messageId': messageId,
    'senderId': senderId,
    'senderUsername': senderUsername,
    'message': message,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    messageId: map['messageId'] ?? '',
    senderId: map['senderId'] ?? '',
    senderUsername: map['senderUsername'] ?? 'Player',
    message: map['message'] ?? '',
    timestamp: map['timestamp'] != null
        ? DateTime.parse(map['timestamp'])
        : DateTime.now(),
    isRead: map['isRead'] ?? false,
  );

  ChatMessage copyWith({
    bool? isRead,
  }) => ChatMessage(
    messageId: messageId,
    senderId: senderId,
    senderUsername: senderUsername,
    message: message,
    timestamp: timestamp,
    isRead: isRead ?? this.isRead,
  );
}
