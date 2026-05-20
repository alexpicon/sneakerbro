// Small, forgiving helpers for reading values out of decoded JSON maps.
// Bundled JSON and the local Hive store can both carry slightly loose types
// (a price written as "120" instead of 120, a missing field, etc.), so these
// keep the model factories from crashing on imperfect data.

String asString(dynamic value) => value?.toString() ?? '';

double asDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int asInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return value?.toString().toLowerCase() == 'true';
}

DateTime? asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

List<String> asStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return <String>[];
}
