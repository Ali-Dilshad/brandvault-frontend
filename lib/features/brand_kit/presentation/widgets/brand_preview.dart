import 'package:flutter/material.dart';
import '../../../../utils/hex_color_parser.dart';
import '../../../../utils/validators.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/brand_model.dart';

class BrandPreview extends StatelessWidget{
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String? fontName;
  final String? logoUrl;

  const BrandPreview({
    super.key,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    this.fontName,
    this.logoUrl,
  });

  factory BrandPreview.fromBrand(BrandModel brand) => BrandPreview(
    name: brand.name,
    primaryColor: brand.primaryColor,
    secondaryColor: brand.secondaryColor,
    fontName: brand.fontName,
    logoUrl: brand.logoUrl,
  );

  @override
  Widget build(BuildContext context) {
    Color primary, secondary;
    try{
      primary = hexToColor(primaryColor);

    }catch (_){
      primary = AppColors.line;
    }
    try{
      secondary = hexToColor(secondaryColor);
    }catch (_){
      secondary = AppColors.ink;
    }

    final logo = logoUrl?.trim() ?? '';
    final showLogo = logo.isNotEmpty && Validators.httpUrl(logo) == null;

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [primary, secondary], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(10),
    ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            if (showLogo)
              Positioned(top: 0,right:0,
              child: Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.white,borderRadius: BorderRadius.circular(6)),
                child: Image.network(logo, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                name.isEmpty ? 'Your brand name?' : name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  fontFamily: fontName,
                ),
              ),
            )
          ],
        )
    );
  }
}
