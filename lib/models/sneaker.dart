import '../utils/parsing.dart';

/// The condition grades a sneaker can have. "Deadstock" (DS) is the
/// sneakerhead term for a pair that has never been worn.
const List<String> kConditionOptions = [
  'Deadstock',
  'Like New',
  'Good',
  'Worn',
  'Beat',
];

/// A single pair of sneakers. Used both for owned pairs and for wishlist
/// entries - [isWishlist] is what tells the two apart.
///
/// Instances are immutable; edits go through [copyWith] so the state layer
/// can swap a whole object and persist it in one step.
class Sneaker {
  const Sneaker({
    required this.id,
    required this.name,
    this.brand = '',
    this.model = '',
    this.colorway = '',
    this.size = '',
    this.condition = 'Good',
    this.purchasePrice = 0,
    this.estimatedValue = 0,
    this.purchaseDate,
    this.imageUrl = '',
    this.totalSteps = 0,
    this.wearCount = 0,
    this.notes = '',
    this.isWishlist = false,
  });

  final String id;
  final String name;
  final String brand;
  final String model;
  final String colorway;
  final String size;
  final String condition;
  final double purchasePrice;
  final double estimatedValue;
  final DateTime? purchaseDate;
  final String imageUrl;
  final int totalSteps;
  final int wearCount;
  final String notes;
  final bool isWishlist;

  /// Cost per wear - the classic collector's metric. A $200 pair worn 100
  /// times costs $2 a wear; a $90 pair worn twice costs $45 a wear.
  double get costPerWear => wearCount > 0 ? purchasePrice / wearCount : 0;

  /// How far the estimated value has moved from what was paid.
  double get valueChange => estimatedValue - purchasePrice;

  /// Average steps per wear, useful on the analytics screen.
  int get stepsPerWear => wearCount > 0 ? (totalSteps / wearCount).round() : 0;

  /// A single line describing the pair, e.g. "Jordan - Chicago - US 10".
  String get subtitle {
    final bits = <String>[];
    if (brand.isNotEmpty) bits.add(brand);
    if (colorway.isNotEmpty) bits.add(colorway);
    if (size.isNotEmpty) bits.add('US $size');
    return bits.join(' - ');
  }

  Sneaker copyWith({
    String? name,
    String? brand,
    String? model,
    String? colorway,
    String? size,
    String? condition,
    double? purchasePrice,
    double? estimatedValue,
    DateTime? purchaseDate,
    bool clearPurchaseDate = false,
    String? imageUrl,
    int? totalSteps,
    int? wearCount,
    String? notes,
    bool? isWishlist,
  }) {
    return Sneaker(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      colorway: colorway ?? this.colorway,
      size: size ?? this.size,
      condition: condition ?? this.condition,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      purchaseDate:
          clearPurchaseDate ? null : (purchaseDate ?? this.purchaseDate),
      imageUrl: imageUrl ?? this.imageUrl,
      totalSteps: totalSteps ?? this.totalSteps,
      wearCount: wearCount ?? this.wearCount,
      notes: notes ?? this.notes,
      isWishlist: isWishlist ?? this.isWishlist,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'model': model,
      'colorway': colorway,
      'size': size,
      'condition': condition,
      'purchasePrice': purchasePrice,
      'estimatedValue': estimatedValue,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'totalSteps': totalSteps,
      'wearCount': wearCount,
      'notes': notes,
      'isWishlist': isWishlist,
    };
  }

  factory Sneaker.fromMap(Map<String, dynamic> map) {
    return Sneaker(
      id: asString(map['id']),
      name: asString(map['name']),
      brand: asString(map['brand']),
      model: asString(map['model']),
      colorway: asString(map['colorway']),
      size: asString(map['size']),
      condition: map['condition'] == null ? 'Good' : asString(map['condition']),
      purchasePrice: asDouble(map['purchasePrice']),
      estimatedValue: asDouble(map['estimatedValue']),
      purchaseDate: asDate(map['purchaseDate']),
      imageUrl: asString(map['imageUrl']),
      totalSteps: asInt(map['totalSteps']),
      wearCount: asInt(map['wearCount']),
      notes: asString(map['notes']),
      isWishlist: asBool(map['isWishlist']),
    );
  }
}
