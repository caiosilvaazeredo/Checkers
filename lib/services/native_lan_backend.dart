import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'lan_backend.dart';
import '../models/lan_game_model.dart';
import '../models/game_model.dart';

/// Backend LAN usando sockets nativos para plataformas mobile e desktop
class NativeLanBackend implements LanBackend {
  static const int discoveryPort = 45123;
  static const int gamePortStart = 45124;
  static const String multicastAddress = '224.0.0.251';

  final StreamController<List<LanGameAdvertisement>> _gamesController =
      StreamController<List<LanGameAdvertisement>>.broadcast();
  final StreamController<LanMessage> _messagesController =
      StreamController<LanMessage>.broadcast();
  final StreamController<String> _disconnectController =
      StreamController<String>.broadcast();

  String? _currentGameId;
  String? _hostIp;
  int? _gamePort;
  ServerSocket? _gameServer;
  Socket? _gameSocket;
  RawDatagramSocket? _discoverySocket;
  Timer? _advertisementTimer;
  Timer? _cleanupTimer;

  final List<LanGameAdvertisement> _availableGames = [];

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

      // Obtém IP local
      final networkInfo = NetworkInfo();
      final wifiIp = await networkInfo.getWifiIP();

      if (wifiIp == null) {
        throw Exception('Não foi possível obter o IP local. Verifique se está conectado ao Wi-Fi.');
      }

      _hostIp = wifiIp;

      // Inicia servidor de jogo
      _gamePort = gamePortStart;
      _gameServer = await ServerSocket.bind(InternetAddress.anyIPv4, _gamePort!);

      debugPrint('🎮 Servidor de jogo iniciado em $_hostIp:$_gamePort');

      // Aguarda conexão do oponente
      _gameServer!.listen((socket) async {
        debugPrint('👤 Oponente conectado: ${socket.remoteAddress.address}');
        _gameSocket = socket;
        _stopAdvertising();

        // Envia confirmação de entrada
        await sendMessage(LanMessage(
          type: LanMessageType.joinAccepted,
          data: {'color': PlayerColor.white.name},
        ));

        // Escuta mensagens do oponente
        _listenToSocket(socket);
      });

      // Inicia descoberta multicast
      await _startDiscovery();

      // Inicia timer para anunciar o jogo periodicamente
      _startAdvertising(hostName, variant);

      return true;
    } catch (e) {
      debugPrint('❌ Erro ao hospedar jogo nativo: $e');
      await cleanup();
      return false;
    }
  }

  @override
  Future<void> discoverGames() async {
    try {
      _availableGames.clear();
      _gamesController.add([]);

      await _startDiscovery();

      // Timer para limpar jogos expirados
      _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _availableGames.removeWhere((game) => game.isExpired());
        _gamesController.add(List.from(_availableGames));
      });
    } catch (e) {
      debugPrint('❌ Erro ao descobrir jogos nativos: $e');
    }
  }

  @override
  Future<bool> joinGame({
    required LanGameAdvertisement game,
    required String playerName,
  }) async {
    try {
      _currentGameId = game.gameId;

      // Conecta ao servidor do jogo
      _gameSocket = await Socket.connect(game.hostIp, game.port);
      debugPrint('🔌 Conectado ao jogo: ${game.hostName}');

      // Envia solicitação de entrada
      await sendMessage(LanMessage(
        type: LanMessageType.joinRequest,
        data: {'playerName': playerName},
      ));

      // Escuta mensagens do host
      _listenToSocket(_gameSocket!);

      // Fecha descoberta
      await stopDiscovery();

      return true;
    } catch (e) {
      debugPrint('❌ Erro ao entrar no jogo nativo: $e');
      await cleanup();
      return false;
    }
  }

  Future<void> _startDiscovery() async {
    _discoverySocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, discoveryPort);
    _discoverySocket!.broadcastEnabled = true;
    _discoverySocket!.multicastLoopback = false;

    // Join multicast group
    try {
      _discoverySocket!.joinMulticast(InternetAddress(multicastAddress));
    } catch (e) {
      debugPrint('⚠️ Aviso: Não foi possível entrar no grupo multicast: $e');
    }

    _discoverySocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _discoverySocket!.receive();
        if (datagram != null) {
          try {
            final message = utf8.decode(datagram.data);
            final json = jsonDecode(message) as Map<String, dynamic>;
            final lanMessage = LanMessage.fromJson(json);

            if (lanMessage.type == LanMessageType.gameAdvertisement) {
              final game = LanGameAdvertisement.fromJson(lanMessage.data);

              // Ignora nosso próprio anúncio
              if (game.gameId == _currentGameId) return;

              // Atualiza ou adiciona jogo
              final index = _availableGames.indexWhere((g) => g.gameId == game.gameId);
              if (index >= 0) {
                _availableGames[index] = game;
              } else {
                _availableGames.add(game);
              }
              _gamesController.add(List.from(_availableGames));
            }
          } catch (e) {
            debugPrint('⚠️ Erro ao processar pacote de descoberta: $e');
          }
        }
      }
    });
  }

  void _startAdvertising(String hostName, GameVariant variant) {
    _advertisementTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _advertiseGame(hostName, variant);
    });
  }

  void _advertiseGame(String hostName, GameVariant variant) {
    if (_discoverySocket == null || _currentGameId == null) return;

    final advertisement = LanGameAdvertisement(
      gameId: _currentGameId!,
      hostName: hostName,
      hostIp: _hostIp!,
      port: _gamePort!,
      variant: variant,
      timestamp: DateTime.now(),
    );

    final message = LanMessage(
      type: LanMessageType.gameAdvertisement,
      data: advertisement.toJson(),
    );

    final data = utf8.encode(jsonEncode(message.toJson()));
    _discoverySocket!.send(data, InternetAddress(multicastAddress), discoveryPort);
  }

  void _stopAdvertising() {
    _advertisementTimer?.cancel();
    _advertisementTimer = null;
  }

  void _listenToSocket(Socket socket) {
    socket.listen(
      (data) {
        try {
          final message = utf8.decode(data);
          final lines = message.split('\n').where((l) => l.trim().isNotEmpty);

          for (final line in lines) {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final lanMessage = LanMessage.fromJson(json);
            _messagesController.add(lanMessage);
          }
        } catch (e) {
          debugPrint('⚠️ Erro ao processar mensagem: $e');
        }
      },
      onError: (error) {
        debugPrint('❌ Erro no socket: $error');
        _disconnectController.add('error');
      },
      onDone: () {
        debugPrint('🔌 Conexão encerrada');
        _disconnectController.add('disconnect');
      },
    );
  }

  @override
  Future<void> sendMessage(LanMessage message) async {
    if (_gameSocket == null) return;

    try {
      _gameSocket!.write(message.toJsonString());
    } catch (e) {
      debugPrint('❌ Erro ao enviar mensagem: $e');
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _discoverySocket?.close();
    _discoverySocket = null;
  }

  @override
  Future<void> cleanup() async {
    _stopAdvertising();
    await stopDiscovery();

    _gameSocket?.close();
    _gameSocket = null;

    _gameServer?.close();
    _gameServer = null;

    _currentGameId = null;
    _availableGames.clear();
  }

  @override
  void dispose() {
    cleanup();
    _gamesController.close();
    _messagesController.close();
    _disconnectController.close();
  }
}
