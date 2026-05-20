import 'package:flutter/material.dart';

import 'models/drop_alert.dart';

// SneakerBro's colours. Picked to feel like a tidy 2018-2022 mobile app:
// an ink-navy brand colour with a shoebox orange accent.
const Color kBrandColor = Color(0xFF22223B);
const Color kAccentColor = Color(0xFFE2563B);
const Color kSurfaceColor = Color(0xFFF4F4F6);
const Color kBorderColor = Color(0xFFE6E6EA);
const Color kMutedText = Color(0xFF6B6B72);

/// Soft elevation shared by the app's white cards. A hairline border plus a
/// faint shadow lifts a card off the grey background without looking heavy.
const List<BoxShadow> kCardShadow = [
  BoxShadow(
    color: Color(0x0F1B1B2E),
    blurRadius: 10,
    offset: Offset(0, 3),
  ),
];

/// The bundled sneaker prices are a saved snapshot from this year. The
/// original app pulled prices from a third-party sneaker API as deadstock
/// market values; the archive ships them frozen, the way the drop alerts
/// ship a saved feed. See the README.
const String kPriceSnapshot = '2022';

ThemeData buildSneakerBroTheme() {
  final base = ThemeData(
    useMaterial3: false,
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: kSurfaceColor,
  );
  return base.copyWith(
    primaryColor: kBrandColor,
    colorScheme: base.colorScheme.copyWith(
      primary: kBrandColor,
      secondary: kAccentColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: kBrandColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kAccentColor,
      foregroundColor: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrandColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ---- condition colours ---------------------------------------------------

Color conditionColor(String condition) {
  switch (condition) {
    case 'Deadstock':
      return const Color(0xFF2E7D32);
    case 'Like New':
      return const Color(0xFF388E3C);
    case 'Good':
      return const Color(0xFF1565C0);
    case 'Worn':
      return const Color(0xFFEF6C00);
    case 'Beat':
      return const Color(0xFFC62828);
    default:
      return kMutedText;
  }
}

Color conditionBg(String condition) {
  switch (condition) {
    case 'Deadstock':
      return const Color(0xFFE6F4E6);
    case 'Like New':
      return const Color(0xFFE8F5E9);
    case 'Good':
      return const Color(0xFFE3F0FB);
    case 'Worn':
      return const Color(0xFFFDECDC);
    case 'Beat':
      return const Color(0xFFFBE4E4);
    default:
      return const Color(0xFFEDEDEF);
  }
}

// ---- alert colours -------------------------------------------------------

Color alertColor(AlertType type) {
  switch (type) {
    case AlertType.newProduct:
      return const Color(0xFF2E7D32);
    case AlertType.restock:
      return const Color(0xFF1565C0);
    case AlertType.priceDrop:
      return const Color(0xFFEF6C00);
    case AlertType.unknown:
      return kMutedText;
  }
}

Color alertBg(AlertType type) {
  switch (type) {
    case AlertType.newProduct:
      return const Color(0xFFE6F4E6);
    case AlertType.restock:
      return const Color(0xFFE3F0FB);
    case AlertType.priceDrop:
      return const Color(0xFFFDECDC);
    case AlertType.unknown:
      return const Color(0xFFEDEDEF);
  }
}

IconData alertIcon(AlertType type) {
  switch (type) {
    case AlertType.newProduct:
      return Icons.fiber_new_outlined;
    case AlertType.restock:
      return Icons.inventory_outlined;
    case AlertType.priceDrop:
      return Icons.trending_down;
    case AlertType.unknown:
      return Icons.notifications_none;
  }
}
