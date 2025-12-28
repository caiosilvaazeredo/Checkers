import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/online_match_model.dart';

class GameService extends ChangeNotifier {
  GameState? _gameState;
  bool _isAiThinking = false;
  String? _aiExplanation;
  String _aiDifficulty = 'hard';
  String? _onlineMatchId;
  String? _myPlayerId;

  GameState? get gameState => _gameState;
  bool get isAiThinking => _isAiThinking;
  String? get aiExplanation => _aiExplanation;
  String get aiDifficulty => _aiDifficulty;
  String? get onlineMatchId => _onlineMatchId;
  String? get myPlayerId => _myPlayerId;
  
  void setDifficulty(String difficulty) {
    _aiDifficulty = difficulty;
    notifyListeners();
  }
  
  void startGame(GameVariant variant, GameMode mode, {String? matchId, String? playerId}) {
    _gameState = GameState(
      board: _createInitialBoard(),
      variant: variant,
      mode: mode,
    );
    _onlineMatchId = matchId;
    _myPlayerId = playerId;
    _calculateValidMoves();
    _aiExplanation = null;
    notifyListeners();
  }

  // Carregar jogo online a partir de OnlineMatch
  void loadOnlineGame(OnlineMatch match, String myPlayerId) {
    _onlineMatchId = match.matchId;
    _myPlayerId = myPlayerId;

    final board = _convertOnlineBoardToGameBoard(match.board);

    _gameState = GameState(
      board: board,
      variant: match.variant,
      mode: GameMode.online,
      turn: match.currentTurn,
      history: match.moveHistory,
      winner: match.winner != null ? _getPlayerColorFromUid(match, match.winner!) : null,
    );

    _calculateValidMoves();
    notifyListeners();
  }

  // Converter board online (String) para board do jogo (Piece)
  List<List<Piece?>> _convertOnlineBoardToGameBoard(List<List<String?>> onlineBoard) {
    return onlineBoard.map((row) {
      return row.map((cell) {
        if (cell == null) return null;
        final parts = cell.split('-');
        final color = parts[0] == 'red' ? PlayerColor.red : PlayerColor.white;
        final type = parts[1] == 'king' ? PieceType.king : PieceType.man;
        return Piece(color: color, type: type);
      }).toList();
    }).toList();
  }

  // Converter board do jogo (Piece) para board online (String)
  List<List<String?>> _convertGameBoardToOnlineBoard(List<List<Piece?>> gameBoard) {
    return gameBoard.map((row) {
      return row.map((cell) {
        if (cell == null) return null;
        final colorStr = cell.color == PlayerColor.red ? 'red' : 'white';
        final typeStr = cell.type == PieceType.king ? 'king' : 'man';
        return '$colorStr-$typeStr';
      }).toList();
    }).toList();
  }

  PlayerColor? _getPlayerColorFromUid(OnlineMatch match, String uid) {
    if (match.redPlayer?.uid == uid) return PlayerColor.red;
    if (match.whitePlayer?.uid == uid) return PlayerColor.white;
    return null;
  }

  PlayerColor? getMyColor(OnlineMatch match) {
    if (_myPlayerId == null) return null;
    return _getPlayerColorFromUid(match, _myPlayerId!);
  }

  bool isMyTurn(OnlineMatch match) {
    if (_myPlayerId == null || _gameState == null) return false;
    final myColor = getMyColor(match);
    return myColor == _gameState!.turn;
  }

  // Obter dados do movimento para sincronizar online
  Map<String, dynamic>? getOnlineMoveData() {
    if (_gameState == null) return null;
    return {
      'board': _convertGameBoardToOnlineBoard(_gameState!.board),
      'currentTurn': _gameState!.turn,
      'winner': _gameState!.winner,
    };
  }
  
