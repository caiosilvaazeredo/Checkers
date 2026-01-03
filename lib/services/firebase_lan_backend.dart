import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'lan_backend.dart';
import '../models/lan_game_model.dart';
import '../models/game_model.dart';

/// Backend LAN usando Firebase Realtime Database para plataforma web
/// Simula funcionalidade LAN usando Firebase como intermediário
class FirebaseLanBackend implements LanBackend {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  final StreamController<List<LanGameAdvertisement>> _gamesController =
      StreamController<List<LanGameAdvertisement>>.broadcast();
  final StreamController<LanMessage> _messagesController =
      StreamController<LanMessage>.broadcast();
  final StreamController<String> _disconnectController =
      StreamController<String>.broadcast();

  StreamSubscription? _gamesSubscription;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _connectionSubscription;

  String? _currentGameId;
  String? _myPlayerId;
  bool _isHost = false;

  @override
  Stream<List<LanGameAdvertisement>> get gamesStream => _gamesController.stream;

  @override
  Stream<LanMessage> get messagesStream => _messagesController.stream;

  @override
  Stream<String> get disconnectStream => _disconnectController.stream;

  @override
  Future<bool> hostGame({
    required String gameId,
    required String hostName,
    required GameVariant variant,
  }) async {
    try {
      _currentGameId = gameId;
      _myPlayerId = 'host_$gameId';
      _isHost = true;

      // Cria o jogo no Firebase
      final gameRef = _db.ref('lan_games/$gameId');
      await gameRef.set({
        'gameId': gameId,
        'hostName': hostName,
        'variant': variant.name,
        'timestamp': ServerValue.timestamp,
        'status': 'waiting', // waiting, playing, finished
        'players': {
          _myPlayerId!: {
            'name': hostName,
            'color': PlayerColor.red.name,
            'connected': true,
          },
        },
      });

      // Mantém presença
      final presenceRef = gameRef.child('players/$_myPlayerId/connected');
      await presenceRef.set(true);
      await presenceRef.onDisconnect().set(false);

      // Escuta por jogador entrando
      _listenForMessages();
      _listenForConnection();

      debugPrint('🎮 Jogo Firebase criado: $gameId');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao hospedar jogo Firebase: $e');
      return false;
    }
  }

  @override
  Future<void> discoverGames() async {
    try {
      // Escuta jogos disponíveis
      final gamesRef = _db.ref('lan_games');
      _gamesSubscription = gamesRef.onValue.listen((event) {
        final games = <LanGameAdvertisement>[];

        if (event.snapshot.value != null) {
          final data = _convertToMap(event.snapshot.value as Map);

          for (final entry in data.entries) {
            try {
              final gameData = entry.value is Map
                  ? _convertToMap(entry.value as Map)
                  : entry.value as Map<String, dynamic>;

              // Ignora jogos já em andamento ou finalizados
              if (gameData['status'] != 'waiting') continue;

              // Ignora jogos muito antigos (mais de 5 minutos)
              final timestamp = gameData['timestamp'] as int?;
              if (timestamp != null) {
                final age = DateTime.now().millisecondsSinceEpoch - timestamp;
                if (age > 300000) continue; // 5 minutos
              }

              final game = LanGameAdvertisement(
                gameId: gameData['gameId'] as String,
                hostName: gameData['hostName'] as String,
                hostIp: 'firebase', // Não usado no Firebase
                port: 0, // Não usado no Firebase
                variant: GameVariant.values.firstWhere(
                  (v) => v.name == gameData['variant'],
                  orElse: () => GameVariant.american,
                ),
                timestamp: timestamp != null
                    ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                    : DateTime.now(),
              );

              games.add(game);
            } catch (e) {
              debugPrint('⚠️ Erro ao processar jogo: $e');
            }
          }
        }

        _gamesController.add(games);
      });

      debugPrint('🔍 Descobrindo jogos Firebase...');
    } catch (e) {
      debugPrint('❌ Erro ao descobrir jogos Firebase: $e');
    }
  }

