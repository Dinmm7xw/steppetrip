import 'dart:convert';

class ReviewModel {
  final String id;
  final String tourId;
  final String userName;
  final int rating;
  final String comment;
  final String date;
  final List<String> tags;
  final String userAvatar;

  const ReviewModel({
    required this.id,
    required this.tourId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
    required this.tags,
    this.userAvatar = '',
  });

  ReviewModel copyWith({
    String? id,
    String? tourId,
    String? userName,
    int? rating,
    String? comment,
    String? date,
    List<String>? tags,
    String? userAvatar,
  }) {
    return ReviewModel(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tourId': tourId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': date,
      'tags': jsonEncode(tags),
      'userAvatar': userAvatar,
    };
  }

  /// REST API: Convert to JSON map (tags as List<String>)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tourId': tourId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'date': date,
      'tags': tags,
      'userAvatar': userAvatar,
    };
  }

  /// REST API: Create model from JSON map
  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel.fromMap(json);

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedTags = [];
    if (map['tags'] != null) {
      if (map['tags'] is String) {
        try {
          final decoded = jsonDecode(map['tags'] as String);
          if (decoded is List) {
            parsedTags = List<String>.from(decoded.map((e) => e.toString()));
          } else {
            parsedTags = (map['tags'] as String)
                .split(RegExp(r'[|,]'))
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } catch (_) {
          parsedTags = (map['tags'] as String)
              .split(RegExp(r'[|,]'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else if (map['tags'] is Iterable) {
        parsedTags =
            List<String>.from((map['tags'] as Iterable).map((e) => e.toString()));
      }
    }

    return ReviewModel(
      id: map['id'] as String,
      tourId: map['tourId'] as String,
      userName: map['userName'] as String,
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String,
      date: map['date'] as String,
      tags: parsedTags,
      userAvatar: (map['userAvatar'] as String?) ?? '',
    );
  }
}
