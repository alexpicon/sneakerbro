import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drop_alert.dart';
import '../state/catalog_model.dart';
import '../theme.dart';
import '../utils/formatting.dart';
import '../widgets/empty_state.dart';

/// The Alerts tab: a saved snapshot of sneaker drop alerts, filterable by
/// alert type. In the original app this feed was live from the InfoBots
/// scrapers.
class DropAlertsScreen extends StatefulWidget {
  const DropAlertsScreen({super.key});

  @override
  State<DropAlertsScreen> createState() => _DropAlertsScreenState();
}

class _DropAlertsScreenState extends State<DropAlertsScreen> {
  AlertType? _filter;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogModel>();
    final alerts = catalog.alertsOfType(_filter);

    return Scaffold(
      appBar: AppBar(title: const Text('Drop Alerts')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.smart_toy_outlined, size: 18, color: kBrandColor),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These drop alerts came from my InfoBots scrapers. This '
                    'archive ships a saved snapshot of that feed.',
                    style: TextStyle(fontSize: 12, color: kMutedText),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', null),
                _chip('New product', AlertType.newProduct),
                _chip('Restock', AlertType.restock),
                _chip('Price drop', AlertType.priceDrop),
              ],
            ),
          ),
          Expanded(
            child: alerts.isEmpty
                ? const EmptyState(
                    icon: Icons.notifications_off_outlined,
                    title: 'No alerts here',
                    message: 'No drop alerts match this filter.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    itemCount: alerts.length,
                    itemBuilder: (_, index) =>
                        _AlertCard(alert: alerts[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, AlertType? type) {
    final selected = _filter == type;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Center(
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => setState(() => _filter = type),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : kMutedText,
          ),
          selectedColor: kBrandColor,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: kBorderColor),
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final DropAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alertColor(alert.alertType);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: alertBg(alert.alertType),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(alertIcon(alert.alertType), size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(
                      alert.alertType.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                money(alert.price),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.productName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [alert.brand, alert.store]
                .where((s) => s.isNotEmpty)
                .join(' · '),
            style: const TextStyle(fontSize: 12.5, color: kMutedText),
          ),
          if (alert.sizes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: alert.sizes
                  .map(
                    (size) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kSurfaceColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: kBorderColor),
                      ),
                      child: Text(
                        size,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.smart_toy_outlined,
                size: 13,
                color: Color(0xFFB9B9C2),
              ),
              const SizedBox(width: 4),
              Text(
                alert.sourceBot,
                style: const TextStyle(fontSize: 11, color: kMutedText),
              ),
              const Spacer(),
              Text(
                longDate(alert.timestamp, fallback: ''),
                style: const TextStyle(fontSize: 11, color: kMutedText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
