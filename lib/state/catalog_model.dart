import 'package:flutter/foundation.dart';

import '../models/catalog_item.dart';
import '../models/drop_alert.dart';
import '../services/asset_loader.dart';

/// Holds the reference data that ships with the app: the browsable sneaker
/// catalog and the drop-alert feed.
///
/// **History.** The catalog was originally fetched from a third-party sneaker
/// API, and the alerts came in live from InfoBots, the scraper project.
/// Both sources were retired with the project; the archive ships the last
/// responses they returned, saved to `assets/data/*.json`. The JSON files
/// are loaded once at startup and never change after that, so this notifier
/// fires [notifyListeners] one time, when loading finishes.
class CatalogModel extends ChangeNotifier {
  List<CatalogItem> _catalog = [];
  List<DropAlert> _alerts = [];
  bool _loaded = false;

  List<CatalogItem> get catalog => List.unmodifiable(_catalog);
  List<DropAlert> get alerts => List.unmodifiable(_alerts);
  bool get loaded => _loaded;

  Future<void> init() async {
    // LIVE: until 2022 this fetched from a third-party sneaker API, and the
    // drop alerts came in from the InfoBots scrapers. Both are gone with
    // the project, so the archive reads the last responses from disk - the
    // snapshots below.
    final catalogRaw = await AssetLoader.loadObjects('assets/data/catalog.json');
    _catalog = catalogRaw.map(CatalogItem.fromMap).toList();
    _catalog.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final alertsRaw =
        await AssetLoader.loadObjects('assets/data/drop_alerts.json');
    _alerts = alertsRaw.map(DropAlert.fromMap).toList();
    // Newest alert first.
    _alerts.sort((a, b) {
      final at = a.timestamp ?? DateTime(2000);
      final bt = b.timestamp ?? DateTime(2000);
      return bt.compareTo(at);
    });

    _loaded = true;
    notifyListeners();
  }

  /// The [count] most recent alerts, for the dashboard preview.
  List<DropAlert> recentAlerts(int count) =>
      _alerts.take(count).toList(growable: false);

  /// Alerts of a single type, or all alerts when [type] is null.
  List<DropAlert> alertsOfType(AlertType? type) {
    if (type == null) return alerts;
    return _alerts.where((a) => a.alertType == type).toList(growable: false);
  }
}
