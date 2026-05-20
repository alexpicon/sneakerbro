import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sneaker.dart';
import '../state/collection_model.dart';
import '../theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/sneaker_card.dart';
import 'add_edit_sneaker_screen.dart';
import 'sneaker_detail_screen.dart';

/// The Wishlist tab: pairs the user wants but does not own yet. Opening a
/// wishlist pair gives the option to move it into the collection.
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  void _addItem(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditSneakerScreen(
          sneaker: Sneaker(
            id: CollectionModel.newId(),
            name: '',
            isWishlist: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionModel>();
    final wishlist = collection.wishlist;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${wishlist.length} pairs',
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addItem(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: wishlist.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Your wishlist is empty',
              message:
                  'Add pairs you are chasing, or save them from the catalog.',
              action: ElevatedButton.icon(
                onPressed: () => _addItem(context),
                icon: const Icon(Icons.add),
                label: const Text('Add a wishlist item'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
              itemCount: wishlist.length + 1,
              itemBuilder: (_, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Open a wishlist pair to move it into your collection '
                      'once you pick it up.',
                      style: TextStyle(fontSize: 12.5, color: kMutedText),
                    ),
                  );
                }
                final sneaker = wishlist[index - 1];
                return SneakerCard(
                  sneaker: sneaker,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SneakerDetailScreen(sneakerId: sneaker.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
