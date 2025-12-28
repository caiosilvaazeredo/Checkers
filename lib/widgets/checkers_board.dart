import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../theme/app_theme.dart';

class CheckersBoard extends StatelessWidget {
  final GameState gameState;
  final Function(Position) onSquareTap;
  final bool isThinking;

  const CheckersBoard({
    super.key,
    required this.gameState,
    required this.onSquareTap,
    this.isThinking = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boardSize = (size.width < size.height ? size.width : size.height * 0.6) - 32;
    final squareSize = boardSize / 8;

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.surface, width: 4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: 64,
        itemBuilder: (context, index) {
          final row = index ~/ 8;
          final col = index % 8;
          final pos = Position(row, col);
          
          return _buildSquare(pos, squareSize);
        },
      ),
    );
  }

  Widget _buildSquare(Position pos, double size) {
    final isDark = (pos.row + pos.col) % 2 == 1;
    final piece = gameState.board[pos.row][pos.col];
    final isSelected = gameState.selectedPos == pos;
    final isValidDest = gameState.selectedPos != null &&
        gameState.validMoves.any((m) =>
            m.from == gameState.selectedPos && m.to == pos);
    final isMustCapture = gameState.mustCaptureFrom == pos;

    Color bgColor = isDark ? AppColors.boardDark : AppColors.boardLight;
    if (isSelected) bgColor = const Color(0xFFBBC546);

    return GestureDetector(
      onTap: () => onSquareTap(pos),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          border: isMustCapture && !isSelected
              ? Border.all(color: Colors.red.withOpacity(0.7), width: 3)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Valid move indicator
            if (isValidDest && piece == null)
              Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            
            // Piece
            if (piece != null)
              _buildPiece(piece, size, isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildPiece(Piece piece, double size, bool isSelected) {
    final isRed = piece.color == PlayerColor.red;
    final pieceSize = size * 0.8;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: pieceSize,
      height: pieceSize,
      transform: isSelected
          ? Matrix4.translationValues(0, -4, 0)
          : Matrix4.identity(),
      decoration: BoxDecoration(
        color: isRed ? AppColors.pieceRed : AppColors.pieceWhite,
        shape: BoxShape.circle,
        border: Border.all(
          color: isRed ? AppColors.pieceRedBorder : AppColors.pieceWhiteBorder,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 0,
            offset: const Offset(0, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: piece.isKing
          ? Icon(
              Icons.favorite,
              color: isRed
                  ? AppColors.pieceRedBorder
                  : AppColors.pieceWhiteBorder.withOpacity(0.6),
              size: pieceSize * 0.5,
            )
          : Container(
              margin: EdgeInsets.all(pieceSize * 0.15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (isRed ? AppColors.pieceRedBorder : AppColors.pieceWhiteBorder)
                      .withOpacity(0.3),
                  width: 2,
                ),
              ),
            ),
    );
  }
}
