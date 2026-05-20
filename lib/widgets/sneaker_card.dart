import 'package:flutter/material.dart';

import '../models/sneaker.dart';
import '../theme.dart';
import '../utils/formatting.dart';
import 'sneaker_image.dart';

/// A small rounded pill showing a sneaker's condition grade.
class ConditionChip extends StatelessWidget {
  const ConditionChip({super.key, required this.condition});

  final String condition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: conditionBg(condition),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        condition,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: conditionColor(condition),
        ),
      ),
    );
  }
}

/// A tappable row card for a single sneaker, used in the collection and
/// wishlist lists.
class SneakerCard extends StatelessWidget {
  const SneakerCard({
    super.key,
    required this.sneaker,
    required this.onTap,
  });

  final Sneaker sneaker;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  imageUrl: sneaker.imageUrl,
                  brand: sneaker.brand,
                  colorway: sneaker.colorway,
                  model: sneaker.model,
                  name: sneaker.name,
                  size: 66,
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
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: kMutedText,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          ConditionChip(condition: sneaker.condition),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sneaker.isWishlist
                                  ? 'On wishlist'
                                  : '${sneaker.wearCount} wears',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kMutedText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '\$${groupDigits(sneaker.estimatedValue.round())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Color(0xFFB9B9C2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
