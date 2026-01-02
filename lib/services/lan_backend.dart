import 'dart:async';
import '../models/lan_game_model.dart';
import '../models/game_model.dart';

/// Interface abstrata para backend de comunicação LAN
/// Permite implementações diferentes para plataformas nativas e web
abstract class LanBackend {
  /// Stream de jogos disponíveis descobertos
  Stream<List<LanGameAdvertisement>> get gamesStream;

  /// Stream de mensagens recebidas
  Stream<LanMessage> get messagesStream;

  /// Stream de eventos de desconexão
  Stream<String> get disconnectStream;

  /// Inicia hospedagem de um jogo
  Future<bool> hostGame({
    required String gameId,
    required String hostName,
    required GameVariant variant,
  });

  /// Inicia descoberta de jogos
  Future<void> discoverGames();

  /// Conecta a um jogo específico
  Future<bool> joinGame({
    required LanGameAdvertisement game,
    required String playerName,
  });

  /// Envia uma mensagem
  Future<void> sendMessage(LanMessage message);

  /// Para descoberta de jogos
  Future<void> stopDiscovery();

  /// Limpa recursos
  Future<void> cleanup();

  /// Fecha o backend
  void dispose();
}
