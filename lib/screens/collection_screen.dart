import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sneaker.dart';
import '../state/collection_model.dart';
import '../theme.dart';
import '../utils/sneaker_query.dart';
import '../widgets/empty_state.dart';
import '../widgets/sneaker_card.dart';
import 'add_edit_sneaker_screen.dart';
import 'catalog_screen.dart';
import 'sneaker_detail_screen.dart';

/// The Collection tab: every owned pair, with text search and dropdown
/// filters for brand, condition and size.
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  SneakerQuery _query = const SneakerQuery();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(List<Sneaker> owned) async {
    final result = await showModalBottomSheet<SneakerQuery>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _FilterSheet(
        query: _query,
        brands: distinctBrands(owned),
        sizes: distinctSizes(owned),
      ),
    );
    if (result != null) {
      setState(() => _query = result);
    }
  }

  /// Lets the user choose how to add a sneaker: pick a known model from the
  /// catalog (fast, fills in the details), or type one in by hand.
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add a sneaker',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.storefront_outlined, color: kBrandColor),
              title: const Text('Pick from the catalog'),
              subtitle: const Text('Browse known sneakers and add one'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CatalogScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: kBrandColor),
              title: const Text('Enter details manually'),
              subtitle: const Text('Fill in a sneaker yourself'),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddEditSneakerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionModel>();
    final owned = collection.owned;
    final results = applySneakerQuery(owned, _query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Collection'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${owned.length} pairs',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(
                        () => _query = _query.copyWith(text: value),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search name, brand, colorway',
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
                const SizedBox(width: 8),
                _FilterButton(
                  count: _query.activeFilterCount,
                  onPressed: owned.isEmpty ? null : () => _openFilters(owned),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Showing ${results.length} of ${owned.length}',
                  style: const TextStyle(fontSize: 12.5, color: kMutedText),
                ),
                const Spacer(),
                if (_query.hasActiveFilters)
                  TextButton(
                    onPressed: () => setState(
                      () => _query = _query.clearedFilters(),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody(owned, results)),
        ],
      ),
    );
  }

  Widget _buildBody(List<Sneaker> owned, List<Sneaker> results) {
    if (owned.isEmpty) {
      return EmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No sneakers yet',
        message: 'Add your first pair, or grab one from the catalog.',
        action: ElevatedButton.icon(
          onPressed: () => _showAddOptions(context),
          icon: const Icon(Icons.add),
          label: const Text('Add a sneaker'),
        ),
      );
    }
    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No matches',
        message: 'Try a different search, or clear your filters.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: results.length,
      itemBuilder: (_, index) {
        final sneaker = results[index];
        return SneakerCard(
          sneaker: sneaker,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SneakerDetailScreen(sneakerId: sneaker.id),
            ),
          ),
        );
      },
    );
  }
}

/// The square filter button next to the search field, with a count badge.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kBorderColor),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune,
                color: enabled ? kBrandColor : const Color(0xFFBDBDC4),
              ),
              if (count > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: kAccentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The bottom sheet with the brand / condition / size dropdown filters.
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.query,
    required this.brands,
    required this.sizes,
  });

  final SneakerQuery query;
  final List<String> brands;
  final List<String> sizes;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _brand = widget.query.brand;
  late String _condition = widget.query.condition;
  late String _size = widget.query.size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        18 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter sneakers',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _dropdown(
            'Brand',
            _brand,
            widget.brands,
            (value) => setState(() => _brand = value),
          ),
          const SizedBox(height: 12),
          _dropdown(
            'Condition',
            _condition,
            kConditionOptions,
            (value) => setState(() => _condition = value),
          ),
          const SizedBox(height: 12),
          _dropdown(
            'Size',
            _size,
            widget.sizes,
            (value) => setState(() => _size = value),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() {
                    _brand = '';
                    _condition = '';
                    _size = '';
                  }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    widget.query.copyWith(
                      brand: _brand,
                      condition: _condition,
                      size: _size,
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: kMutedText,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          // Re-key on value changes so "Clear" visibly resets the dropdown.
          // The guard also avoids a stale value (the last pair of a brand
          // deleted while this filter was still set to it).
          key: ValueKey('$label-$value'),
          initialValue:
              (value.isNotEmpty && options.contains(value)) ? value : null,
          isExpanded: true,
          hint: const Text('Any'),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('Any')),
            ...options.map(
              (option) => DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              ),
            ),
          ],
          onChanged: (value) => onChanged(value ?? ''),
        ),
      ],
    );
  }
}
