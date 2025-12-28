import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../models/online_match_model.dart';
import '../../models/game_model.dart';
import '../../services/game_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/checkers_board.dart';

class SpectatorScreen extends StatefulWidget {
  const SpectatorScreen({Key? key}) : super(key: key);

  @override
  State<SpectatorScreen> createState() => _SpectatorScreenState();
}

class _SpectatorScreenState extends State<SpectatorScreen> {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  List<OnlineMatch> _liveMatches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveMatches();
  }

  Future<void> _loadLiveMatches() async {
    try {
      final snapshot = await _db.ref('matches')
          .orderByChild('status')
          .equalTo(MatchStatus.active.toString().split('.').last)
          .limitToFirst(20)
          .get();

      if (snapshot.exists) {
        final matchesMap = Map<String, dynamic>.from(snapshot.value as Map);
        _liveMatches = matchesMap.values
            .map((data) => OnlineMatch.fromMap(Map<String, dynamic>.from(data)))
            .toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidas ao Vivo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _loadLiveMatches();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _liveMatches.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.live_tv, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma partida ao vivo no momento',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _liveMatches.length,
                  itemBuilder: (context, index) {
                    final match = _liveMatches[index];
                    return _MatchCard(
                      match: match,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpectatorGameScreen(match: match),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final OnlineMatch match;
  final VoidCallback onTap;

  const _MatchCard({
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fiber_manual_record,
                  color: Colors.red,
                  size: 16,
                ),
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
                            match.redPlayer?.username ?? 'Jogador 1',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text('vs'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.whitePlayer?.username ?? 'Jogador 2',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${match.moveHistory.length} movimentos • ${match.variant == GameVariant.american ? "Americana" : "Brasileira"}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class SpectatorGameScreen extends StatefulWidget {
  final OnlineMatch match;

  const SpectatorGameScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<SpectatorGameScreen> createState() => _SpectatorGameScreenState();
}

class _SpectatorGameScreenState extends State<SpectatorGameScreen> {
  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  void _loadGame() {
    final game = context.read<GameService>();
    game.loadOnlineGame(widget.match, ''); // Espectador não tem ID
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.live_tv, size: 20, color: Colors.red),
            SizedBox(width: 8),
            Text('Modo Espectador'),
          ],
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance
            .ref('matches/${widget.match.matchId}')
            .onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.snapshot.value == null) {
            return const Center(child: Text('Partida não encontrada'));
          }

          final matchData = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
          final liveMatch = OnlineMatch.fromMap(matchData);

          // Atualizar o jogo quando houver mudanças
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final game = context.read<GameService>();
            game.loadOnlineGame(liveMatch, '');
          });

          return Consumer<GameService>(
            builder: (context, game, _) {
              final state = game.gameState;
              if (state == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: [
                  // Info da partida
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.surface,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _PlayerInfo(
                              name: liveMatch.redPlayer?.username ?? 'Jogador 1',
                              rating: liveMatch.redPlayer?.rating,
                              isActive: state.turn == PlayerColor.red,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.fiber_manual_record,
                                      color: Colors.red, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'AO VIVO',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _PlayerInfo(
                              name: liveMatch.whitePlayer?.username ?? 'Jogador 2',
                              rating: liveMatch.whitePlayer?.rating,
                              isActive: state.turn == PlayerColor.white,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tabuleiro
                  Expanded(
                    child: Center(
                      child: CheckersBoard(
                        gameState: state,
                        onSquareTap: (_) {}, // Sem interação no modo espectador
                        isThinking: false,
                      ),
                    ),
                  ),

                  // Histórico de movimentos
                  Container(
                    height: 80,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Movimentos: ${state.history.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.history.length,
                            itemBuilder: (context, i) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Chip(
                                label: Text(
                                  '${(i ~/ 2) + 1}. ${state.history[i]}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: AppColors.surface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _PlayerInfo extends StatelessWidget {
  final String name;
  final int? rating;
  final bool isActive;

  const _PlayerInfo({
    required this.name,
    this.rating,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
            color: isActive ? AppColors.accent : AppColors.textPrimary,
          ),
        ),
        if (rating != null)
          Text(
            'Rating: $rating',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
