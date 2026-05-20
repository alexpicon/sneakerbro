import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user.dart';

/// Authentication for SneakerBro.
///
/// **History.** The original app authenticated users with Firebase Auth,
/// and each user's collection lived in Cloud Firestore. The backend was
/// retired when the project went quiet in 2022.
///
/// This service preserves the same API the rest of the app was written
/// against — sign in, sign up, sign out, a current-user notifier — but
/// persists locally so the archive still runs without a backend. Lines
/// marked `// LIVE:` mark where the original made a network call to
/// Firebase.
class AuthService extends ChangeNotifier {
  static const String _usersBoxName = 'sneakerbro_users';
  static const String _sessionKey = '__session_user_id__';
  static const String _userPrefix = 'user:';
  static const String _passwordPrefix = 'password:';

  late Box<String> _box;
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  /// Must be called once at startup, before runApp.
  Future<void> init() async {
    _box = await Hive.openBox<String>(_usersBoxName);
    final sessionId = _box.get(_sessionKey);
    if (sessionId != null) {
      _currentUser = _loadUserById(sessionId);
    }
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    // LIVE: FirebaseAuth.instance.signInWithEmailAndPassword(...)
    final normalized = email.trim().toLowerCase();
    final user = _findByEmail(normalized);
    if (user == null) {
      throw const AuthException('No account found with that email.');
    }
    if (_passwordOf(user.id) != password) {
      throw const AuthException('Wrong password.');
    }
    await _box.put(_sessionKey, user.id);
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // LIVE: FirebaseAuth.instance.createUserWithEmailAndPassword(...)
    final cleanName = name.trim();
    final normalized = email.trim().toLowerCase();
    if (cleanName.isEmpty) {
      throw const AuthException('Please enter a name.');
    }
    if (!normalized.contains('@')) {
      throw const AuthException('Please enter a valid email.');
    }
    if (password.length < 4) {
      throw const AuthException('Password is too short.');
    }
    if (_findByEmail(normalized) != null) {
      throw const AuthException('An account with that email already exists.');
    }
    final user = AppUser(
      id: 'u_${DateTime.now().microsecondsSinceEpoch}',
      name: cleanName,
      email: normalized,
      createdAt: DateTime.now(),
    );
    await _saveUser(user, password);
    await _box.put(_sessionKey, user.id);
    _currentUser = user;
    notifyListeners();
    return user;
  }

  Future<void> signOut() async {
    // LIVE: FirebaseAuth.instance.signOut()
    await _box.delete(_sessionKey);
    _currentUser = null;
    notifyListeners();
  }

  /// Seeds the canonical demo account on first launch, so the archive opens
  /// to a populated collection instead of an empty sign-up form.
  Future<AppUser> ensureDemoUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final existing = _findByEmail(normalized);
    if (existing != null) return existing;
    final user = AppUser(
      id: 'u_demo_alex',
      name: name,
      email: normalized,
      createdAt: DateTime.now(),
    );
    await _saveUser(user, password);
    return user;
  }

  // ---- private ----------------------------------------------------------

  AppUser? _findByEmail(String email) {
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith(_userPrefix)) continue;
      final raw = _box.get(key);
      if (raw == null) continue;
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        if ((map['email'] as String?)?.toLowerCase() == email) {
          return AppUser.fromMap(map);
        }
      } catch (_) {
        // skip a corrupt record
      }
    }
    return null;
  }

  AppUser? _loadUserById(String id) {
    final raw = _box.get('$_userPrefix$id');
    if (raw == null) return null;
    try {
      return AppUser.fromMap(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String? _passwordOf(String id) => _box.get('$_passwordPrefix$id');

  Future<void> _saveUser(AppUser user, String password) async {
    await _box.put('$_userPrefix${user.id}', json.encode(user.toMap()));
    // The original never stored passwords client-side — Firebase Auth held
    // credentials in the cloud. The stub stores them locally only because
    // there's no remote server to validate against. Not real security.
    await _box.put('$_passwordPrefix${user.id}', password);
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
