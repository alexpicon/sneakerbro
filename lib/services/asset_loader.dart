import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads the bundled JSON files (catalog, drop alerts, sample collection)
/// that ship inside the app under assets/data/.
class AssetLoader {
  /// Reads a JSON file that contains a top-level array and returns its items.
  /// Returns an empty list if the file is missing or is not a JSON array,
  /// so a bad asset can never crash startup.
  static Future<List<Map<String, dynamic>>> loadObjects(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final decoded = json.decode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
