import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/sneaker.dart';

/// Per-user persistence for the signed-in user's sneaker collection.
///
/// **History.** The original app stored each user's collection in Cloud
/// Firestore, partitioned by Firebase user id. With the backend retired,
/// this service preserves the per-user model locally — each user's
/// collection lives in its own Hive box, named by user id. The collection
/// API mirrors what the Firestore-backed version exposed, so the rest of
/// the app calls the same methods either way. Lines marked `// LIVE:` are
/// where the original talked to Firestore.
class StorageService {
  static const String _metaBoxName = 'sneakerbro_meta';
  static String _userBoxName(String userId) =>
      'sneakerbro_collection_$userId';

  late Box<String> _metaBox;
  Box<String>? _userBox;
  String? _activeUserId;

  /// Must be called once at startup, before any user has signed in.
  Future<void> init() async {
    await Hive.initFlutter();
    _metaBox = await Hive.openBox<String>(_metaBoxName);
  }

  /// Opens (or switches to) the collection box for [userId]. Called on
  /// sign-in by [CollectionModel] when it hears the auth state change.
  Future<void> useUser(String userId) async {
    if (_activeUserId == userId && _userBox != null) return;
    await _userBox?.close();
    _userBox = await Hive.openBox<String>(_userBoxName(userId));
    _activeUserId = userId;
  }

  /// Closes the currently-open user box. Called on sign-out.
  Future<void> clearUser() async {
    await _userBox?.close();
    _userBox = null;
    _activeUserId = null;
  }

  /// True when no user is signed in.
  bool get hasNoUser => _userBox == null;

  Box<String> get _box {
    final box = _userBox;
    if (box == null) {
      throw StateError('No user is signed in - call useUser() first.');
    }
    return box;
  }

  /// True when the active user's collection has no sneakers yet.
  bool get isEmpty => _box.isEmpty;

  /// The seed version last written for the active user. The bundled sample
  /// data only applies to the demo account; other accounts start empty.
  String? get seedVersion =>
      _metaBox.get('seedVersion:${_activeUserId ?? ""}');

  Future<void> setSeedVersion(String version) async {
    await _metaBox.put('seedVersion:${_activeUserId ?? ""}', version);
  }

  /// Removes every sneaker from the active user's collection.
  Future<void> clearCollection() async {
    await _box.clear();
  }

  List<Sneaker> loadAll() {
    final result = <Sneaker>[];
    for (final value in _box.values) {
      try {
        final map = json.decode(value) as Map<String, dynamic>;
        result.add(Sneaker.fromMap(map));
      } catch (_) {
        // skip a corrupt record rather than failing the whole load
      }
    }
    return result;
  }

  Future<void> save(Sneaker sneaker) async {
    // LIVE: Firestore.doc('/users/$_activeUserId/sneakers/${sneaker.id}').set(...)
    await _box.put(sneaker.id, json.encode(sneaker.toMap()));
  }

  Future<void> saveAll(List<Sneaker> sneakers) async {
    final entries = <String, String>{
      for (final s in sneakers) s.id: json.encode(s.toMap()),
    };
    await _box.putAll(entries);
  }

  Future<void> delete(String id) async {
    // LIVE: Firestore.doc('/users/$_activeUserId/sneakers/$id').delete()
    await _box.delete(id);
  }
}
