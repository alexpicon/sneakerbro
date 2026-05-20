import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalog_item.dart';
import '../models/sneaker.dart';
import '../state/catalog_model.dart';
import '../state/collection_model.dart';
import '../theme.dart';
import '../utils/formatting.dart';
import '../widgets/empty_state.dart';
import '../widgets/sneaker_image.dart';
import 'add_edit_sneaker_screen.dart';

/// The Catalog tab: a browsable list of reference sneakers loaded from
/// bundled JSON. Any item can be added to the collection or the wishlist.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _search = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CatalogItem> _filtered(List<CatalogItem> items) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      final haystack =
          '${item.name} ${item.brand} ${item.model} ${item.colorway}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  /// Builds a [Sneaker] from a catalog item, ready to add.
  Sneaker _toSneaker(CatalogItem item, {required bool wishlist}) {
    return Sneaker(
      id: CollectionModel.newId(),
      name: item.name,
      brand: item.brand,
      model: item.model,
      colorway: item.colorway,
      condition: 'Deadstock',
      estimatedValue: item.retailPrice,
      purchasePrice: wishlist ? 0 : item.retailPrice,
      imageUrl: item.imageUrl,
      isWishlist: wishlist,
    );
  }

  void _openItem(CatalogItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => _CatalogItemSheet(
        item: item,
        onAddToCollection: () {
          Navigator.pop(sheetContext);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditSneakerScreen(
                sneaker: _toSneaker(item, wishlist: false),
              ),
            ),
          );
        },
        onAddToWishlist: () {
          context
              .read<CollectionModel>()
              .upsert(_toSneaker(item, wishlist: true));
          Navigator.pop(sheetContext);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${item.name} added to your wishlist')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogModel>();
    final items = _filtered(catalog.catalog);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${catalog.catalog.length} releases',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: _controller,
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'Search the catalog',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kBorderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: kBrandColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tap a sneaker to add it to your collection or wishlist.',
                style: TextStyle(fontSize: 12.5, color: kMutedText),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off,
                    title: 'Nothing in the catalog matches',
                    message: 'Try a different search term.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (_, index) => _CatalogCard(
                      item: items[index],
                      onTap: () => _openItem(items[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final release = monthYear(item.releaseDate, fallback: '');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: kCardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SneakerImage(
                  imageUrl: item.imageUrl,
                  brand: item.brand,
                  colorway: item.colorway,
                  model: item.model,
                  name: item.name,
                  size: 66,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [item.brand, item.colorway]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: kMutedText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Retail ${money(item.retailPrice)}'
                        '${release.isEmpty ? '' : '  ·  $release'}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.add_circle_outline, color: kBrandColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogItemSheet extends StatelessWidget {
  const _CatalogItemSheet({
    required this.item,
    required this.onAddToCollection,
    required this.onAddToWishlist,
  });

  final CatalogItem item;
  final VoidCallback onAddToCollection;
  final VoidCallback onAddToWishlist;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SneakerImage(
                imageUrl: item.imageUrl,
                brand: item.brand,
                colorway: item.colorway,
                model: item.model,
                name: item.name,
                size: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [item.brand, item.model, item.colorway]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: kMutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _factTile('Retail price', money(item.retailPrice)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _factTile(
                  'Released',
                  monthYear(item.releaseDate, fallback: 'Unknown'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAddToCollection,
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Add to my collection'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAddToWishlist,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.favorite_border),
              label: const Text('Add to wishlist'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _factTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: kMutedText),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
