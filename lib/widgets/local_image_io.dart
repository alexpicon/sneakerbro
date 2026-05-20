import 'dart:io';

import 'package:flutter/material.dart';

/// Builds a rounded image widget for a local file [path], or returns null
/// when the path is empty or the file no longer exists (so the caller can
/// fall back to the drawn artwork).
Widget? localImage(
  String path, {
  required double size,
  required double borderRadius,
}) {
  if (path.isEmpty) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  return ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: Image.file(
      file,
      width: size,
      height: size,
      fit: BoxFit.cover,
    ),
  );
}
