class AppUser {
  final String uid;
  final String email;
  final String username;
  final int rating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final DateTime createdAt;
  final List<String> friends;
  final List<String> friendRequests;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    this.rating = 1200,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    DateTime? createdAt,
    this.friends = const [],
    this.friendRequests = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  double get winRate => gamesPlayed > 0 ? (wins / gamesPlayed) * 100 : 0;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'username': username,
    'rating': rating,
    'gamesPlayed': gamesPlayed,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'createdAt': createdAt.toIso8601String(),
    'friends': friends,
    'friendRequests': friendRequests,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    uid: map['uid'] ?? '',
    email: map['email'] ?? '',
    username: map['username'] ?? 'Player',
    rating: map['rating'] ?? 1200,
    gamesPlayed: map['gamesPlayed'] ?? 0,
    wins: map['wins'] ?? 0,
    losses: map['losses'] ?? 0,
    draws: map['draws'] ?? 0,
    createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    friends: List<String>.from(map['friends'] ?? []),
    friendRequests: List<String>.from(map['friendRequests'] ?? []),
  );

  AppUser copyWith({
    String? username,
    int? rating,
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? draws,
    List<String>? friends,
    List<String>? friendRequests,
  }) => AppUser(
    uid: uid,
    email: email,
    username: username ?? this.username,
    rating: rating ?? this.rating,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    wins: wins ?? this.wins,
    losses: losses ?? this.losses,
    draws: draws ?? this.draws,
    createdAt: createdAt,
    friends: friends ?? this.friends,
    friendRequests: friendRequests ?? this.friendRequests,
  );
}
