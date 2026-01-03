import 'game_model.dart';

/// Representa um jogo LAN disponível na rede
class LanGameAdvertisement {
  final String gameId;
  final String hostName;
  final String hostIp;
  final int port;
  final GameVariant variant;
  final DateTime timestamp;

  LanGameAdvertisement({
    required this.gameId,
    required this.hostName,
    required this.hostIp,
    required this.port,
    required this.variant,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'gameId': gameId,
    'hostName': hostName,
    'hostIp': hostIp,
    'port': port,
    'variant': variant.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory LanGameAdvertisement.fromJson(Map<String, dynamic> json) {
    return LanGameAdvertisement(
      gameId: json['gameId'] as String,
      hostName: json['hostName'] as String,
      hostIp: json['hostIp'] as String,
      port: json['port'] as int,
      variant: GameVariant.values.firstWhere((v) => v.name == json['variant']),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  bool isExpired() {
    return DateTime.now().difference(timestamp).inSeconds > 30;
  }
}

/// Tipos de mensagens LAN
enum LanMessageType {
  gameAdvertisement,  // Anúncio de jogo disponível
  joinRequest,        // Solicitação para entrar no jogo
  joinAccepted,       // Entrada aceita
  joinRejected,       // Entrada rejeitada
  gameStart,          // Início do jogo
  move,               // Movimento de peça
  resign,             // Desistência
  disconnect,         // Desconexão
}

/// Mensagem LAN
class LanMessage {
  final LanMessageType type;
  final Map<String, dynamic> data;

  LanMessage({
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'data': data,
  };

  factory LanMessage.fromJson(Map<String, dynamic> json) {
    // Converte data para Map<String, dynamic> se for LinkedMap
    final rawData = json['data'];
    final data = rawData is Map<String, dynamic>
        ? rawData
        : Map<String, dynamic>.from(rawData as Map);

    return LanMessage(
      type: LanMessageType.values.firstWhere((t) => t.name == json['type']),
      data: data,
    );
  }

  String toJsonString() {
    final jsonMap = toJson();
    return '${_encodeJson(jsonMap)}\n';
  }

  static String _encodeJson(Map<String, dynamic> json) {
    final buffer = StringBuffer();
    buffer.write('{');

    final entries = json.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('"${entry.key}":');

      final value = entry.value;
      if (value is String) {
        buffer.write('"${value.replaceAll('"', '\\"')}"');
      } else if (value is Map) {
        buffer.write(_encodeJson(value as Map<String, dynamic>));
      } else {
        buffer.write(value.toString());
      }

      if (i < entries.length - 1) {
        buffer.write(',');
      }
    }

    buffer.write('}');
    return buffer.toString();
  }
}

/// Estado da conexão LAN
enum LanConnectionStatus {
  disconnected,
  hosting,
  discovering,
  connecting,
  waitingApproval,  // Host aguardando aprovação de jogador
  connected,
}

/// Informações do jogador LAN
class LanPlayer {
  final String name;
  final PlayerColor color;
  final bool isHost;

  LanPlayer({
    required this.name,
    required this.color,
    required this.isHost,
  });
}
