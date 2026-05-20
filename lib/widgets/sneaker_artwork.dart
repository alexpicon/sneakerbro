import 'package:flutter/material.dart';

import '../utils/colorways.dart';

/// The three shoe shapes the artwork can draw. A collection of low-tops,
/// high-tops and runners reads as distinct pairs at a glance, instead of one
/// silhouette recoloured over and over.
enum SneakerSilhouette { lowTop, highTop, runner }

/// Picks a silhouette from a sneaker's model and name. High-top basketball
/// shoes and Chucks get the tall collar; Yeezys, Air Max and other runners
/// get the chunky-soled shape; everything else is a low-top.
SneakerSilhouette silhouetteFor(String model, String name) {
  final text = '$model $name'.toLowerCase();
  if (text.contains('high') ||
      text.contains('chuck') ||
      text.contains('mid')) {
    return SneakerSilhouette.highTop;
  }
  if (text.contains('yeezy') ||
      text.contains('boost') ||
      text.contains('air max') ||
      text.contains('mars yard') ||
      text.contains('vapormax') ||
      text.contains('vapor') ||
      text.contains('presto') ||
      text.contains('new balance') ||
      text.contains('990') ||
      text.contains('550') ||
      text.contains('runner')) {
    return SneakerSilhouette.runner;
  }
  return SneakerSilhouette.lowTop;
}

/// Draws a flat, stylised sneaker, coloured from the sneaker's colorway and
/// shaped from its model.
///
/// This is the app's stand-in for product photography. It ships no image
/// files, works fully offline, and gives every sneaker a distinct look
/// pulled from its real colorway (see [paletteFor]) and silhouette.
class SneakerArtwork extends StatelessWidget {
  const SneakerArtwork({
    super.key,
    required this.brand,
    required this.colorway,
    this.model = '',
    this.name = '',
    this.size = 64,
    this.borderRadius = 12,
  });

  final String brand;
  final String colorway;
  final String model;
  final String name;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        size: Size.square(size),
        painter: _SneakerPainter(
          paletteFor(brand, colorway),
          silhouetteFor(model, name),
        ),
      ),
    );
  }
}

/// Paints a sneaker in side profile. The sole and colour-blocking are shared;
/// the upper outline, collar and laces change with the [silhouette].
class _SneakerPainter extends CustomPainter {
  _SneakerPainter(this.palette, this.silhouette);

  final SneakerPalette palette;
  final SneakerSilhouette silhouette;

  bool get _isRunner => silhouette == SneakerSilhouette.runner;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    Offset at(double x, double y) => Offset(x * w, y * h);

    final fill = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // Background tile.
    fill.color = palette.background;
    canvas.drawRect(Offset.zero & size, fill);

    // ---- sole ------------------------------------------------------------
    // Runners ride on a chunkier midsole; low- and high-tops share a slim one.
    final outsole = _isRunner
        ? RRect.fromLTRBR(
            0.10 * w, 0.72 * h, 0.92 * w, 0.815 * h, Radius.circular(0.05 * w))
        : RRect.fromLTRBR(
            0.13 * w, 0.70 * h, 0.89 * w, 0.79 * h, Radius.circular(0.04 * w));
    fill.color = _darken(palette.sole, 0.22);
    canvas.drawRRect(outsole, fill);

    final midsole = _isRunner
        ? RRect.fromLTRBR(
            0.09 * w, 0.585 * h, 0.93 * w, 0.745 * h, Radius.circular(0.07 * w))
        : RRect.fromLTRBR(
            0.12 * w, 0.64 * h, 0.90 * w, 0.725 * h, Radius.circular(0.045 * w));
    fill.color = palette.sole;
    canvas.drawRRect(midsole, fill);
    canvas.drawRRect(
      midsole,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.012 * w
        ..color = _darken(palette.sole, 0.18),
    );

    // ---- upper -----------------------------------------------------------
    final upper = _buildUpper(w, h);
    fill.color = palette.upper;
    canvas.drawPath(upper, fill);

    // Coloured panels and laces, clipped so they stay inside the upper.
    canvas.save();
    canvas.clipPath(upper);
    _paintPanels(canvas, w, h, fill);
    _paintLaces(canvas, at, w);
    canvas.restore();

    // High-tops get an ankle-collar opening so the tall shape reads clearly.
    if (silhouette == SneakerSilhouette.highTop) {
      fill.color = _darken(palette.upper, 0.20);
      canvas.drawOval(
        Rect.fromCenter(
            center: at(0.34, 0.27), width: 0.20 * w, height: 0.16 * h),
        fill,
      );
    }

