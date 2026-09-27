import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/brand_model.dart';

/// A compact, read-only card for the dashboard's right-hand panel — the
/// brand name, font, and the two required colors as swatches with their
/// hex value printed on top. Tapping it opens the full editor.
class BrandKitSummaryCard extends StatelessWidget {
  final BrandModel? brand;
  final VoidCallback onEdit;

  const BrandKitSummaryCard({super.key, required this.brand, required this.onEdit});

  Color _safeColor(String hex, Color fallback) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = this.brand;

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paperRaised,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: brand == null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('No brand kit yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            SizedBox(height: 4),
            Text('Tap to set your colors, logo and font.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(brand.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(
              brand.fontName == null || brand.fontName!.isEmpty ? 'No font set' : 'Font — ${brand.fontName}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _swatch(brand.primaryColor, AppColors.accent)),
                const SizedBox(width: 8),
                Expanded(child: _swatch(brand.secondaryColor, AppColors.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(String hex, Color fallback) => Container(
    height: 44,
    alignment: Alignment.bottomLeft,
    padding: const EdgeInsets.all(6),
    decoration: BoxDecoration(color: _safeColor(hex, fallback), borderRadius: BorderRadius.circular(6)),
    child: Text(hex, style: const TextStyle(fontSize: 10.5, color: Colors.white, fontFamily: 'monospace')),
  );
}
