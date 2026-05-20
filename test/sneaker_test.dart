import 'package:flutter_test/flutter_test.dart';
import 'package:sneakerbro/models/sneaker.dart';
import 'package:sneakerbro/utils/sneaker_query.dart';

// Unit tests for the parts with real logic in them: the sneaker metrics and
// the collection search/filter. Run with `flutter test`.
void main() {
  group('Sneaker metrics', () {
    test('cost per wear divides purchase price by wear count', () {
      const sneaker = Sneaker(
        id: '1',
        name: 'Test',
        purchasePrice: 200,
        wearCount: 50,
      );
      expect(sneaker.costPerWear, 4.0);
    });

    test('cost per wear is zero when the pair has never been worn', () {
      const sneaker = Sneaker(id: '1', name: 'Test', purchasePrice: 200);
      expect(sneaker.costPerWear, 0);
    });

    test('value change is estimated value minus purchase price', () {
      const sneaker = Sneaker(
        id: '1',
        name: 'Test',
        purchasePrice: 100,
        estimatedValue: 250,
      );
      expect(sneaker.valueChange, 150);
    });

    test('survives a round trip through toMap / fromMap', () {
      const original = Sneaker(
        id: 'abc',
        name: 'Air Jordan 1',
        brand: 'Jordan',
        size: '10',
        wearCount: 5,
        purchasePrice: 170,
      );
      final restored = Sneaker.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.brand, original.brand);
      expect(restored.size, original.size);
      expect(restored.wearCount, original.wearCount);
      expect(restored.purchasePrice, original.purchasePrice);
    });
  });

  group('applySneakerQuery', () {
    final sneakers = [
      const Sneaker(
        id: '1',
        name: 'Dunk Low Panda',
        brand: 'Nike',
        condition: 'Good',
        size: '10',
      ),
      const Sneaker(
        id: '2',
        name: 'Air Jordan 1',
        brand: 'Jordan',
        condition: 'Deadstock',
        size: '9',
      ),
      const Sneaker(
        id: '3',
        name: 'Yeezy 350',
        brand: 'adidas',
        condition: 'Good',
        size: '10',
      ),
    ];

    test('free-text search matches the brand', () {
      final results =
          applySneakerQuery(sneakers, const SneakerQuery(text: 'jordan'));
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('brand filter narrows the list', () {
      final results =
          applySneakerQuery(sneakers, const SneakerQuery(brand: 'Nike'));
      expect(results.length, 1);
      expect(results.first.id, '1');
    });

    test('condition and size filters combine', () {
      final results = applySneakerQuery(
        sneakers,
        const SneakerQuery(condition: 'Good', size: '10'),
      );
      expect(results.length, 2);
    });

    test('an empty query returns every sneaker', () {
      final results = applySneakerQuery(sneakers, const SneakerQuery());
      expect(results.length, 3);
    });
  });
}