  @override
  Future<bool> joinGame({
    required LanGameAdvertisement game,
    required String playerName,
  }) async {
    try {
      _currentGameId = game.gameId;
      _myPlayerId = 'guest_${DateTime.now().millisecondsSinceEpoch}';
      _isHost = false;

      final gameRef = _db.ref('lan_games/$_currentGameId');

      // Adiciona jogador ao jogo
      await gameRef.child('players/$_myPlayerId').set({
        'name': playerName,
        'color': PlayerColor.white.name,
        'connected': true,
      });

      // Atualiza status do jogo para "playing"
      await gameRef.child('status').set('playing');

      // Mantém presença
      final presenceRef = gameRef.child('players/$_myPlayerId/connected');
      await presenceRef.onDisconnect().set(false);

      // Escuta mensagens
      _listenForMessages();

      // Envia mensagem de entrada
      await sendMessage(LanMessage(
        type: LanMessageType.joinRequest,
        data: {'playerName': playerName},
      ));

      debugPrint('🔌 Conectado ao jogo Firebase: ${game.gameId}');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao entrar no jogo Firebase: $e');
      return false;
    }
  }

  void _listenForMessages() {
    if (_currentGameId == null) return;

    final messagesRef = _db.ref('lan_games/$_currentGameId/messages');
    _messagesSubscription = messagesRef.onChildAdded.listen((event) {
      try {
        final rawData = event.snapshot.value;
        if (rawData == null) return;

        // Converte recursivamente LinkedMap para Map<String, dynamic>
        final data = _convertToMap(rawData as Map);

        // Ignora mensagens próprias
        if (data['senderId'] == _myPlayerId) return;

        final message = LanMessage.fromJson(data);
        _messagesController.add(message);
      } catch (e) {
        debugPrint('⚠️ Erro ao processar mensagem: $e');
      }
    });
  }

  /// Converte recursivamente LinkedMap para Map<String, dynamic>
  Map<String, dynamic> _convertToMap(Map map) {
    final result = <String, dynamic>{};
    map.forEach((key, value) {
      if (value is Map) {
        result[key.toString()] = _convertToMap(value);
      } else if (value is List) {
        result[key.toString()] = value.map((e) => e is Map ? _convertToMap(e) : e).toList();
      } else {
        result[key.toString()] = value;
      }
    });
    return result;
  }

  void _listenForConnection() {
    if (_currentGameId == null || !_isHost) return;

    final playersRef = _db.ref('lan_games/$_currentGameId/players');
    _connectionSubscription = playersRef.onChildAdded.listen((event) {
      try {
        final playerId = event.snapshot.key;
        if (playerId == _myPlayerId) return; // Ignora a si mesmo

        debugPrint('👤 Jogador conectado: $playerId');

        // Envia confirmação de entrada
        sendMessage(LanMessage(
          type: LanMessageType.joinAccepted,
          data: {'color': PlayerColor.white.name},
        ));
      } catch (e) {
        debugPrint('⚠️ Erro ao processar conexão: $e');
      }
    });

    // Escuta desconexões
    playersRef.onChildChanged.listen((event) {
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        if (data['connected'] == false) {
          debugPrint('🔌 Jogador desconectou');
          _disconnectController.add('disconnect');
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao processar desconexão: $e');
      }
    });
  }

  @override
  Future<void> sendMessage(LanMessage message) async {
    if (_currentGameId == null || _myPlayerId == null) return;

    try {
      final messagesRef = _db.ref('lan_games/$_currentGameId/messages');
      final messageData = message.toJson();
      messageData['senderId'] = _myPlayerId;
      messageData['timestamp'] = ServerValue.timestamp;

      await messagesRef.push().set(messageData);
    } catch (e) {
      debugPrint('❌ Erro ao enviar mensagem Firebase: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    await _gamesSubscription?.cancel();
    _gamesSubscription = null;
  }

  @override
  Future<void> cleanup() async {
    if (_currentGameId != null && _isHost) {
      // Remove o jogo do Firebase
      try {
        await _db.ref('lan_games/$_currentGameId').remove();
      } catch (e) {
        debugPrint('⚠️ Erro ao limpar jogo: $e');
      }
    } else if (_currentGameId != null && _myPlayerId != null) {
      // Marca jogador como desconectado
      try {
        await _db.ref('lan_games/$_currentGameId/players/$_myPlayerId/connected').set(false);
      } catch (e) {
        debugPrint('⚠️ Erro ao marcar desconexão: $e');
      }
    }

    await stopDiscovery();
    await _messagesSubscription?.cancel();
    await _connectionSubscription?.cancel();

    _messagesSubscription = null;
    _connectionSubscription = null;
    _currentGameId = null;
    _myPlayerId = null;
    _isHost = false;
  }

  @override
  void dispose() {
    cleanup();
    _gamesController.close();
    _messagesController.close();
    _disconnectController.close();
  }
}
