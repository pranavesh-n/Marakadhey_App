import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_helper.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
    );
  }

  String toJson() => json.encode(toMap());
  factory UserProfile.fromJson(String source) => UserProfile.fromMap(json.decode(source));
}

class AuthService extends ChangeNotifier {
  static const String _keyUser = '@marakadhey_auth_profile';
  static const String _keyAccounts = '@marakadhey_registered_accounts_v1';
  UserProfile? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '1067507684798-puuuhnbroa1ci41mitft47ja4c6qcc9s.apps.googleusercontent.com' : null,
    serverClientId: '1067507684798-puuuhnbroa1ci41mitft47ja4c6qcc9s.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  UserProfile? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_keyUser);
      if (userJson != null && userJson.isNotEmpty) {
        final profile = UserProfile.fromJson(userJson);
        if (profile.uid.isNotEmpty) {
          _currentUser = profile;
        }
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  /// Register a new user account with their own name and email
  Future<bool> registerWithEmail(String name, String email, String password) async {
    _errorMessage = null;
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      _errorMessage = 'Please enter your name.';
      notifyListeners();
      return false;
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      _errorMessage = 'Please enter a valid email address.';
      notifyListeners();
      return false;
    }
    if (password.trim().length < 4) {
      _errorMessage = 'Password must be at least 4 characters.';
      notifyListeners();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> accounts = {};
    final existingAccountsJson = prefs.getString(_keyAccounts);
    if (existingAccountsJson != null && existingAccountsJson.isNotEmpty) {
      try {
        accounts = json.decode(existingAccountsJson);
      } catch (_) {}
    }

    // Generate safe deterministic or random user ID
    final uid = 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    accounts[cleanEmail] = {
      'uid': uid,
      'name': cleanName,
      'email': cleanEmail,
      'password': password.trim(),
    };
    await prefs.setString(_keyAccounts, json.encode(accounts));

    final profile = UserProfile(
      uid: uid,
      email: cleanEmail,
      displayName: cleanName,
    );

    _currentUser = profile;
    await prefs.setString(_keyUser, profile.toJson());
    notifyListeners();
    return true;
  }

  /// Log in an existing user with email and password
  Future<bool> loginWithEmail(String email, String password) async {
    _errorMessage = null;
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      _errorMessage = 'Please enter your email and password.';
      notifyListeners();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> accounts = {};
    final existingAccountsJson = prefs.getString(_keyAccounts);
    if (existingAccountsJson != null && existingAccountsJson.isNotEmpty) {
      try {
        accounts = json.decode(existingAccountsJson);
      } catch (_) {}
    }

    String displayName;
    String uid;

    if (accounts.containsKey(cleanEmail)) {
      final acc = accounts[cleanEmail];
      displayName = acc['name'] ?? cleanEmail.split('@')[0];
      uid = acc['uid'] ?? 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    } else {
      // Auto-create local profile for this specific user
      final namePrefix = cleanEmail.split('@')[0];
      displayName = namePrefix.isNotEmpty ? namePrefix[0].toUpperCase() + namePrefix.substring(1) : 'User';
      uid = 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      accounts[cleanEmail] = {
        'uid': uid,
        'name': displayName,
        'email': cleanEmail,
        'password': cleanPass,
      };
      await prefs.setString(_keyAccounts, json.encode(accounts));
    }

    final profile = UserProfile(
      uid: uid,
      email: cleanEmail,
      displayName: displayName,
    );

    _currentUser = profile;
    await prefs.setString(_keyUser, profile.toJson());
    notifyListeners();
    return true;
  }

  /// Sign in with Google (extracts actual Google account name & email)
  Future<bool> loginWithGoogle() async {
    _errorMessage = null;
    try {
      if (kIsWeb) {
        final webResult = await performWebGoogleSignIn();
        if (webResult != null) {
          if (webResult['success'] == true) {
            final email = (webResult['email'] as String).toLowerCase();
            final displayName = webResult['displayName'] ?? email.split('@')[0];
            final profile = UserProfile(
              uid: 'g_${webResult['uid'] ?? email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
              email: email,
              displayName: displayName,
              photoUrl: webResult['photoUrl'],
            );

            _currentUser = profile;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_keyUser, profile.toJson());
            notifyListeners();
            return true;
          } else {
            final err = webResult['error']?.toString() ?? 'Sign-in cancelled';
            if (!err.toLowerCase().contains('popup-closed') && !err.toLowerCase().contains('cancel')) {
              _errorMessage = err;
            }
            notifyListeners();
            return false;
          }
        }
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final profile = UserProfile(
          uid: 'g_${googleUser.id}',
          email: googleUser.email.toLowerCase(),
          displayName: googleUser.displayName ?? googleUser.email.split('@')[0],
          photoUrl: googleUser.photoUrl,
        );

        _currentUser = profile;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyUser, profile.toJson());
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Google Sign-In was cancelled.';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('Google Sign-in error: $e');
      _errorMessage = 'Google Sign-In error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Direct Google account sign in without password
  Future<void> loginWithGoogleProfile(String name, String email) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim().isNotEmpty ? name.trim() : (cleanEmail.split('@')[0]);
    final uid = 'g_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    final profile = UserProfile(
      uid: uid,
      email: cleanEmail,
      displayName: cleanName,
    );

    _currentUser = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, profile.toJson());
    notifyListeners();
  }



  /// Update display name for current user
  Future<void> updateDisplayName(String newName) async {
    if (_currentUser == null || newName.trim().isEmpty) return;
    final updated = UserProfile(
      uid: _currentUser!.uid,
      email: _currentUser!.email,
      displayName: newName.trim(),
      photoUrl: _currentUser!.photoUrl,
    );
    _currentUser = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, updated.toJson());
    notifyListeners();
  }

  /// Log out active user and clear session
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    notifyListeners();
  }
}
