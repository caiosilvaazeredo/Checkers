import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class LeaderboardService extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  List<AppUser> _leaderboard = [];
  bool _isLoading = false;
  
  List<AppUser> get leaderboard => _leaderboard;
  bool get isLoading => _isLoading;
  
  Future<void> loadLeaderboard() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _db.ref('users')
          .orderByChild('rating')
          .limitToLast(50)
          .get();
      
      if (snapshot.exists) {
        _leaderboard = [];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          _leaderboard.add(AppUser.fromMap(Map<String, dynamic>.from(entry.value)));
        }
        _leaderboard.sort((a, b) => b.rating.compareTo(a.rating));
      }
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
}
