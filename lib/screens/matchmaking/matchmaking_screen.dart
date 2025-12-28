import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/matchmaking_service.dart';
import '../../services/auth_service.dart';
import '../../models/game_model.dart';
import '../../models/online_match_model.dart';
import '../game/game_screen.dart';

class MatchmakingScreen extends StatefulWidget {
  const MatchmakingScreen({Key? key}) : super(key: key);

  @override
  State<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends State<MatchmakingScreen> {
  GameVariant _selectedVariant = GameVariant.american;

  @override
  void initState() {
    super.initState();
    // Verificar se já está em uma partida
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchmaking = context.read<MatchmakingService>();
      if (matchmaking.currentMatch != null && matchmaking.currentMatch!.isActive) {
        _navigateToGame(matchmaking.currentMatch!);
      }
    });
  }

  void _navigateToGame(OnlineMatch match) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameScreen(
          mode: GameMode.online,
          variant: match.variant,
          onlineMatchId: match.matchId,
        ),
      ),
    );
  }

  Future<void> _startMatchmaking() async {
    final auth = context.read<AuthService>();
    final matchmaking = context.read<MatchmakingService>();

    if (auth.currentUser == null) return;

    await matchmaking.joinMatchmakingQueue(
      user: auth.currentUser!,
      variant: _selectedVariant,
    );
  }

  Future<void> _cancelMatchmaking() async {
    final auth = context.read<AuthService>();
    final matchmaking = context.read<MatchmakingService>();

    if (auth.currentUser == null) return;

    await matchmaking.leaveQueue(auth.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Matchmaking'),
        elevation: 0,
      ),
      body: Consumer<MatchmakingService>(
        builder: (context, matchmaking, _) {
          // Se encontrou partida e está ativa, navegar para o jogo
          if (matchmaking.currentMatch != null && matchmaking.currentMatch!.isActive) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _navigateToGame(matchmaking.currentMatch!);
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (matchmaking.error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            matchmaking.error!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: matchmaking.clearError,
                        ),
                      ],
                    ),
                  ),

                // Seletor de variante
                if (!matchmaking.isSearching) ...[
                  const Text(
                    'Selecione a variante:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _VariantButton(
                          variant: GameVariant.american,
                          selected: _selectedVariant == GameVariant.american,
                          onTap: () => setState(() => _selectedVariant = GameVariant.american),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VariantButton(
                          variant: GameVariant.brazilian,
                          selected: _selectedVariant == GameVariant.brazilian,
                          onTap: () => setState(() => _selectedVariant = GameVariant.brazilian),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],

                // Botão de iniciar/cancelar busca
                if (!matchmaking.isSearching)
                  ElevatedButton.icon(
                    onPressed: matchmaking.isLoading ? null : _startMatchmaking,
                    icon: const Icon(Icons.search),
                    label: const Text('Buscar Partida'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        matchmaking.currentMatch != null && matchmaking.currentMatch!.isWaiting
                            ? 'Aguardando oponente...'
                            : 'Procurando partida...',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      if (matchmaking.currentMatch != null && matchmaking.currentMatch!.isWaiting)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262421),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Partida criada!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'ID: ${matchmaking.currentMatch!.matchId.substring(0, 8)}...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _cancelMatchmaking,
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar Busca'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                // Convites de amigos
                const Text(
                  'Convites de Amigos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _FriendInvitesList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _VariantButton extends StatelessWidget {
  final GameVariant variant;
  final bool selected;
  final VoidCallback onTap;

  const _VariantButton({
    required this.variant,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = variant == GameVariant.american ? 'Americana' : 'Brasileira';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF81B64C) : const Color(0xFF262421),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF81B64C) : Colors.grey[700]!,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.extension,
              color: selected ? Colors.white : Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey[400],
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendInvitesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      return const Text('Nenhum convite pendente');
    }

    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('match_invites/${auth.currentUser!.uid}').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Text('Nenhum convite pendente');
        }

        final invitesData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final invites = <MapEntry<String, dynamic>>[];

        invitesData.forEach((key, value) {
          invites.add(MapEntry(key, value));
        });

        if (invites.isEmpty) {
          return const Text('Nenhum convite pendente');
        }

        return Column(
          children: invites.map((entry) {
            final inviteData = Map<String, dynamic>.from(entry.value);
            return _InviteCard(
              inviteId: entry.key,
              senderUsername: inviteData['senderUsername'] ?? 'Jogador',
              matchId: inviteData['matchId'] ?? '',
              variant: inviteData['variant'] ?? 'american',
            );
          }).toList(),
        );
      },
    );
  }
}

class _InviteCard extends StatelessWidget {
  final String inviteId;
  final String senderUsername;
  final String matchId;
  final String variant;

  const _InviteCard({
    required this.inviteId,
    required this.senderUsername,
    required this.matchId,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final matchmaking = context.read<MatchmakingService>();

    return Card(
      color: const Color(0xFF262421),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF81B64C)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Damas ${variant == 'american' ? 'Americana' : 'Brasileira'}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () async {
                if (auth.currentUser != null) {
                  final success = await matchmaking.acceptFriendInvite(
                    user: auth.currentUser!,
                    matchId: matchId,
                    inviteId: inviteId,
                  );
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Entrando na partida...')),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () async {
                if (auth.currentUser != null) {
                  await matchmaking.declineInvite(
                    auth.currentUser!.uid,
                    inviteId,
                    matchId,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
