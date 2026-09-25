import 'package:flutter/material.dart';

Color hexToColor(String hex) {
  final clean = hex.trim().replaceAll('#', '');

  if (!isValidHex(clean)) {
    throw FormatException('Invalid hex color: $hex');
  }

  final color = clean.length == 6 ? 'FF$clean' : clean;
  return Color(int.parse(color, radix: 16));
}

bool isValidHex(String value) {
  final clean = value.trim().replaceAll('#', '');

  return RegExp(r'^[0-9A-Fa-f]{6}$|^[0-9A-Fa-f]{8}$')
      .hasMatch(clean);
}

String normalizeHex(String value) => '#${value.trim().replaceAll('#', '').toUpperCase()}';