    // Crisp outline around the upper (helps light sneakers read).
    canvas.drawPath(
      upper,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.014 * w
        ..strokeJoin = StrokeJoin.round
        ..color = _darken(palette.upper, 0.16),
    );
  }

  /// The filled outline of the upper, in side profile, heel on the left.
  Path _buildUpper(double w, double h) {
    switch (silhouette) {
      case SneakerSilhouette.highTop:
        // A tall padded collar wrapping up around the ankle.
        return Path()
          ..moveTo(0.15 * w, 0.665 * h)
          ..lineTo(0.165 * w, 0.21 * h)
          ..quadraticBezierTo(0.19 * w, 0.12 * h, 0.30 * w, 0.135 * h)
          ..quadraticBezierTo(0.42 * w, 0.15 * h, 0.45 * w, 0.36 * h)
          ..quadraticBezierTo(0.465 * w, 0.41 * h, 0.51 * w, 0.41 * h)
          ..quadraticBezierTo(0.64 * w, 0.405 * h, 0.79 * w, 0.55 * h)
          ..quadraticBezierTo(0.90 * w, 0.605 * h, 0.85 * w, 0.665 * h)
          ..close();
      case SneakerSilhouette.runner:
        // A smooth, low, domed upper sitting on the chunky midsole.
        return Path()
          ..moveTo(0.13 * w, 0.62 * h)
          ..quadraticBezierTo(0.12 * w, 0.40 * h, 0.31 * w, 0.385 * h)
          ..quadraticBezierTo(0.52 * w, 0.36 * h, 0.69 * w, 0.45 * h)
          ..quadraticBezierTo(0.91 * w, 0.52 * h, 0.89 * w, 0.62 * h)
          ..close();
      case SneakerSilhouette.lowTop:
        // Heel wall, ankle-collar dip, instep and toe box.
        return Path()
          ..moveTo(0.15 * w, 0.665 * h)
          ..lineTo(0.205 * w, 0.42 * h)
          ..quadraticBezierTo(0.245 * w, 0.525 * h, 0.33 * w, 0.53 * h)
          ..quadraticBezierTo(0.405 * w, 0.53 * h, 0.45 * w, 0.405 * h)
          ..quadraticBezierTo(0.62 * w, 0.40 * h, 0.78 * w, 0.55 * h)
          ..quadraticBezierTo(0.895 * w, 0.605 * h, 0.85 * w, 0.665 * h)
          ..close();
    }
  }

  /// The accent-coloured colour-blocking: heel counter and toe cap.
  void _paintPanels(Canvas canvas, double w, double h, Paint fill) {
    fill.color = palette.accent;

    if (_isRunner) {
      // A heel clip at the back and a sweeping side panel.
      canvas.drawPath(
        Path()
          ..moveTo(0, 0.30 * h)
          ..lineTo(0, 0.66 * h)
          ..lineTo(0.18 * w, 0.66 * h)
          ..quadraticBezierTo(0.20 * w, 0.42 * h, 0.13 * w, 0.30 * h)
          ..close(),
        fill,
      );
      canvas.drawPath(
        Path()
          ..moveTo(0.40 * w, 0.70 * h)
          ..quadraticBezierTo(0.55 * w, 0.48 * h, 0.78 * w, 0.55 * h)
          ..quadraticBezierTo(0.66 * w, 0.62 * h, 0.62 * w, 0.70 * h)
          ..close(),
        fill,
      );
      return;
    }

    // Heel counter (back of the shoe). High-tops carry it up the collar.
    final heelTop = silhouette == SneakerSilhouette.highTop ? 0.14 : 0.28;
    canvas.drawPath(
      Path()
        ..moveTo(0, heelTop * h)
        ..lineTo(0, 0.72 * h)
        ..lineTo(0.22 * w, 0.72 * h)
        ..quadraticBezierTo(
            0.30 * w, 0.50 * h, 0.235 * w, heelTop * h)
        ..close(),
      fill,
    );

    // Toe cap (front of the shoe).
    canvas.drawPath(
      Path()
        ..moveTo(0.72 * w, 0.22 * h)
        ..quadraticBezierTo(0.595 * w, 0.52 * h, 0.685 * w, 0.74 * h)
        ..lineTo(1.02 * w, 0.74 * h)
        ..lineTo(1.02 * w, 0.22 * h)
        ..close(),
      fill,
    );
  }

  /// Laces across the instep. Runners get a short set; high-tops a tall set.
  void _paintLaces(Canvas canvas, Offset Function(double, double) at,
      double w) {
    final lace = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.032 * w
      ..color = palette.laces;

    switch (silhouette) {
      case SneakerSilhouette.highTop:
        for (var i = 0; i < 4; i++) {
          final x = 0.40 + i * 0.050;
          canvas.drawLine(at(x, 0.50), at(x + 0.05, 0.31), lace);
        }
      case SneakerSilhouette.runner:
        for (var i = 0; i < 2; i++) {
          final x = 0.40 + i * 0.060;
          canvas.drawLine(at(x, 0.50), at(x + 0.055, 0.41), lace);
        }
      case SneakerSilhouette.lowTop:
        for (var i = 0; i < 3; i++) {
          final x = 0.40 + i * 0.052;
          canvas.drawLine(at(x, 0.555), at(x + 0.05, 0.45), lace);
        }
    }
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(_SneakerPainter oldDelegate) =>
      oldDelegate.silhouette != silhouette ||
      oldDelegate.palette.upper != palette.upper ||
      oldDelegate.palette.sole != palette.sole ||
      oldDelegate.palette.accent != palette.accent ||
      oldDelegate.palette.background != palette.background;
}
