import 'package:flutter/material.dart';

/// The set of colours used to draw a sneaker's artwork. It is derived from
/// the sneaker's real colorway, so "Black/Red" gives a black upper with a
/// red accent, "University Blue/White" gives a blue upper, and so on.
class SneakerPalette {
  const SneakerPalette({
    required this.background,
    required this.upper,
    required this.sole,
    required this.accent,
    required this.laces,
  });

  final Color background;
  final Color upper;
  final Color sole;
  final Color accent;
  final Color laces;
}

// Colour words recognised inside a colorway string.
const Map<String, Color> _colorWords = {
  'black': Color(0xFF2C2C30),
  'white': Color(0xFFF1F1EE),
  'cream': Color(0xFFE8DCC0),
  'sail': Color(0xFFE8DCC0),
  'red': Color(0xFFC23A33),
  'infrared': Color(0xFFE0483B),
  'royal': Color(0xFF2447A8),
  'navy': Color(0xFF26304F),
  'blue': Color(0xFF3A6FB0),
  'green': Color(0xFF2F7D4F),
  'teal': Color(0xFF2E8B86),
  'orange': Color(0xFFE07C30),
  'yellow': Color(0xFFE6B23C),
  'gold': Color(0xFFC6A24A),
  'brown': Color(0xFF7C5740),
  'tan': Color(0xFFC6A57C),
  'grey': Color(0xFF9B9BA2),
  'gray': Color(0xFF9B9BA2),
  'silver': Color(0xFFC9C9D0),
  'pink': Color(0xFFDBA1B0),
  'purple': Color(0xFF6B4C93),
};

// Famous colorway nicknames that carry no plain colour word. Each maps to
// the colour words it stands for, in front-to-back order. "Bred" is black
// and red, a "Panda" Dunk is white and black, and so on. Without this a
// nickname colorway would fall back to a flat brand colour.
const Map<String, String> _colorwayAliases = {
  'bred': 'black red',
  'banned': 'black red',
  'panda': 'white black',
  'oreo': 'white black',
  'zebra': 'white black',
  'beluga': 'grey orange',
  'mocha': 'brown',
  'chicago': 'red white',
  'unc': 'blue white',
  'maple': 'tan',
  'multicolor': 'teal pink',
};

// Fallback colour per brand, used when a colorway has no recognised words.
const Map<String, Color> _brandColors = {
  'nike': Color(0xFF3C4250),
  'jordan': Color(0xFF8E2C36),
  'adidas': Color(0xFF3A4654),
  'new balance': Color(0xFF6E7480),
  'converse': Color(0xFF2C2C30),
  'vans': Color(0xFF2C2C30),
};

const Color _defaultSole = Color(0xFFEAE8E2);

bool _isLight(Color c) => c.computeLuminance() > 0.55;

/// A tonal sibling of [c]: darker if [c] is light, lighter if it is dark.
/// Used as the accent for single-colour (monochrome) sneakers.
Color _shade(Color c) {
  final hsl = HSLColor.fromColor(c);
  final lightness =
      _isLight(c) ? hsl.lightness - 0.18 : hsl.lightness + 0.16;
  return hsl.withLightness(lightness.clamp(0.0, 1.0)).toColor();
}

/// A pale wash of the upper colour, used as the artwork's background tile.
Color _backgroundFor(Color upper) {
  final hsl = HSLColor.fromColor(upper);
  return HSLColor.fromAHSL(
    1,
    hsl.hue,
    (hsl.saturation * 0.5).clamp(0.0, 0.32),
    0.93,
  ).toColor();
}

/// Builds a [SneakerPalette] from a sneaker's brand and colorway.
SneakerPalette paletteFor(String brand, String colorway) {
  var normalized = colorway.toLowerCase();
  // Expand nickname colorways into plain colour words, in place, so a
  // "Bred" reads as "black red" and keeps its front-to-back order.
  _colorwayAliases.forEach((alias, expansion) {
    normalized = normalized.replaceAll(alias, ' $expansion ');
  });

  final tokens = normalized.split(RegExp('[^a-z]+'));
  final colors = <Color>[];
  for (final token in tokens) {
    final color = _colorWords[token];
    if (color != null && !colors.contains(color)) {
      colors.add(color);
    }
  }
  if (colors.isEmpty) {
    colors.add(_brandColors[brand.toLowerCase()] ?? const Color(0xFF50555F));
  }

  final upper = colors[0];
  final accent = colors.length > 1 ? colors[1] : _shade(upper);
  // Soles are kept a consistent light colour: it is the most common real
  // sneaker sole and avoids a dark colorway making the shoe look boxed in.
  const sole = _defaultSole;
  final laces =
      _isLight(upper) ? const Color(0xFF3A3A3E) : const Color(0xFFF0F0EC);

  return SneakerPalette(
    background: _backgroundFor(upper),
    upper: upper,
    sole: sole,
    accent: accent,
    laces: laces,
  );
}
