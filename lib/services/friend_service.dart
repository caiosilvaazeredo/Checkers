import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';

class FriendService extends ChangeNotifier {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  
  List<AppUser> _friends = [];
  List<AppUser> _friendRequests = [];
  List<AppUser> _searchResults = [];
  bool _isLoading = false;
  
  List<AppUser> get friends => _friends;
  List<AppUser> get friendRequests => _friendRequests;
  List<AppUser> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  
  Future<void> loadFriends(String currentUserId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _db.ref('users/$currentUserId').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final friendIds = List<String>.from(data['friends'] ?? []);
        final requestIds = List<String>.from(data['friendRequests'] ?? []);
        
        _friends = await _loadUsers(friendIds);
        _friendRequests = await _loadUsers(requestIds);
      }
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<List<AppUser>> _loadUsers(List<String> userIds) async {
    final users = <AppUser>[];
    for (final id in userIds) {
      final snapshot = await _db.ref('users/$id').get();
      if (snapshot.exists) {
        users.add(AppUser.fromMap(Map<String, dynamic>.from(snapshot.value as Map)));
      }
    }
    return users;
  }
  
  Future<void> searchUsers(String query, String currentUserId) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final snapshot = await _db.ref('users')
          .orderByChild('username')
          .startAt(query)
          .endAt('$query\uf8ff')
          .limitToFirst(10)
          .get();
      
      if (snapshot.exists) {
        _searchResults = [];
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          if (entry.key != currentUserId) {
            _searchResults.add(AppUser.fromMap(Map<String, dynamic>.from(entry.value)));
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching users: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    try {
      final snapshot = await _db.ref('users/$toUserId/friendRequests').get();
      final requests = snapshot.exists 
          ? List<String>.from(snapshot.value as List) 
          : <String>[];
      
      if (!requests.contains(fromUserId)) {
        requests.add(fromUserId);
        await _db.ref('users/$toUserId/friendRequests').set(requests);
      }
    } catch (e) {
      debugPrint('Error sending friend request: $e');
    }
  }
  
  Future<void> acceptFriendRequest(String currentUserId, String friendId) async {
    try {
      // Add to both users' friends lists
      await _addFriend(currentUserId, friendId);
      await _addFriend(friendId, currentUserId);
      
      // Remove from requests
      await _removeRequest(currentUserId, friendId);
      
      await loadFriends(currentUserId);
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
    }
  }
  
  Future<void> declineFriendRequest(String currentUserId, String friendId) async {
    try {
      await _removeRequest(currentUserId, friendId);
      await loadFriends(currentUserId);
    } catch (e) {
      debugPrint('Error declining friend request: $e');
    }
  }
  
  Future<void> _addFriend(String userId, String friendId) async {
    final snapshot = await _db.ref('users/$userId/friends').get();
    final friends = snapshot.exists 
        ? List<String>.from(snapshot.value as List) 
        : <String>[];
    
    if (!friends.contains(friendId)) {
      friends.add(friendId);
      await _db.ref('users/$userId/friends').set(friends);
    }
  }
  
  Future<void> _removeRequest(String userId, String fromId) async {
    final snapshot = await _db.ref('users/$userId/friendRequests').get();
    if (snapshot.exists) {
      final requests = List<String>.from(snapshot.value as List);
      requests.remove(fromId);
      await _db.ref('users/$userId/friendRequests').set(requests);
    }
  }
  
  Future<void> removeFriend(String currentUserId, String friendId) async {
    try {
      await _removeFriendFromList(currentUserId, friendId);
      await _removeFriendFromList(friendId, currentUserId);
      await loadFriends(currentUserId);
    } catch (e) {
      debugPrint('Error removing friend: $e');
    }
  }
  
  Future<void> _removeFriendFromList(String userId, String friendId) async {
    final snapshot = await _db.ref('users/$userId/friends').get();
    if (snapshot.exists) {
      final friends = List<String>.from(snapshot.value as List);
      friends.remove(friendId);
      await _db.ref('users/$userId/friends').set(friends);
    }
  }
}
