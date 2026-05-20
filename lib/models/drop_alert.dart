import '../utils/parsing.dart';

/// The kinds of alert the InfoBots scrapers used to emit.
enum AlertType { newProduct, restock, priceDrop, unknown }

AlertType alertTypeFromRaw(String raw) {
  switch (raw) {
    case 'new_product':
      return AlertType.newProduct;
    case 'restock':
      return AlertType.restock;
    case 'price_drop':
      return AlertType.priceDrop;
    default:
      return AlertType.unknown;
  }
}

extension AlertTypeInfo on AlertType {
  /// The stored/raw string value.
  String get raw {
    switch (this) {
      case AlertType.newProduct:
        return 'new_product';
      case AlertType.restock:
        return 'restock';
      case AlertType.priceDrop:
        return 'price_drop';
      case AlertType.unknown:
        return 'unknown';
    }
  }

  /// A human label for the UI.
  String get label {
    switch (this) {
      case AlertType.newProduct:
        return 'New product';
      case AlertType.restock:
        return 'Restock';
      case AlertType.priceDrop:
        return 'Price drop';
      case AlertType.unknown:
        return 'Alert';
    }
  }
}

/// A drop alert. In the original app these arrived live from my InfoBots
/// scrapers; this archive ships a saved snapshot of that feed as bundled JSON.
class DropAlert {
  const DropAlert({
    required this.id,
    required this.productName,
    this.brand = '',
    this.store = '',
    this.price = 0,
    this.sizes = const [],
    this.url = '',
    this.timestamp,
    this.sourceBot = '',
    this.alertType = AlertType.unknown,
  });

  final String id;
  final String productName;
  final String brand;
  final String store;
  final double price;
  final List<String> sizes;
  final String url;
  final DateTime? timestamp;
  final String sourceBot;
  final AlertType alertType;

  factory DropAlert.fromMap(Map<String, dynamic> map) {
    return DropAlert(
      id: asString(map['id']),
      productName: asString(map['productName']),
      brand: asString(map['brand']),
      store: asString(map['store']),
      price: asDouble(map['price']),
      sizes: asStringList(map['sizes']),
      url: asString(map['url']),
      timestamp: asDate(map['timestamp']),
      sourceBot: asString(map['sourceBot']),
      alertType: alertTypeFromRaw(asString(map['alertType'])),
    );
  }
}
