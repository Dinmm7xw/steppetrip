import 'dart:convert';

class TourPlace {
  final String id;
  final String name;
  final String region;
  final String category;
  final double rating;
  final int reviewsCount;
  final int pricePerPerson;
  final String description;
  final String imageUrl;
  final List<String> highlights;
  final String bestSeason;
  final bool isFavorite;

  const TourPlace({
    required this.id,
    required this.name,
    required this.region,
    required this.category,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerPerson,
    required this.description,
    required this.imageUrl,
    required this.highlights,
    required this.bestSeason,
    this.isFavorite = false,
  });

  TourPlace copyWith({
    String? id,
    String? name,
    String? region,
    String? category,
    double? rating,
    int? reviewsCount,
    int? pricePerPerson,
    String? description,
    String? imageUrl,
    List<String>? highlights,
    String? bestSeason,
    bool? isFavorite,
  }) {
    return TourPlace(
      id: id ?? this.id,
      name: name ?? this.name,
      region: region ?? this.region,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      pricePerPerson: pricePerPerson ?? this.pricePerPerson,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      highlights: highlights ?? this.highlights,
      bestSeason: bestSeason ?? this.bestSeason,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerPerson': pricePerPerson,
      'description': description,
      'imageUrl': imageUrl,
      'highlights': jsonEncode(highlights),
      'bestSeason': bestSeason,
      'isFavorite': isFavorite ? 1 : 0,
    };
  }

  /// REST API: Convert to JSON map (highlights as List<String>, isFavorite as bool)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'region': region,
      'category': category,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerPerson': pricePerPerson,
      'description': description,
      'imageUrl': imageUrl,
      'highlights': highlights,
      'bestSeason': bestSeason,
      'isFavorite': isFavorite,
    };
  }

  /// REST API: Create model from JSON map
  factory TourPlace.fromJson(Map<String, dynamic> json) => TourPlace.fromMap(json);

  factory TourPlace.fromMap(Map<String, dynamic> map) {
    List<String> parsedHighlights = [];
    if (map['highlights'] != null) {
      if (map['highlights'] is String) {
        try {
          final decoded = jsonDecode(map['highlights'] as String);
          if (decoded is List) {
            parsedHighlights = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            parsedHighlights = (map['highlights'] as String)
                .split(RegExp(r'[|,]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {
          parsedHighlights = (map['highlights'] as String)
              .split(RegExp(r'[|,]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (map['highlights'] is Iterable) {
        parsedHighlights =
            List<String>.from((map['highlights'] as Iterable).map((e) => e.toString()));
      }
    }

    return TourPlace(
      id: map['id'] as String,
      name: map['name'] as String,
      region: map['region'] as String,
      category: map['category'] as String,
      rating: (map['rating'] as num).toDouble(),
      reviewsCount: (map['reviewsCount'] as num).toInt(),
      pricePerPerson: (map['pricePerPerson'] as num).toInt(),
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String,
      highlights: parsedHighlights,
      bestSeason: map['bestSeason'] as String,
      isFavorite: map['isFavorite'] == 1 || map['isFavorite'] == true,
    );
  }
}
