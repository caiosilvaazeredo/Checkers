enum PlayerColor { red, white }
enum PieceType { man, king }
enum GameVariant { american, brazilian }
enum GameMode { ai, pvp, online, lan }

class Position {
  final int row;
  final int col;
  const Position(this.row, this.col);
  
  @override
  bool operator ==(Object other) =>
      other is Position && other.row == row && other.col == col;
  
  @override
  int get hashCode => row.hashCode ^ col.hashCode;
  
  @override
  String toString() => '($row, $col)';
}

class Piece {
  final PlayerColor color;
  final PieceType type;
  
  const Piece({required this.color, this.type = PieceType.man});
  
  Piece promote() => Piece(color: color, type: PieceType.king);
  bool get isKing => type == PieceType.king;
}

class Move {
  final Position from;
  final Position to;
  final bool isCapture;
  final Position? capturedPos;
  
  const Move({
    required this.from,
    required this.to,
    this.isCapture = false,
    this.capturedPos,
  });
  
  String toNotation() {
    final fromCol = String.fromCharCode(97 + from.col);
    final toCol = String.fromCharCode(97 + to.col);
    return '$fromCol${8 - from.row}-$toCol${8 - to.row}';
  }
}

class GameState {
  final List<List<Piece?>> board;
  final PlayerColor turn;
  final Position? selectedPos;
  final List<Move> validMoves;
  final Position? mustCaptureFrom;
  final PlayerColor? winner;
  final List<String> history;
  final GameVariant variant;
  final GameMode mode;
  
  GameState({
    required this.board,
    this.turn = PlayerColor.red,
    this.selectedPos,
    this.validMoves = const [],
    this.mustCaptureFrom,
    this.winner,
    this.history = const [],
    this.variant = GameVariant.american,
    this.mode = GameMode.ai,
  });
  
  GameState copyWith({
    List<List<Piece?>>? board,
    PlayerColor? turn,
    Position? selectedPos,
    List<Move>? validMoves,
    Position? mustCaptureFrom,
    PlayerColor? winner,
    List<String>? history,
    bool clearSelection = false,
    bool clearMustCapture = false,
  }) => GameState(
    board: board ?? this.board,
    turn: turn ?? this.turn,
    selectedPos: clearSelection ? null : (selectedPos ?? this.selectedPos),
    validMoves: validMoves ?? this.validMoves,
    mustCaptureFrom: clearMustCapture ? null : (mustCaptureFrom ?? this.mustCaptureFrom),
    winner: winner ?? this.winner,
    history: history ?? this.history,
    variant: variant,
    mode: mode,
  );
}
