import 'package:flutter/foundation.dart';

import '../models/sneaker.dart';
import '../services/asset_loader.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Owns the signed-in user's sneakers - both the collection and the wishlist
/// - and is the single source of truth the screens listen to.
///
/// **History.** The original app loaded each user's collection from Cloud
/// Firestore on sign-in and wrote changes straight back. This model
/// preserves that lifecycle: it listens to [AuthService], opens the right
/// user's storage on sign-in, and clears state on sign-out.
class CollectionModel extends ChangeNotifier {
  CollectionModel(this._storage, this._auth);

  final StorageService _storage;
  final AuthService _auth;
  List<Sneaker> _sneakers = [];
  bool _ready = false;

  /// Demo account id — the only user whose collection ships with the
  /// bundled sample data. Sign-ups start with an empty collection.
  static const String _demoUserId = 'u_demo_alex';

  /// Identifies the current bundled sample data. Bump this whenever
  /// `assets/data/sample_sneakers.json` changes so the demo account picks
  /// up the new collection on next launch.
  static const String _seedVersion = '2026-05-personal-collection-v18';

  /// Whether the model has loaded data for the current user yet.
  bool get isReady => _ready;

  /// Wires the model to the auth service. Listens for sign-in / sign-out
  /// and reloads from the matching user's box.
  Future<void> bind() async {
    _auth.addListener(_handleAuthChange);
    await _handleAuthChange();
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChange);
    super.dispose();
  }

  Future<void> _handleAuthChange() async {
    final user = _auth.currentUser;
    if (user == null) {
      await _storage.clearUser();
      _sneakers = [];
      _ready = false;
      notifyListeners();
      return;
    }
    await _storage.useUser(user.id);
    if (user.id == _demoUserId) {
      // The demo account is the only one that ships with a bundled
      // collection. A real sign-up starts empty - which is what the
      // original behaviour was on first launch before any data synced.
      if (_storage.isEmpty || _storage.seedVersion != _seedVersion) {
        await _reseed();
        await _storage.setSeedVersion(_seedVersion);
      }
    }
    _sneakers = _storage.loadAll();
    _sortByName();
    _ready = true;
    notifyListeners();
  }

  /// Seeds, or refreshes, the demo account's bundled collection from JSON.
  /// Pairs the user added themselves are not part of the seed and are kept
  /// across the refresh.
  Future<void> _reseed() async {
    final raw =
        await AssetLoader.loadObjects('assets/data/sample_sneakers.json');
    final seeded = raw.map(Sneaker.fromMap).toList();
    if (seeded.isEmpty) return;
    final seedIds = seeded.map((s) => s.id).toSet();
    final userAdded =
        _storage.loadAll().where((s) => !seedIds.contains(s.id)).toList();
    await _storage.clearCollection();
    await _storage.saveAll([...seeded, ...userAdded]);
  }

  void _sortByName() {
    _sneakers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  // ---- read access -------------------------------------------------------

  /// Every sneaker the signed-in user has, owned and wishlisted.
  List<Sneaker> get all => List.unmodifiable(_sneakers);

  /// Pairs the user actually owns.
  List<Sneaker> get owned =>
      _sneakers.where((s) => !s.isWishlist).toList(growable: false);

  /// Pairs the user wants but does not own yet.
  List<Sneaker> get wishlist =>
      _sneakers.where((s) => s.isWishlist).toList(growable: false);

  Sneaker? byId(String id) {
    for (final sneaker in _sneakers) {
      if (sneaker.id == id) return sneaker;
    }
    return null;
  }

  // ---- mutations ---------------------------------------------------------

  /// Inserts a new sneaker or replaces an existing one with the same id.
  Future<void> upsert(Sneaker sneaker) async {
    final index = _sneakers.indexWhere((s) => s.id == sneaker.id);
    if (index >= 0) {
      _sneakers[index] = sneaker;
    } else {
      _sneakers.add(sneaker);
    }
    _sortByName();
    await _storage.save(sneaker);
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _sneakers.removeWhere((s) => s.id == id);
    await _storage.delete(id);
    notifyListeners();
  }

  /// Records wear for a pair: adds [wears] to the wear count and [steps] to
  /// the lifetime step total. This is the manual usage tracking.
  Future<void> logWear(String id, {int wears = 1, int steps = 0}) async {
    final sneaker = byId(id);
    if (sneaker == null) return;
    await upsert(sneaker.copyWith(
      wearCount: sneaker.wearCount + wears,
      totalSteps: sneaker.totalSteps + steps,
    ));
  }

  /// Moves a wishlist entry into the owned collection.
  Future<void> moveToCollection(String id) async {
    final sneaker = byId(id);
    if (sneaker == null || !sneaker.isWishlist) return;
    await upsert(sneaker.copyWith(isWishlist: false));
  }

  // ---- analytics ---------------------------------------------------------

  int get ownedCount => owned.length;

  int get wishlistCount => wishlist.length;

  /// Sum of the estimated value of every owned pair.
  double get totalEstimatedValue =>
      owned.fold(0, (sum, s) => sum + s.estimatedValue);

  /// Sum of what was paid for every owned pair.
  double get totalSpent => owned.fold(0, (sum, s) => sum + s.purchasePrice);

  /// Total value gained or lost across the owned collection.
  double get totalValueChange => totalEstimatedValue - totalSpent;

  int get totalSteps => owned.fold(0, (sum, s) => sum + s.totalSteps);

  int get totalWears => owned.fold(0, (sum, s) => sum + s.wearCount);

  /// Owned collection market value grouped by brand, largest first.
  Map<String, double> get valueByBrand {
    final totals = <String, double>{};
    for (final s in owned) {
      final brand = s.brand.isEmpty ? 'Other' : s.brand;
      totals[brand] = (totals[brand] ?? 0) + s.estimatedValue;
    }
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  /// Owned pair count grouped by brand.
  Map<String, int> get countByBrand {
    final counts = <String, int>{};
    for (final s in owned) {
      final brand = s.brand.isEmpty ? 'Other' : s.brand;
      counts[brand] = (counts[brand] ?? 0) + 1;
    }
    return counts;
  }

  /// The most-worn owned pair, or null if nothing has been worn yet.
  Sneaker? get mostWorn {
    Sneaker? best;
    for (final sneaker in owned) {
      if (sneaker.wearCount <= 0) continue;
      if (best == null || sneaker.wearCount > best.wearCount) {
        best = sneaker;
      }
    }
    return best;
  }

  /// Generates a unique id for a brand-new sneaker.
  static String newId() => 'sb_${DateTime.now().microsecondsSinceEpoch}';
}
