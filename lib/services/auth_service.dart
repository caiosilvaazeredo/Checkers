import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

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
    debugPrint('🔐 Auth state changed: ${firebaseUser?.email ?? "null"}');
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
      debugPrint('📂 Loading user data for: $uid');
      final snapshot = await _db.ref('users/$uid').get();
      if (snapshot.exists) {
        _currentUser =
            AppUser.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
        debugPrint('✅ User data loaded: ${_currentUser?.username}');
      } else {
        debugPrint('⚠️ No user data found in database for: $uid');
      }
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
      _error = e.toString();
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      debugPrint('🔑 Attempting email sign in: $email');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Sign in successful: ${credential.user?.uid}');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error during sign in: $e');
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithEmail(
      String email, String password, String username) async {
    try {
      debugPrint('📝 Attempting registration: $email, username: $username');
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User created in Auth: ${credential.user?.uid}');

      if (credential.user != null) {
        final user = AppUser(
          uid: credential.user!.uid,
          email: email,
          username: username,
        );

        debugPrint('💾 Saving user to database...');
        await _db.ref('users/${user.uid}').set(user.toMap());
        debugPrint('✅ User saved to database');

        _currentUser = user;
      }
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      _error = _getErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('❌ Unexpected error during registration: $e');
      _error = 'An unexpected error occurred: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('🔵 Attempting Google Sign In...');
      _isLoading = true;
      _error = null;
      notifyListeners();

      UserCredential userCredential;

      if (kIsWeb) {
        // Para Web: usar signInWithPopup diretamente com Firebase
        debugPrint('🌐 Using Web flow (signInWithPopup)');
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        userCredential = await _auth.signInWithPopup(googleProvider);
        debugPrint('✅ Web Google Sign In successful');
      } else {
        // Para Mobile: usar google_sign_in package
        debugPrint('📱 Using Mobile flow (GoogleSignIn)');
        final googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('⚠️ Google Sign In cancelled by user');
          _isLoading = false;
          notifyListeners();
          return false;
        }

        debugPrint('✅ Google user obtained: ${googleUser.email}');

        final googleAuth = await googleUser.authentication;
        debugPrint(
            '🔑 Got Google Auth - idToken: ${googleAuth.idToken != null}, accessToken: ${googleAuth.accessToken != null}');

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      debugPrint('✅ Firebase credential obtained: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        final snapshot = await _db.ref('users/${firebaseUser.uid}').get();

        if (!snapshot.exists) {
          debugPrint('📝 Creating new user in database...');
          final user = AppUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            username: firebaseUser.displayName ?? 'Player',
          );
          await _db.ref('users/${user.uid}').set(user.toMap());
          debugPrint('✅ New user created in database');
        } else {
          debugPrint('✅ User already exists in database');
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Google Sign In Error: $e');
      _error = 'Google Sign In failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('📧 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Password reset error: ${e.code}');
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendSignInLink(String email) async {
    try {
      debugPrint('🔗 Sending sign-in link to: $email');
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://checkers-27bb3.firebaseapp.com/finishSignUp?email=$email',
        handleCodeInApp: true,
        androidPackageName: 'com.example.master_checkers',
        androidInstallApp: true,
        androidMinimumVersion: '21',
        iOSBundleId: 'com.example.masterCheckers',
      );
      await _auth.sendSignInLinkToEmail(
          email: email, actionCodeSettings: actionCodeSettings);
      debugPrint('✅ Sign-in link sent');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending sign-in link: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    debugPrint('🚪 Signing out...');
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ Google sign out error (ignorable): $e');
    }
    await _auth.signOut();
    _currentUser = null;
    debugPrint('✅ Signed out');
    notifyListeners();
  }

  Future<void> updateUserStats(
      {int? rating, int? wins, int? losses, int? draws}) async {
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
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email is already registered.';
      case 'weak-password':
        return 'Password is too weak (min 6 characters).';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred ($code). Please try again.';
    }
  }
}
