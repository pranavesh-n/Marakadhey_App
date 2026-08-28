import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_auth_helper.dart';
import 'firestore_auth_service.dart';
import 'supabase_service.dart';

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

enum AuthStatus {
  success,
  accountNotFound,
  wrongPassword,
  emailAlreadyInUse,
  invalidEmail,
  weakPassword,
  missingFields,
  cancelled,
  error,
}

class AuthResult {
  final AuthStatus status;
  final String message;
  final UserProfile? user;

  const AuthResult({
    required this.status,
    required this.message,
    this.user,
  });

  bool get isSuccess => status == AuthStatus.success;
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

  static bool isValidEmail(String email) {
    final clean = email.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(clean);
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
  Future<AuthResult> registerWithEmail(String name, String email, String password) async {
    _errorMessage = null;
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = name.trim();
    final cleanPass = password.trim();

    if (cleanName.isEmpty) {
      const msg = 'Please enter your full name.';
      _errorMessage = msg;
      notifyListeners();
      return const AuthResult(status: AuthStatus.missingFields, message: msg);
    }
    if (cleanEmail.isEmpty || !isValidEmail(cleanEmail)) {
      const msg = 'Please enter a valid email address (e.g. you@outlook.com or you@zoho.com).';
      _errorMessage = msg;
      notifyListeners();
      return const AuthResult(status: AuthStatus.invalidEmail, message: msg);
    }
    if (cleanPass.length < 6) {
      const msg = 'Password must be at least 6 characters long.';
      _errorMessage = msg;
      notifyListeners();
      return const AuthResult(status: AuthStatus.weakPassword, message: msg);
    }

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> accounts = {};
    final existingAccountsJson = prefs.getString(_keyAccounts);
    if (existingAccountsJson != null && existingAccountsJson.isNotEmpty) {
      try {
        accounts = json.decode(existingAccountsJson);
      } catch (_) {}
    }

    // Check if account already exists
    if (accounts.containsKey(cleanEmail)) {
      final msg = 'An account already exists with $cleanEmail. Please sign in instead.';
      _errorMessage = msg;
      notifyListeners();
      return AuthResult(status: AuthStatus.emailAlreadyInUse, message: msg);
    }

    // Generate safe deterministic user ID
    final uid = 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    accounts[cleanEmail] = {
      'uid': uid,
      'name': cleanName,
      'email': cleanEmail,
      'password': cleanPass,
      'createdAt': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_keyAccounts, json.encode(accounts));

    // Store account credentials into Firebase Firestore DB
    await FirestoreAuthService.saveAccount(
      uid: uid,
      name: cleanName,
      email: cleanEmail,
      password: cleanPass,
    );

    // Sync to Supabase Database if configured
    if (SupabaseService.isConfigured) {
      await SupabaseService.insertAccount(
        uid: uid,
        name: cleanName,
        email: cleanEmail,
        password: cleanPass,
      );
    }

    final profile = UserProfile(
      uid: uid,
      email: cleanEmail,
      displayName: cleanName,
    );

    _currentUser = profile;
    await prefs.setString(_keyUser, profile.toJson());
    notifyListeners();
    return AuthResult(status: AuthStatus.success, message: 'Account created successfully', user: profile);
  }

  /// Log in an existing user with email and password
  Future<AuthResult> loginWithEmail(String email, String password) async {
    _errorMessage = null;
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      const msg = 'Please enter both email and password.';
      _errorMessage = msg;
      notifyListeners();
      return const AuthResult(status: AuthStatus.missingFields, message: msg);
    }

    if (!isValidEmail(cleanEmail)) {
      const msg = 'Please enter a valid email address (e.g. you@outlook.com or you@zoho.com).';
      _errorMessage = msg;
      notifyListeners();
      return const AuthResult(status: AuthStatus.invalidEmail, message: msg);
    }

    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> accounts = {};
    final existingAccountsJson = prefs.getString(_keyAccounts);
    if (existingAccountsJson != null && existingAccountsJson.isNotEmpty) {
      try {
        accounts = json.decode(existingAccountsJson);
      } catch (_) {}
    }

    // If not found in local cache, check Firebase Firestore DB
    if (!accounts.containsKey(cleanEmail)) {
      final firestoreAcc = await FirestoreAuthService.findAccount(cleanEmail);
      if (firestoreAcc != null) {
        accounts[cleanEmail] = {
          'uid': firestoreAcc['uid'] ?? 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
          'name': firestoreAcc['name'] ?? cleanEmail.split('@')[0],
          'email': cleanEmail,
          'password': firestoreAcc['password'] ?? '',
          'photoUrl': firestoreAcc['photoUrl'],
        };
        await prefs.setString(_keyAccounts, json.encode(accounts));
      }
    }

    // Check Supabase if configured as secondary
    if (!accounts.containsKey(cleanEmail) && SupabaseService.isConfigured) {
      final remoteAcc = await SupabaseService.findAccount(cleanEmail);
      if (remoteAcc != null) {
        accounts[cleanEmail] = {
          'uid': remoteAcc['uid'] ?? 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
          'name': remoteAcc['name'] ?? cleanEmail.split('@')[0],
          'email': cleanEmail,
          'password': remoteAcc['password'] ?? '',
        };
        await prefs.setString(_keyAccounts, json.encode(accounts));
      }
    }

    // Strictly verify if account exists
    if (!accounts.containsKey(cleanEmail)) {
      final msg = 'No account found for $cleanEmail. Kindly create a new account.';
      _errorMessage = msg;
      notifyListeners();
      return AuthResult(status: AuthStatus.accountNotFound, message: msg);
    }

    final acc = accounts[cleanEmail];
    final storedPass = acc['password']?.toString() ?? '';

    // Strictly verify password
    if (storedPass != cleanPass) {
      const msg = 'Incorrect password. Please try again.';
      _errorMessage = msg;
      notifyListeners();
      return const AuthResult(status: AuthStatus.wrongPassword, message: msg);
    }

    final displayName = acc['name'] ?? cleanEmail.split('@')[0];
    final uid = acc['uid'] ?? 'usr_${cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

    final profile = UserProfile(
      uid: uid,
      email: cleanEmail,
      displayName: displayName,
      photoUrl: acc['photoUrl'],
    );

    _currentUser = profile;
    await prefs.setString(_keyUser, profile.toJson());
    notifyListeners();
    return AuthResult(status: AuthStatus.success, message: 'Signed in successfully', user: profile);
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
