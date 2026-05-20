import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sneaker.dart';
import '../state/collection_model.dart';
import '../theme.dart';
import '../utils/formatting.dart';
import '../widgets/empty_state.dart';
import '../widgets/section_header.dart';
import '../widgets/stat_card.dart';

const Color _green = Color(0xFF2E7D32);
const Color _red = Color(0xFFC62828);

/// The Analytics screen: collection value, usage totals, the most-worn pair
/// and a cost-per-wear leaderboard.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionModel>();
    final owned = collection.owned;

    if (owned.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const EmptyState(
          icon: Icons.insights,
          title: 'No analytics yet',
          message: 'Add a few sneakers to your collection to see your stats.',
        ),
      );
    }

    // Worn pairs, best (lowest) cost-per-wear first.
    final worn = owned.where((s) => s.wearCount > 0).toList()
      ..sort((a, b) => a.costPerWear.compareTo(b.costPerWear));
    final neverWorn = owned.length - worn.length;
    final mostWorn = collection.mostWorn;
    final change = collection.totalValueChange;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Collection value'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                label: 'Sneakers owned',
                value: '${collection.ownedCount}',
                icon: Icons.inventory_2_outlined,
              ),
              StatCard(
                label: 'Total spent',
                value: moneyWhole(collection.totalSpent),
                icon: Icons.payments_outlined,
              ),
              StatCard(
                label: 'Market value',
                value: moneyWhole(collection.totalEstimatedValue),
                icon: Icons.sell_outlined,
                color: _green,
                footnote: '$kPriceSnapshot snapshot',
              ),
              StatCard(
                label: 'Value change',
                value: signedMoneyWhole(change),
                icon: change >= 0 ? Icons.trending_up : Icons.trending_down,
                color: change >= 0 ? _green : _red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Value by brand'),
          const SizedBox(height: 10),
          _BrandValueChart(
            valueByBrand: collection.valueByBrand,
            countByBrand: collection.countByBrand,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Usage'),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatCard(
                label: 'Total wears',
                value: groupDigits(collection.totalWears),
                icon: Icons.directions_walk,
              ),
              StatCard(
                label: 'Total steps',
                value: groupDigits(collection.totalSteps),
                icon: Icons.directions_run,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Most worn pair'),
          const SizedBox(height: 10),
          if (mostWorn != null)
            _MostWornPanel(sneaker: mostWorn)
          else
            const _Hint('No wears logged yet.'),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Cost per wear'),
          const SizedBox(height: 4),
          const Text(
            'What each pair has cost you per time worn. Lower is better '
            'value, so the best-value pairs are at the top.',
            style: TextStyle(fontSize: 12.5, color: kMutedText),
          ),
          const SizedBox(height: 10),
          if (worn.isEmpty)
            const _Hint(
              'No pairs have been worn yet. Log a wear on a sneaker to '
              'start building this list.',
            )
          else
            ...List.generate(
              worn.length,
              (index) => _LeaderRow(rank: index + 1, sneaker: worn[index]),
            ),
          if (neverWorn > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$neverWorn ${neverWorn == 1 ? 'pair has' : 'pairs have'} '
              'no wears logged yet.',
              style: const TextStyle(fontSize: 12.5, color: kMutedText),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MostWornPanel extends StatelessWidget {
  const _MostWornPanel({required this.sneaker});

  final Sneaker sneaker;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBrandColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sneaker.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sneaker.subtitle,
            style: const TextStyle(color: Color(0xFFBFBFCB), fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniMetric(value: '${sneaker.wearCount}', label: 'wears'),
              _MiniMetric(
                value: groupDigits(sneaker.totalSteps),
                label: 'steps',
              ),
              _MiniMetric(
                value: sneaker.wearCount > 0
                    ? money(sneaker.costPerWear)
                    : '-',
                label: 'per wear',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.value, required this.label});

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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBFBFCB), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const _LeaderRow({required this.rank, required this.sneaker});

  final int rank;
  final Sneaker sneaker;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? kAccentColor : kSurfaceColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.white : kMutedText,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sneaker.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sneaker.wearCount} wears · '
                  '${money(sneaker.purchasePrice)} paid',
                  style: const TextStyle(fontSize: 11.5, color: kMutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(sneaker.costPerWear),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
              const Text(
                'per wear',
                style: TextStyle(fontSize: 10.5, color: kMutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
        boxShadow: kCardShadow,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: kMutedText),
      ),
    );
  }
}

/// A horizontal bar chart of the owned collection's market value, by brand.
/// Drawn from plain widgets - no charting dependency - to match the rest of
/// the app.
class _BrandValueChart extends StatelessWidget {
  const _BrandValueChart({
    required this.valueByBrand,
    required this.countByBrand,
  });

  final Map<String, double> valueByBrand;
  final Map<String, int> countByBrand;

  @override
  Widget build(BuildContext context) {
    final entries = valueByBrand.entries.toList();
    final maxValue = entries.isEmpty ? 0.0 : entries.first.value;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
        boxShadow: kCardShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _BrandBar(
              brand: entries[i].key,
              value: entries[i].value,
              count: countByBrand[entries[i].key] ?? 0,
              fraction: maxValue > 0
                  ? (entries[i].value / maxValue).clamp(0.04, 1.0)
                  : 0.0,
            ),
          ],
        ],
      ),
    );
  }
}

class _BrandBar extends StatelessWidget {
  const _BrandBar({
    required this.brand,
    required this.value,
    required this.count,
    required this.fraction,
  });

  final String brand;
  final double value;
  final int count;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '$brand  ·  $count ${count == 1 ? 'pair' : 'pairs'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              moneyWhole(value),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 10,
            color: kSurfaceColor,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              heightFactor: 1,
              child: const ColoredBox(color: kBrandColor),
            ),
          ),
        ),
      ],
    );
  }
}
