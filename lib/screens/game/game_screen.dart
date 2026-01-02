import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../models/lan_game_model.dart';
import '../../services/game_service.dart';
import '../../services/online_game_service.dart';
import '../../services/lan_game_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/checkers_board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isOnlineGame = false;
  bool _isLanGame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onlineGame = context.read<OnlineGameService>();
      final lanGame = context.read<LanGameService>();

      if (onlineGame.currentGame != null) {
        setState(() => _isOnlineGame = true);
      } else if (lanGame.status == LanConnectionStatus.connected) {
        setState(() => _isLanGame = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnlineGame) {
      return _buildOnlineGame(context);
    } else if (_isLanGame) {
      return _buildLanGame(context);
    } else {
      return _buildLocalGame(context);
    }
  }

  Widget _buildLocalGame(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Checkers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _showResignDialog(context),
          ),
        ],
      ),
      body: Consumer<GameService>(
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

  Widget _buildOnlineGame(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _showOnlineResignDialog(context),
          ),
        ],
      ),
      body: Consumer2<OnlineGameService, AuthService>(
        builder: (context, onlineGame, auth, _) {
          final game = onlineGame.currentGame;
          if (game == null) {
            return const Center(child: Text('No game in progress'));
          }

          final state = game.gameState;
          final myColor = onlineGame.myColor;
          final opponent = myColor == PlayerColor.red
              ? game.whitePlayer
              : game.redPlayer;
          final me = myColor == PlayerColor.red ? game.redPlayer : game.whitePlayer;
          final isMyTurn = state.turn == myColor;

          return Column(
            children: [
              // Opponent info
              _OnlinePlayerBar(
                player: opponent,
                isActive: state.turn != myColor,
                color: myColor == PlayerColor.red
                    ? PlayerColor.white
                    : PlayerColor.red,
              ),

              // Board
              Expanded(
                child: Center(
                  child: CheckersBoard(
                    gameState: state,
                    onSquareTap: isMyTurn
                        ? (pos) => _handleOnlineMove(context, pos, state, onlineGame)
                        : (_) {}, // Disable moves when not my turn
                    isThinking: !isMyTurn,
                  ),
                ),
              ),

              // Turn indicator
              if (!isMyTurn)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Waiting for ${opponent.username}...',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

              // My player info
              _OnlinePlayerBar(
                player: me,
                isActive: isMyTurn,
                color: myColor!,
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
                _buildOnlineWinnerOverlay(context, state.winner!, myColor!),
            ],
          );
        },
      ),
    );
  }

  void _handleOnlineMove(BuildContext context, Position pos, GameState state, OnlineGameService onlineGame) {
    // Handle piece selection
    final piece = state.board[pos.row][pos.col];

    if (piece != null && piece.color == onlineGame.myColor) {
      // Selected own piece - just update local state for visual feedback
      // This will be managed by the OnlineGameService
      return;
    }

    // Check if it's a valid move
    if (state.selectedPos != null) {
      final validMoves = _calculateValidMovesForOnline(state);
      final move = validMoves.where((m) =>
        m.from == state.selectedPos && m.to == pos
      ).firstOrNull;

      if (move != null) {
        onlineGame.makeMove(move);
      }
    }
  }

  List<Move> _calculateValidMovesForOnline(GameState state) {
    final moves = <Move>[];
    final captures = <Move>[];

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = state.board[r][c];
        if (piece == null || piece.color != state.turn) continue;

        final pieceMoves = _getPieceMovesForOnline(Position(r, c), piece, state);
        for (final move in pieceMoves) {
          if (move.isCapture) {
            captures.add(move);
          } else {
            moves.add(move);
          }
        }
      }
    }

    return captures.isNotEmpty ? captures : moves;
  }

  List<Move> _getPieceMovesForOnline(Position pos, Piece piece, GameState state) {
    final moves = <Move>[];
    final isKing = piece.isKing;
    final forward = piece.color == PlayerColor.red ? -1 : 1;

    // Simple American checkers rules
    final moveDirs = isKing
        ? [[-1, -1], [-1, 1], [1, -1], [1, 1]]
        : [[forward, -1], [forward, 1]];

    for (final dir in moveDirs) {
      final r = pos.row + dir[0];
      final c = pos.col + dir[1];
      if (_isValidPos(r, c) && state.board[r][c] == null) {
        moves.add(Move(from: pos, to: Position(r, c)));
      }
    }

    // Capture moves
    for (final dir in moveDirs) {
      final r1 = pos.row + dir[0];
      final c1 = pos.col + dir[1];
      final r2 = pos.row + dir[0] * 2;
      final c2 = pos.col + dir[1] * 2;

      if (_isValidPos(r2, c2) && state.board[r2][c2] == null) {
        final midPiece = state.board[r1][c1];
        if (midPiece != null && midPiece.color != piece.color) {
          moves.add(Move(
            from: pos,
            to: Position(r2, c2),
            isCapture: true,
            capturedPos: Position(r1, c1),
          ));
        }
      }
    }

    return moves;
  }

  bool _isValidPos(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  Widget _buildOnlineWinnerOverlay(BuildContext context, PlayerColor winner, PlayerColor myColor) {
    final didIWin = winner == myColor;
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
            didIWin ? '🎉 You Win!' : '😞 You Lost',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final auth = context.read<AuthService>();
                  final onlineGame = context.read<OnlineGameService>();
                  await onlineGame.leaveGame(auth.currentUser!.uid);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Back to Menu'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOnlineResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final auth = context.read<AuthService>();
              final onlineGame = context.read<OnlineGameService>();
              await onlineGame.leaveGame(auth.currentUser!.uid);
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resign'),
          ),
        ],
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

  void _showResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('Are you sure you want to resign this game?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GameService>().resign();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  // LAN Game UI
  Widget _buildLanGame(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Jogo LAN'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Casual',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: () => _showLanResignDialog(context),
          ),
        ],
      ),
      body: Consumer<LanGameService>(
        builder: (context, lanService, _) {
          final state = lanService.gameState;
          if (state == null) {
            return const Center(child: Text('No game in progress'));
          }

          final myColor = lanService.myColor;
          final isMyTurn = state.turn == myColor;
          final opponentColor = myColor == PlayerColor.red
              ? PlayerColor.white
              : PlayerColor.red;

          return Column(
            children: [
              // Opponent info
              _LanPlayerBar(
                name: lanService.isHost ? 'Guest' : 'Host',
                isActive: !isMyTurn,
                color: opponentColor,
                isHost: !lanService.isHost,
              ),

              // Board
              Expanded(
                child: Center(
                  child: CheckersBoard(
                    gameState: state,
                    onSquareTap: isMyTurn
                        ? (pos) => _handleLanMove(context, pos, state, lanService)
                        : (_) {}, // Disable moves when not my turn
                    isThinking: !isMyTurn,
                  ),
                ),
              ),

              // Turn indicator
              if (!isMyTurn)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Aguardando oponente...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),

              // My player info
              _LanPlayerBar(
                name: 'Você',
                isActive: isMyTurn,
                color: myColor!,
                isHost: lanService.isHost,
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
                _buildLanWinnerOverlay(context, state.winner!, myColor!),
            ],
          );
        },
      ),
    );
  }

  void _handleLanMove(BuildContext context, Position pos, GameState state, LanGameService lanService) {
    // Handle piece selection
    final piece = state.board[pos.row][pos.col];

    if (piece != null && piece.color == lanService.myColor) {
      // Selected own piece - just update local state for visual feedback
      return;
    }

    // Check if it's a valid move
    if (state.selectedPos != null) {
      final validMoves = _calculateValidMovesForOnline(state);
      final move = validMoves.where((m) =>
        m.from == state.selectedPos && m.to == pos
      ).firstOrNull;

      if (move != null) {
        lanService.sendMove(move);
      }
    }
  }

  void _showLanResignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desistir?'),
        content: const Text('Tem certeza que quer desistir deste jogo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final lanService = context.read<LanGameService>();
              lanService.resign();
              await lanService.cleanup();
              if (context.mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desistir'),
          ),
        ],
      ),
    );
  }

  Widget _buildLanWinnerOverlay(BuildContext context, PlayerColor winner, PlayerColor myColor) {
    final didIWin = winner == myColor;
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
            didIWin ? '🎉 Você Venceu!' : '😞 Você Perdeu',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Jogo casual - não afeta ranking',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  final lanService = context.read<LanGameService>();
                  await lanService.cleanup();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Voltar ao Menu'),
              ),
            ],
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

  const _PlayerBar({
    required this.name,
    required this.isActive,
    required this.color,
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
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
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

class _OnlinePlayerBar extends StatelessWidget {
  final OnlinePlayer player;
  final bool isActive;
  final PlayerColor color;

  const _OnlinePlayerBar({
    required this.player,
    required this.isActive,
    required this.color,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.username,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rating: ${player.rating}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isActive) ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ],
          if (!player.connected) ...[
            const Icon(
              Icons.cloud_off,
              size: 16,
              color: Colors.red,
            ),
          ],
        ],
      ),
    );
  }
}

class _LanPlayerBar extends StatelessWidget {
  final String name;
  final bool isActive;
  final PlayerColor color;
  final bool isHost;

  const _LanPlayerBar({
    required this.name,
    required this.isActive,
    required this.color,
    required this.isHost,
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Icon(
                    isHost ? Icons.wifi_tethering : Icons.wifi,
                    size: 12,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isHost ? 'Host' : 'Guest',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (isActive) ...[
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
