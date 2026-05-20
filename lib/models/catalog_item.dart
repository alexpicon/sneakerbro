import '../utils/parsing.dart';

/// An entry in the browsable sneaker catalog. The catalog ships as bundled,
/// read-only JSON; a user turns a catalog item into a real [Sneaker] by
/// adding it to their collection or wishlist.
class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    this.brand = '',
    this.model = '',
    this.colorway = '',
    this.retailPrice = 0,
    this.imageUrl = '',
    this.releaseDate,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final String colorway;
  final double retailPrice;
  final String imageUrl;
  final DateTime? releaseDate;

  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      id: asString(map['id']),
      name: asString(map['name']),
      brand: asString(map['brand']),
      model: asString(map['model']),
      colorway: asString(map['colorway']),
      retailPrice: asDouble(map['retailPrice']),
      imageUrl: asString(map['imageUrl']),
      releaseDate: asDate(map['releaseDate']),
    );
  }
}
