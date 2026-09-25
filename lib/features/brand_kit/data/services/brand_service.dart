import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/endpoints.dart';
import '../../../../utils/hex_color_parser.dart';
import '../../../../utils/validators.dart';
import '../models/brand_model.dart';


class BrandService {
  BrandModel? _mockBrand = BrandModel(
      id: 'brand-1',
      name: 'Nordwind Coffee',
      primaryColor: '#5B4FE8',
      secondaryColor: '#1C1F22',
      fontName: 'Söhne',
  );

  Future<BrandModel?> getBrand() async {
    if (AppApiClient.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockBrand;
    }
    try {
      final json = await AppApiClient.get(Endpoints.brand);
      return json == null ? null : BrandModel.fromJson(json);
    } on AppException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
  Future<BrandModel> saveBrand(BrandModel input) async {
    final brand = BrandModel(
      id: input.id,
      name: input.name.trim(),
      primaryColor: isValidHex(input.primaryColor) ? normalizeHex(input.primaryColor) : input.primaryColor,
      secondaryColor: isValidHex(input.secondaryColor) ? normalizeHex(input.secondaryColor) : input.secondaryColor,
      logoUrl: _blankToNull(input.logoUrl),
      fontName: _blankToNull(input.fontName),
    );
    _validate(brand);

    if (AppApiClient.useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      _mockBrand = brand.id == null ? brand.withId('brand-1') : brand;
      return _mockBrand!;
    }

    final json = brand.id == null
        ? await AppApiClient.post(Endpoints.brand, body: brand.toJson())
        : await AppApiClient.patch(Endpoints.brand, body: brand.toJson(includeNulls: true));
    return BrandModel.fromJson(json);
  }
  String? _blankToNull(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

  void _validate(BrandModel brand) {
    if (brand.name.isEmpty) {
      throw ArgumentError('Brand name is required');
    }
    if (!isValidHex(brand.primaryColor)) {
      throw ArgumentError('Primary color must be a hex value like #5B4FE8');
    }
    if (!isValidHex(brand.secondaryColor)) {
      throw ArgumentError('Secondary color must be a hex value like #1C1F22');
    }
    final logoError = Validators.httpUrl(
        brand.logoUrl, required: false, label: 'Logo URL');
    if (logoError != null) throw ArgumentError(logoError);
  }
}

