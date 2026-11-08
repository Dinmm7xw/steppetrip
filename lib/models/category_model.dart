class CategoryModel {
  final String id;
  final String name;
  final String iconName;
  final int placesCount;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.iconName,
    this.placesCount = 0,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    String? iconName,
    int? placesCount,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      placesCount: placesCount ?? this.placesCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'placesCount': placesCount,
    };
  }

  /// REST API: Convert to JSON map
  Map<String, dynamic> toJson() => toMap();

  /// REST API: Create model from JSON map
  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel.fromMap(json);

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      iconName: (map['iconName'] as String?) ?? 'category',
      placesCount: (map['placesCount'] as num?)?.toInt() ?? 0,
    );
  }
}
