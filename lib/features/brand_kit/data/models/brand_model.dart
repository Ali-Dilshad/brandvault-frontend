class BrandModel {
  final String? id;
  final String name;
  final String primaryColor;
  final String secondaryColor;
  final String? logoUrl;
  final String? fontName;

  BrandModel({
    this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
    this.fontName
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) => BrandModel(
      id: json['id'],
      name: json['name'],
      primaryColor: json['primaryColor'],
      secondaryColor: json['secondaryColor'],
      logoUrl: json['logoUrl'],
      fontName: json['fontName'],
  );
  BrandModel withId(String newId) => BrandModel(
      id: newId,
      name: name,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      logoUrl: logoUrl,
      fontName: fontName,
  );

  Map<String, dynamic> toJson({bool includeNulls = false}) =>{
    'name':name,
    'primaryColor': primaryColor,
    'secondaryColor':secondaryColor,
    if (includeNulls || logoUrl != null) 'logoUrl' : logoUrl,
    if (includeNulls || fontName != null ) 'fontName': fontName,

  };
}