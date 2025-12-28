class EloService {
  // Fator K baseado no número de partidas jogadas
  static int getKFactor(int gamesPlayed) {
    if (gamesPlayed < 30) return 40; // Novos jogadores
    if (gamesPlayed < 100) return 30; // Jogadores intermediários
    return 20; // Jogadores experientes
  }

  // Calcular probabilidade de vitória
  static double calculateExpectedScore(int ratingA, int ratingB) {
    return 1.0 / (1.0 + pow(10, (ratingB - ratingA) / 400.0));
  }

  // Calcular novo rating
  static Map<String, int> calculateNewRatings({
    required int player1Rating,
    required int player2Rating,
    required int player1GamesPlayed,
    required int player2GamesPlayed,
    required double player1Score, // 1.0 = vitória, 0.5 = empate, 0.0 = derrota
  }) {
    final k1 = getKFactor(player1GamesPlayed);
    final k2 = getKFactor(player2GamesPlayed);

    final expected1 = calculateExpectedScore(player1Rating, player2Rating);
    final expected2 = calculateExpectedScore(player2Rating, player1Rating);

    final change1 = (k1 * (player1Score - expected1)).round();
    final change2 = (k2 * ((1 - player1Score) - expected2)).round();

    return {
      'player1NewRating': max(100, player1Rating + change1),
      'player2NewRating': max(100, player2Rating + change2),
      'player1Change': change1,
      'player2Change': change2,
    };
  }

  // Calcular mudança de rating para vitória contra IA
  static int calculateAiRatingChange({
    required int playerRating,
    required int gamesPlayed,
    required bool won,
    required String aiDifficulty,
  }) {
    // Rating estimado da IA baseado na dificuldade
    final aiRating = {
      'easy': 800,
      'medium': 1200,
      'hard': 1600,
    }[aiDifficulty] ?? 1200;

    final k = getKFactor(gamesPlayed);
    final expected = calculateExpectedScore(playerRating, aiRating);
    final score = won ? 1.0 : 0.0;

    final change = (k * (score - expected)).round();
    return max(100, playerRating + change);
  }

  static double pow(num x, num exponent) {
    return x.toDouble().powDouble(exponent.toDouble());
  }
}

extension on double {
  double powDouble(double exponent) {
    if (exponent == 0) return 1.0;
    if (exponent == 1) return this;

    double result = 1.0;
    double base = this;
    int exp = exponent.abs().toInt();

    for (int i = 0; i < exp; i++) {
      result *= base;
    }

    if (exponent < 0) {
      return 1.0 / result;
    }

    return result;
  }
}

// Função auxiliar max
int max(int a, int b) => a > b ? a : b;
