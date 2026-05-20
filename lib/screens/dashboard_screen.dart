import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drop_alert.dart';
import '../models/sneaker.dart';
import '../services/auth_service.dart';
import '../state/catalog_model.dart';
import '../state/collection_model.dart';
import '../theme.dart';
import '../utils/formatting.dart';
import '../widgets/section_header.dart';
import '../widgets/sneaker_image.dart';
import '../widgets/stat_card.dart';
import 'analytics_screen.dart';
import 'drop_alerts_screen.dart';
import 'sneaker_detail_screen.dart';

/// The home tab: a quick summary of the collection plus recent drop alerts.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final collection = context.watch<CollectionModel>();
    final catalog = context.watch<CatalogModel>();
    final mostWorn = collection.mostWorn;
    final recentAlerts = catalog.recentAlerts(3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SneakerBro'),
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: 'Profile',
          onPressed: () => _showProfileSheet(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Analytics',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Your collection at a glance',
            style: TextStyle(fontSize: 13, color: kMutedText),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.32,
            children: [
              StatCard(
                label: 'Sneakers owned',
                value: '${collection.ownedCount}',
                icon: Icons.inventory_2_outlined,
              ),
              StatCard(
                label: 'Market value',
                value: moneyWhole(collection.totalEstimatedValue),
                icon: Icons.sell_outlined,
                color: const Color(0xFF2E7D32),
                footnote: '$kPriceSnapshot snapshot',
              ),
              StatCard(
                label: 'Total wears',
                value: groupDigits(collection.totalWears),
                icon: Icons.directions_walk,
              ),
              StatCard(
                label: 'On the wishlist',
                value: '${collection.wishlistCount}',
                icon: Icons.favorite_border,
                color: kAccentColor,
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Most worn pair'),
          const SizedBox(height: 8),
          if (mostWorn != null)
            _MostWornCard(sneaker: mostWorn)
          else
            const _HintCard(
              text: 'No wears logged yet. Open a sneaker and tap '
                  '"Log a wear" to start tracking.',
            ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Recent drop alerts',
            actionLabel: 'See all',
            onAction: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DropAlertsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          if (recentAlerts.isEmpty)
            const _HintCard(text: 'No drop alerts in the bundled feed.')
          else
            ...recentAlerts.map((a) => _MiniAlertRow(alert: a)),
          const SizedBox(height: 18),
          const _AnalyticsCta(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Bottom sheet that shows the signed-in user and the sign-out button.
  void _showProfileSheet(BuildContext context) {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kBrandColor,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
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
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  await context.read<AuthService>().signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A white, rounded, optionally tappable container used for dashboard cards.
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          child: Padding(padding: const EdgeInsets.all(12), child: child),
        ),
      ),
    );
  }
}

class _MostWornCard extends StatelessWidget {
  const _MostWornCard({required this.sneaker});

  final Sneaker sneaker;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SneakerDetailScreen(sneakerId: sneaker.id),
        ),
      ),
      child: Row(
        children: [
          SneakerImage(
            imageUrl: sneaker.imageUrl,
            brand: sneaker.brand,
            colorway: sneaker.colorway,
            model: sneaker.model,
            name: sneaker.name,
            size: 60,
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
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sneaker.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, color: kMutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${sneaker.wearCount}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'wears',
                style: TextStyle(fontSize: 11, color: kMutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniAlertRow extends StatelessWidget {
  const _MiniAlertRow({required this.alert});

  final DropAlert alert;

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
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: alertBg(alert.alertType),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              alertIcon(alert.alertType),
              size: 19,
              color: alertColor(alert.alertType),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  '${alert.alertType.label} · ${alert.store}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: kMutedText),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            money(alert.price),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
        boxShadow: kCardShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: kMutedText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: kMutedText),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCta extends StatelessWidget {
  const _AnalyticsCta();

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
      ),
      child: const Row(
        children: [
          Icon(Icons.insights, color: kBrandColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collection analytics',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                ),
                SizedBox(height: 2),
                Text(
                  'Steps, wears, cost-per-wear and value',
                  style: TextStyle(fontSize: 12, color: kMutedText),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Color(0xFFB9B9C2)),
        ],
      ),
    );
  }
}
