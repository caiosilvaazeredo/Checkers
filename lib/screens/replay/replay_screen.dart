import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/match_history_model.dart';
import '../../models/game_model.dart';
import '../../services/game_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/checkers_board.dart';

class ReplayScreen extends StatefulWidget {
  final MatchHistory match;

  const ReplayScreen({Key? key, required this.match}) : super(key: key);

  @override
  State<ReplayScreen> createState() => _ReplayScreenState();
}

class _ReplayScreenState extends State<ReplayScreen> {
  int _currentMoveIndex = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeReplay();
  }

  void _initializeReplay() {
    final game = context.read<GameService>();
    game.startGame(widget.match.variant, GameMode.pvp);
  }

  void _executeMovesToIndex(int targetIndex) {
    final game = context.read<GameService>();

    // Reiniciar o jogo
    game.startGame(widget.match.variant, GameMode.pvp);

    // Executar movimentos até o índice desejado
    for (int i = 0; i <= targetIndex && i < widget.match.moveHistory.length; i++) {
      _executeMove(i);
    }

    setState(() {
      _currentMoveIndex = targetIndex;
    });
  }

  void _executeMove(int index) {
    if (index >= widget.match.moveHistory.length) return;

    final game = context.read<GameService>();
    final state = game.gameState;
    if (state == null) return;

    final moveNotation = widget.match.moveHistory[index];

    // Parsear notação (ex: "a2-b3" ou "a2xc4")
    final parts = moveNotation.contains('x')
        ? moveNotation.split('x')
        : moveNotation.split('-');

    if (parts.length != 2) return;

    final from = _parsePosition(parts[0]);
    final to = _parsePosition(parts[1]);

    if (from == null || to == null) return;

    // Simular seleção e movimento
    game.selectSquare(from);
    game.selectSquare(to);
  }

  Position? _parsePosition(String notation) {
    if (notation.length < 2) return null;

    final col = notation.codeUnitAt(0) - 97; // 'a' = 0
    final row = 8 - int.parse(notation[1]); // '8' = 0, '1' = 7

    if (row < 0 || row >= 8 || col < 0 || col >= 8) return null;
    return Position(row, col);
  }

  void _nextMove() {
    if (_currentMoveIndex < widget.match.moveHistory.length - 1) {
      _executeMovesToIndex(_currentMoveIndex + 1);
    }
  }

  void _previousMove() {
    if (_currentMoveIndex > 0) {
      _executeMovesToIndex(_currentMoveIndex - 1);
    }
  }

  void _goToStart() {
    _executeMovesToIndex(-1);
    setState(() {
      _currentMoveIndex = -1;
    });
    final game = context.read<GameService>();
    game.startGame(widget.match.variant, GameMode.pvp);
  }

  void _goToEnd() {
    _executeMovesToIndex(widget.match.moveHistory.length - 1);
  }

  void _toggleAutoPlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _autoPlay();
    }
  }

  Future<void> _autoPlay() async {
    while (_isPlaying && _currentMoveIndex < widget.match.moveHistory.length - 1) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_isPlaying) {
        _nextMove();
      }
    }
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replay de Partida'),
        elevation: 0,
      ),
      body: Consumer<GameService>(
        builder: (context, game, _) {
          final state = game.gameState;

          if (state == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Informações da partida
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.match.player1Name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text('vs'),
                        Text(
                          widget.match.player2Name ?? 'Oponente',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Movimento ${_currentMoveIndex + 1} de ${widget.match.moveHistory.length}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    if (_currentMoveIndex >= 0 && _currentMoveIndex < widget.match.moveHistory.length)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.match.moveHistory[_currentMoveIndex],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Tabuleiro
              Expanded(
                child: Center(
                  child: CheckersBoard(
                    gameState: state,
                    onSquareTap: (_) {}, // Sem interação durante replay
                    isThinking: false,
                  ),
                ),
              ),

              // Controles de replay
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Column(
                  children: [
                    // Barra de progresso
                    Slider(
                      value: _currentMoveIndex.toDouble(),
                      min: -1,
                      max: (widget.match.moveHistory.length - 1).toDouble(),
                      divisions: widget.match.moveHistory.length,
                      activeColor: AppColors.accent,
                      onChanged: (value) {
                        _executeMovesToIndex(value.toInt());
                      },
                    ),

                    // Botões de controle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: _goToStart,
                          iconSize: 32,
                          color: AppColors.accent,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _currentMoveIndex > 0 ? _previousMove : null,
                          iconSize: 32,
                          color: AppColors.accent,
                        ),
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: _toggleAutoPlay,
                          iconSize: 48,
                          color: AppColors.accent,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _currentMoveIndex < widget.match.moveHistory.length - 1
                              ? _nextMove
                              : null,
                          iconSize: 32,
                          color: AppColors.accent,
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: _goToEnd,
                          iconSize: 32,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de movimentos
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.match.moveHistory.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentMoveIndex;
                    return GestureDetector(
                      onTap: () => _executeMovesToIndex(index),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppColors.accent : Colors.grey[700]!,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.match.moveHistory[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _isPlaying = false;
    super.dispose();
  }
}
