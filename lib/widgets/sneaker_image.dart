import 'package:flutter/material.dart';

import '../theme.dart';
import 'local_image.dart';
import 'sneaker_artwork.dart';

/// The image shown for a sneaker.
///
/// Resolution order:
///  1. A photo the user took or picked, stored on the device.
///  2. A remote image URL (catalog items, or a pasted URL).
///  3. [SneakerArtwork] - a flat illustration drawn from the colorway and
///     model, used whenever there is no photo. It always works offline.
///
/// Anything that fails to load falls through to the artwork, so the image
/// slot is never blank.
class SneakerImage extends StatelessWidget {
  const SneakerImage({
    super.key,
    this.imageUrl = '',
    required this.brand,
    required this.colorway,
    this.model = '',
    this.name = '',
    this.size = 64,
    this.borderRadius = 12,
  });

  final String imageUrl;
  final String brand;
  final String colorway;
  final String model;
  final String name;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final artwork = SneakerArtwork(
      brand: brand,
      colorway: colorway,
      model: model,
      name: name,
      size: size,
      borderRadius: borderRadius,
    );

    // A remote photo: catalog imagery, or a URL the user pasted in.
    if (imageUrl.startsWith('http') || imageUrl.startsWith('blob:')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => artwork,
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _loadingTile(),
        ),
      );
    }

    // A photo bundled with the app: the seeded collection's own photos.
    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => artwork,
        ),
      );
    }

    // A photo stored on the device. On web there is no file system, so
    // [localImage] returns null and we draw the artwork instead.
    if (imageUrl.isNotEmpty) {
      final local = localImage(
        imageUrl,
        size: size,
        borderRadius: borderRadius,
      );
      if (local != null) return local;
    }

    return artwork;
  }

  Widget _loadingTile() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
