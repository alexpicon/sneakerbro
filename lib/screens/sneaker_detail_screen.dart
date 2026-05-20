import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sneaker.dart';
import '../state/collection_model.dart';
import '../theme.dart';
import '../utils/formatting.dart';
import '../widgets/sneaker_card.dart' show ConditionChip;
import '../widgets/sneaker_image.dart';
import 'add_edit_sneaker_screen.dart';

/// The full detail view for one sneaker: its info, usage tracking, and the
/// edit / delete / log-a-wear actions.
class SneakerDetailScreen extends StatelessWidget {
  const SneakerDetailScreen({super.key, required this.sneakerId});

  final String sneakerId;

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionModel>();
    final sneaker = collection.byId(sneakerId);

    if (sneaker == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sneaker')),
        body: const Center(
          child: Text('This sneaker is no longer in your collection.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sneaker.isWishlist ? 'Wishlist item' : 'Sneaker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditSneakerScreen(
                  sneaker: sneaker,
                  isEditing: true,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context, sneaker),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: SneakerImage(
              imageUrl: sneaker.imageUrl,
              brand: sneaker.brand,
              colorway: sneaker.colorway,
              model: sneaker.model,
              name: sneaker.name,
              size: 160,
              borderRadius: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            sneaker.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(sneaker.subtitle, style: const TextStyle(color: kMutedText)),
          const SizedBox(height: 10),
          Row(
            children: [
              ConditionChip(condition: sneaker.condition),
              if (sneaker.isWishlist) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE7E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'On wishlist',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kAccentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          if (!sneaker.isWishlist) ...[
            _UsageCard(sneaker: sneaker),
            const SizedBox(height: 14),
          ],
          _DetailsCard(sneaker: sneaker),
          if (sneaker.notes.isNotEmpty) ...[
            const SizedBox(height: 14),
            _NotesCard(notes: sneaker.notes),
          ],
          const SizedBox(height: 20),
          if (sneaker.isWishlist)
            ElevatedButton.icon(
              onPressed: () => _moveToCollection(context),
              icon: const Icon(Icons.move_to_inbox),
              label: const Text('Move to my collection'),
            )
          else
            ElevatedButton.icon(
              onPressed: () => _logWear(context, sneaker),
              icon: const Icon(Icons.directions_walk),
              label: const Text('Log a wear'),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Sneaker sneaker) async {
    final navigator = Navigator.of(context);
    final model = context.read<CollectionModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete sneaker?'),
        content: Text('"${sneaker.name}" will be removed from SneakerBro.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await model.remove(sneaker.id);
      navigator.pop();
    }
  }

  void _moveToCollection(BuildContext context) {
    context.read<CollectionModel>().moveToCollection(sneakerId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Moved to your collection')),
    );
  }

  Future<void> _logWear(BuildContext context, Sneaker sneaker) async {
    final model = context.read<CollectionModel>();
    final messenger = ScaffoldMessenger.of(context);
    final stepsController = TextEditingController();

    final steps = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log a wear'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This adds one wear. Optionally enter the steps you walked '
              'in them today.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Steps (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              ctx,
              int.tryParse(stepsController.text.trim()) ?? 0,
            ),
            child: const Text('Log wear'),
          ),
        ],
      ),
    );
    stepsController.dispose();

    if (steps == null) return; // cancelled
    await model.logWear(sneaker.id, wears: 1, steps: steps);
    messenger.showSnackBar(
      SnackBar(content: Text('Logged a wear for ${sneaker.name}')),
    );
  }
}

/// Usage tracking: wears, steps and the cost-per-wear metric.
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.sneaker});

  final Sneaker sneaker;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Usage',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _UsageStat(
                value: '${sneaker.wearCount}',
                label: 'Wears',
              ),
              _UsageStat(
                value: groupDigits(sneaker.totalSteps),
                label: 'Total steps',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _UsageStat(
                value: sneaker.wearCount > 0
                    ? money(sneaker.costPerWear)
                    : '-',
                label: 'Cost per wear',
              ),
              _UsageStat(
                value: sneaker.wearCount > 0
                    ? groupDigits(sneaker.stepsPerWear)
                    : '-',
                label: 'Steps per wear',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageStat extends StatelessWidget {
  const _UsageStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: kMutedText)),
        ],
      ),
    );
  }
}

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.sneaker});

  final Sneaker sneaker;

  @override
  Widget build(BuildContext context) {
    final change = sneaker.valueChange;
    final rows = <Widget>[
      if (sneaker.brand.isNotEmpty) _InfoRow('Brand', sneaker.brand),
      if (sneaker.model.isNotEmpty) _InfoRow('Model', sneaker.model),
      if (sneaker.colorway.isNotEmpty) _InfoRow('Colorway', sneaker.colorway),
      if (sneaker.size.isNotEmpty) _InfoRow('Size', 'US ${sneaker.size}'),
      _InfoRow('Condition', sneaker.condition),
      _InfoRow('Purchase price', money(sneaker.purchasePrice)),
      _InfoRow('Market value', money(sneaker.estimatedValue)),
      _InfoRow(
        'Value change',
        signedMoney(change),
        valueColor: change >= 0
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828),
      ),
      _InfoRow('Purchase date', longDate(sneaker.purchaseDate)),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...rows,
          const SizedBox(height: 10),
          const Text(
            'Market value as of September 2022',
            style: TextStyle(fontSize: 11.5, color: kMutedText),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notes',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(notes, style: const TextStyle(height: 1.4)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: kMutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared white rounded card used by the detail sections.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: kCardShadow,
      ),
      child: child,
    );
  }
}
