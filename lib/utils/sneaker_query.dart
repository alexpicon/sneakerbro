import '../models/sneaker.dart';

/// A set of search and filter criteria for a list of sneakers.
///
/// [text] is a free-text search over name / brand / model / colorway.
/// The remaining fields are exact-match filters; an empty string means
/// "any". Used by the collection and wishlist screens.
class SneakerQuery {
  const SneakerQuery({
    this.text = '',
    this.brand = '',
    this.condition = '',
    this.size = '',
  });

  final String text;
  final String brand;
  final String condition;
  final String size;

  /// True when at least one of the dropdown filters is narrowing the list.
  bool get hasActiveFilters =>
      brand.isNotEmpty || condition.isNotEmpty || size.isNotEmpty;

  /// How many dropdown filters are active - shown on the filter button.
  int get activeFilterCount =>
      (brand.isNotEmpty ? 1 : 0) +
      (condition.isNotEmpty ? 1 : 0) +
      (size.isNotEmpty ? 1 : 0);

  SneakerQuery copyWith({
    String? text,
    String? brand,
    String? condition,
    String? size,
  }) {
    return SneakerQuery(
      text: text ?? this.text,
      brand: brand ?? this.brand,
      condition: condition ?? this.condition,
      size: size ?? this.size,
    );
  }

  /// Returns a copy with every dropdown filter cleared but the text kept.
  SneakerQuery clearedFilters() => SneakerQuery(text: text);
}

/// Applies [query] to [input] and returns the matching sneakers.
List<Sneaker> applySneakerQuery(List<Sneaker> input, SneakerQuery query) {
  final needle = query.text.trim().toLowerCase();
  return input.where((sneaker) {
    if (needle.isNotEmpty) {
      final haystack =
          '${sneaker.name} ${sneaker.brand} ${sneaker.model} ${sneaker.colorway}'
              .toLowerCase();
      if (!haystack.contains(needle)) return false;
    }
    if (query.brand.isNotEmpty && sneaker.brand != query.brand) return false;
    if (query.condition.isNotEmpty && sneaker.condition != query.condition) {
      return false;
    }
    if (query.size.isNotEmpty && sneaker.size != query.size) return false;
    return true;
  }).toList();
}

/// The distinct, sorted brand values present in [sneakers].
List<String> distinctBrands(List<Sneaker> sneakers) {
  final set = sneakers
      .map((s) => s.brand)
      .where((b) => b.isNotEmpty)
      .toSet()
      .toList();
  set.sort();
  return set;
}

/// The distinct sizes present in [sneakers], sorted numerically where possible.
List<String> distinctSizes(List<Sneaker> sneakers) {
  final set =
      sneakers.map((s) => s.size).where((s) => s.isNotEmpty).toSet().toList();
  set.sort((a, b) {
    final na = double.tryParse(a);
    final nb = double.tryParse(b);
    if (na != null && nb != null) return na.compareTo(nb);
    return a.compareTo(b);
  });
  return set;
}
