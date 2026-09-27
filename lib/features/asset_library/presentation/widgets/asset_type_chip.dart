import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/asset_model.dart';


String assetTypeGlyph(AssetType type) {
  switch (type) {
    case AssetType.image:
      return '🖼';
    case AssetType.video:
      return '▶';
    case AssetType.logo:
      return '◆';
    case AssetType.font:
      return 'A';
    case AssetType.document:
      return '📄';
  }
}

class AssetTypeChip extends StatelessWidget {
  final AssetType type;
  final double size;

  const AssetTypeChip({super.key, required this.type, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(6)),
      child: Text(assetTypeGlyph(type), style: TextStyle(fontSize: size * 0.42, color: AppColors.inkSoft)),
    );
  }
}