  List<List<Piece?>> _createInitialBoard() {
    final board = List.generate(8, (_) => List<Piece?>.filled(8, null));
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if ((r + c) % 2 == 1) {
          if (r < 3) board[r][c] = const Piece(color: PlayerColor.white);
          if (r > 4) board[r][c] = const Piece(color: PlayerColor.red);
        }
      }
    }
    return board;
  }
  
  void _calculateValidMoves() {
    if (_gameState == null) return;
    
    final moves = <Move>[];
    final captures = <Move>[];
    
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (_gameState!.mustCaptureFrom != null) {
          if (r != _gameState!.mustCaptureFrom!.row || 
              c != _gameState!.mustCaptureFrom!.col) continue;
        }
        
        final piece = _gameState!.board[r][c];
        if (piece == null || piece.color != _gameState!.turn) continue;
        
        final pieceMoves = _getPieceMoves(Position(r, c), piece);
        for (final move in pieceMoves) {
          if (move.isCapture) {
            captures.add(move);
          } else {
            moves.add(move);
          }
        }
      }
    }
    
    _gameState = _gameState!.copyWith(
      validMoves: captures.isNotEmpty ? captures : moves,
    );
  }
  
  List<Move> _getPieceMoves(Position pos, Piece piece) {
    final moves = <Move>[];
    final isKing = piece.isKing;
    final forward = piece.color == PlayerColor.red ? -1 : 1;
    final variant = _gameState!.variant;
    
    if (variant == GameVariant.american) {
      final moveDirs = isKing 
          ? [[-1, -1], [-1, 1], [1, -1], [1, 1]]
          : [[forward, -1], [forward, 1]];
      
      for (final dir in moveDirs) {
        final r = pos.row + dir[0];
        final c = pos.col + dir[1];
        if (_isValid(r, c) && _gameState!.board[r][c] == null) {
          moves.add(Move(from: pos, to: Position(r, c)));
        }
      }
      
      final captureDirs = isKing 
          ? [[-1, -1], [-1, 1], [1, -1], [1, 1]]
          : [[forward, -1], [forward, 1]];
      
      for (final dir in captureDirs) {
        final r1 = pos.row + dir[0];
        final c1 = pos.col + dir[1];
        final r2 = pos.row + dir[0] * 2;
        final c2 = pos.col + dir[1] * 2;
        
        if (_isValid(r2, c2) && _gameState!.board[r2][c2] == null) {
          final midPiece = _gameState!.board[r1][c1];
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
    } else {
      // Brazilian variant - men capture backwards, flying kings
      final moveDirs = [[forward, -1], [forward, 1]];
      final captureDirs = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
      
      if (!isKing) {
        for (final dir in moveDirs) {
          final r = pos.row + dir[0];
          final c = pos.col + dir[1];
          if (_isValid(r, c) && _gameState!.board[r][c] == null) {
            moves.add(Move(from: pos, to: Position(r, c)));
          }
        }
        
        for (final dir in captureDirs) {
          final r1 = pos.row + dir[0];
          final c1 = pos.col + dir[1];
          final r2 = pos.row + dir[0] * 2;
          final c2 = pos.col + dir[1] * 2;
          
          if (_isValid(r2, c2) && _gameState!.board[r2][c2] == null) {
            final midPiece = _gameState!.board[r1][c1];
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
      } else {
        // Flying king
        for (final dir in captureDirs) {
          int r = pos.row + dir[0];
          int c = pos.col + dir[1];
          Position? enemyPos;
          
          while (_isValid(r, c)) {
            final cell = _gameState!.board[r][c];
            if (cell == null) {
              if (enemyPos != null) {
                moves.add(Move(
                  from: pos, 
                  to: Position(r, c), 
                  isCapture: true,
                  capturedPos: enemyPos,
                ));
              } else {
                moves.add(Move(from: pos, to: Position(r, c)));
              }
            } else if (cell.color == piece.color) {
              break;
            } else {
              if (enemyPos != null) break;
              enemyPos = Position(r, c);
            }
            r += dir[0];
            c += dir[1];
          }
        }
      }
    }
    
    return moves;
  }
  
  bool _isValid(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;
  
  void selectSquare(Position pos, {Function(Move)? onOnlineMove}) {
    if (_gameState == null || _gameState!.winner != null || _isAiThinking) return;

    final piece = _gameState!.board[pos.row][pos.col];

    if (piece != null && piece.color == _gameState!.turn) {
      if (_gameState!.mustCaptureFrom != null) {
        if (pos == _gameState!.mustCaptureFrom) {
          _gameState = _gameState!.copyWith(selectedPos: pos);
          notifyListeners();
        }
        return;
      }
      _gameState = _gameState!.copyWith(selectedPos: pos);
      notifyListeners();
      return;
    }

    if (piece == null && _gameState!.selectedPos != null) {
      final move = _gameState!.validMoves.where((m) =>
        m.from == _gameState!.selectedPos && m.to == pos
      ).firstOrNull;

      if (move != null) {
        _executeMove(move);
        // Se for modo online, notificar o callback
        if (_gameState!.mode == GameMode.online && onOnlineMove != null) {
          onOnlineMove(move);
        }
      }
    }
  }
  
  void _executeMove(Move move) {
    if (_gameState == null) return;
    
    final newBoard = _gameState!.board.map((r) => r.toList()).toList();
    var piece = newBoard[move.from.row][move.from.col]!;
    
    newBoard[move.to.row][move.to.col] = piece;
    newBoard[move.from.row][move.from.col] = null;
    
    if (move.capturedPos != null) {
      newBoard[move.capturedPos!.row][move.capturedPos!.col] = null;
    }
    
    bool promoted = false;
    if (piece.type == PieceType.man) {
      if ((piece.color == PlayerColor.red && move.to.row == 0) ||
          (piece.color == PlayerColor.white && move.to.row == 7)) {
        newBoard[move.to.row][move.to.col] = piece.promote();
        promoted = true;
      }
    }
    
    final newHistory = [..._gameState!.history, move.toNotation()];
    
    PlayerColor nextTurn = _gameState!.turn;
    Position? mustCaptureFrom;
    
    if (move.isCapture && !promoted) {
      _gameState = _gameState!.copyWith(
        board: newBoard,
        history: newHistory,
        clearSelection: true,
      );
      _gameState = _gameState!.copyWith(mustCaptureFrom: move.to);
      _calculateValidMoves();
      
      final hasMoreCaptures = _gameState!.validMoves.any((m) => m.isCapture);
      if (hasMoreCaptures) {
        mustCaptureFrom = move.to;
      } else {
        nextTurn = _gameState!.turn == PlayerColor.red 
            ? PlayerColor.white 
            : PlayerColor.red;
      }
    } else {
      nextTurn = _gameState!.turn == PlayerColor.red 
          ? PlayerColor.white 
          : PlayerColor.red;
    }
    
    _gameState = _gameState!.copyWith(
      board: newBoard,
      turn: nextTurn,
      history: newHistory,
      clearSelection: true,
      mustCaptureFrom: mustCaptureFrom,
      clearMustCapture: mustCaptureFrom == null,
    );
    
    _calculateValidMoves();
    _checkWinner();
    notifyListeners();
    
    if (_gameState!.mode == GameMode.ai && 
        _gameState!.turn == PlayerColor.white &&
        _gameState!.winner == null) {
      _makeAiMove();
    }
  }
  
  void _checkWinner() {
    if (_gameState == null) return;
    
    int redCount = 0, whiteCount = 0;
    for (final row in _gameState!.board) {
      for (final piece in row) {
        if (piece?.color == PlayerColor.red) redCount++;
        if (piece?.color == PlayerColor.white) whiteCount++;
      }
    }
    
    if (redCount == 0) {
      _gameState = _gameState!.copyWith(winner: PlayerColor.white);
    } else if (whiteCount == 0) {
      _gameState = _gameState!.copyWith(winner: PlayerColor.red);
    } else if (_gameState!.validMoves.isEmpty) {
      _gameState = _gameState!.copyWith(
        winner: _gameState!.turn == PlayerColor.red 
            ? PlayerColor.white 
            : PlayerColor.red,
      );
    }
  }
  
  Future<void> _makeAiMove() async {
    if (_gameState == null || _gameState!.validMoves.isEmpty) return;
    
    _isAiThinking = true;
    notifyListeners();
    
    await Future.delayed(Duration(milliseconds: _gameState!.mustCaptureFrom != null ? 600 : 1000));
    
    // Simple AI: prefer captures, then random
    final captures = _gameState!.validMoves.where((m) => m.isCapture).toList();
    final Move move;
    
    if (captures.isNotEmpty) {
      captures.shuffle();
      move = captures.first;
      _aiExplanation = "Forced capture - taking the piece!";
    } else {
      final moves = _gameState!.validMoves.toList()..shuffle();
      move = moves.first;
      _aiExplanation = "Developing position...";
    }
    
    _isAiThinking = false;
    _executeMove(move);
  }
  
  void resign() {
    if (_gameState == null) return;
    _gameState = _gameState!.copyWith(
      winner: _gameState!.turn == PlayerColor.red 
          ? PlayerColor.white 
          : PlayerColor.red,
    );
    notifyListeners();
  }
  
  void resetGame() {
    _gameState = null;
    _aiExplanation = null;
    _onlineMatchId = null;
    _myPlayerId = null;
    notifyListeners();
  }
}
