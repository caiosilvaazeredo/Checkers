import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../models/online_match_model.dart';
import '../../services/game_service.dart';
import '../../services/matchmaking_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/checkers_board.dart';
import '../../widgets/chat_widget.dart';

class GameScreen extends StatefulWidget {
  final GameMode mode;
  final GameVariant variant;
  final String? onlineMatchId;

  const GameScreen({
    super.key,
    required this.mode,
    this.variant = GameVariant.american,
    this.onlineMatchId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeGame();
    });
  }

  void _initializeGame() {
    final game = context.read<GameService>();

    if (widget.mode == GameMode.online && widget.onlineMatchId != null) {
      // Carregar partida online
      final matchmaking = context.read<MatchmakingService>();
      matchmaking.loadMatch(widget.onlineMatchId!);
    } else {
      // Iniciar jogo local (AI ou PvP)
      game.startGame(widget.variant, widget.mode);
    }
  }

  void _handleOnlineMove(Move move) async {
    final matchmaking = context.read<MatchmakingService>();
    final game = context.read<GameService>();
    final match = matchmaking.currentMatch;

    if (match == null || game.gameState == null) return;

    final moveData = game.getOnlineMoveData();
    if (moveData == null) return;

    await matchmaking.makeMove(
      matchId: match.matchId,
      from: move.from,
      to: move.to,
      isCapture: move.isCapture,
      capturedPos: move.capturedPos,
      newBoard: moveData['board'] as List<List<String?>>,
      nextTurn: moveData['currentTurn'] as PlayerColor,
      winner: moveData['winner'] != null
          ? match.getPlayerUid(moveData['winner'] as PlayerColor)
          : null,
    );
  }

  void _openChat() {
    if (widget.onlineMatchId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ChatWidget(matchId: widget.onlineMatchId!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Checkers'),
        actions: [
          if (widget.mode == GameMode.online && widget.onlineMatchId != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: _openChat,
              tooltip: 'Chat',
            ),
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _showResignDialog(context),
          ),
        ],
      ),
      body: widget.mode == GameMode.online
          ? _buildOnlineGameBody()
          : _buildLocalGameBody(),
      floatingActionButton: widget.mode == GameMode.online && widget.onlineMatchId != null
          ? FloatingActionButton(
              onPressed: _openChat,
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.chat),
            )
          : null,
    );
  }

  Widget _buildOnlineGameBody() {
    return Consumer2<GameService, MatchmakingService>(
      builder: (context, game, matchmaking, _) {
        final match = matchmaking.currentMatch;
        final auth = context.read<AuthService>();

        if (match == null || auth.currentUser == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Carregar o jogo se ainda não foi carregado
        if (game.gameState == null || game.onlineMatchId != match.matchId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            game.loadOnlineGame(match, auth.currentUser!.uid);
          });
          return const Center(child: CircularProgressIndicator());
        }

        final state = game.gameState!;
        final myColor = game.getMyColor(match);
        final isMyTurn = game.isMyTurn(match);

        final opponent = myColor == PlayerColor.red
            ? match.whitePlayer
            : match.redPlayer;
        final me = myColor == PlayerColor.red
            ? match.redPlayer
            : match.whitePlayer;

        return Column(
          children: [
            // Opponent info
            _PlayerBar(
              name: opponent?.username ?? 'Oponente',
              rating: opponent?.rating,
              isActive: state.turn != myColor,
              color: opponent?.color ?? PlayerColor.white,
            ),

            // Board
            Expanded(
              child: Center(
                child: CheckersBoard(
                  gameState: state,
                  onSquareTap: (pos) {
                    if (isMyTurn && !match.isCompleted) {
                      game.selectSquare(pos, onOnlineMove: _handleOnlineMove);
                    }
                  },
                  isThinking: false,
                ),
              ),
            ),

            // Turn indicator
            if (!match.isCompleted)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isMyTurn ? 'Sua vez!' : 'Aguardando oponente...',
                  style: TextStyle(
                    color: isMyTurn ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // My info
            _PlayerBar(
              name: me?.username ?? 'Você',
              rating: me?.rating,
              isActive: state.turn == myColor,
              color: me?.color ?? PlayerColor.red,
            ),

            // Move history
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
            const SizedBox(height: 16),

            // Winner overlay
            if (state.winner != null)
              _buildOnlineWinnerOverlay(context, state.winner!, match, myColor),
          ],
        );
      },
    );
  }

  Widget _buildLocalGameBody() {
    return Consumer<GameService>(
      builder: (context, game, _) {
        final state = game.gameState;
        if (state == null) {
          return const Center(child: Text('No game in progress'));
        }

        return Column(
          children: [
            // Top player info
            _PlayerBar(
              name: state.mode == GameMode.ai ? 'Gemini AI' : 'White',
              isActive: state.turn == PlayerColor.white,
              color: PlayerColor.white,
            ),

            // Board
            Expanded(
              child: Center(
                child: CheckersBoard(
                  gameState: state,
                  onSquareTap: game.selectSquare,
                  isThinking: game.isAiThinking,
                ),
              ),
            ),
              
              // AI Explanation
              if (game.aiExplanation != null && state.mode == GameMode.ai)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.psychology, color: AppColors.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          game.aiExplanation!,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Bottom player info
              _PlayerBar(
                name: 'You',
                isActive: state.turn == PlayerColor.red,
                color: PlayerColor.red,
              ),
              
              // Move history
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
              const SizedBox(height: 16),
              
              // Winner dialog
              if (state.winner != null)
                _buildWinnerOverlay(context, state.winner!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWinnerOverlay(BuildContext context, PlayerColor winner) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: winner == PlayerColor.red ? AppColors.pieceRed : AppColors.accent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            winner == PlayerColor.red ? '🎉 You Win!' : 'AI Wins',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<GameService>().resetGame();
                  Navigator.pop(context);
                },
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineWinnerOverlay(
    BuildContext context,
    PlayerColor winner,
    OnlineMatch match,
    PlayerColor? myColor,
  ) {
    final didIWin = winner == myColor;
    final winnerName = winner == PlayerColor.red
        ? match.redPlayer?.username
        : match.whitePlayer?.username;

    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: didIWin ? AppColors.accent : AppColors.pieceRed,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            didIWin ? '🎉 Você Venceu!' : '${winnerName ?? "Oponente"} Venceu',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<GameService>().resetGame();
                  Navigator.pop(context);
                },
                child: const Text('Voltar ao Menu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desistir?'),
        content: const Text('Tem certeza que deseja desistir desta partida?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.mode == GameMode.online && widget.onlineMatchId != null) {
                final auth = context.read<AuthService>();
                if (auth.currentUser != null) {
                  context.read<MatchmakingService>().resignMatch(
                        widget.onlineMatchId!,
                        auth.currentUser!.uid,
                      );
                }
              } else {
                context.read<GameService>().resign();
              }
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desistir'),
          ),
        ],
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final String name;
  final bool isActive;
  final PlayerColor color;
  final int? rating;

  const _PlayerBar({
    required this.name,
    required this.isActive,
    required this.color,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border.all(color: AppColors.accent, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color == PlayerColor.red
                  ? AppColors.pieceRed
                  : AppColors.pieceWhite,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (rating != null)
                  Text(
                    'Rating: $rating',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
