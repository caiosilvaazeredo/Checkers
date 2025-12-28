import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  AppUser? _currentUser;
  bool _isLoading = true;
  String? _error;
  
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }
  
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _loadUserData(firebaseUser.uid);
    } else {
      _currentUser = null;
    }
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _loadUserData(String uid) async {
    try {
      final snapshot = await _db.ref('users/$uid').get();
      if (snapshot.exists) {
        _currentUser = AppUser.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      }
    } catch (e) {
      _error = e.toString();
    }
  }
  
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> registerWithEmail(String email, String password, String username) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        final user = AppUser(
          uid: credential.user!.uid,
          email: email,
          username: username,
        );
        await _db.ref('users/${user.uid}').set(user.toMap());
        _currentUser = user;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        final snapshot = await _db.ref('users/${userCredential.user!.uid}').get();
        if (!snapshot.exists) {
          final user = AppUser(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            username: googleUser.displayName ?? 'Player',
          );
          await _db.ref('users/${user.uid}').set(user.toMap());
        }
      }
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> sendSignInLink(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://checkers-27bb3.firebaseapp.com/finishSignUp?email=$email',
        handleCodeInApp: true,
        androidPackageName: 'com.example.master_checkers',
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.example.masterCheckers',
      );
      await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: actionCodeSettings);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }
  
  Future<void> updateUserStats({int? rating, int? wins, int? losses, int? draws}) async {
    if (_currentUser == null) return;
    
    final updates = <String, dynamic>{};
    if (rating != null) updates['rating'] = rating;
    if (wins != null) updates['wins'] = _currentUser!.wins + 1;
    if (losses != null) updates['losses'] = _currentUser!.losses + 1;
    if (draws != null) updates['draws'] = _currentUser!.draws + 1;
    updates['gamesPlayed'] = _currentUser!.gamesPlayed + 1;
    
    await _db.ref('users/${_currentUser!.uid}').update(updates);
    await _loadUserData(_currentUser!.uid);
    notifyListeners();
  }
  
  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'Email is already registered.';
      case 'weak-password': return 'Password is too weak.';
      case 'invalid-email': return 'Invalid email address.';
      default: return 'An error occurred. Please try again.';
    }
  }
}
