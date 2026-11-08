class FavoriteModel {
  final String id;
  final String userId;
  final String tourId;
  final String addedAt;

  const FavoriteModel({
    required this.id,
    required this.userId,
    required this.tourId,
    required this.addedAt,
  });

  FavoriteModel copyWith({
    String? id,
    String? userId,
    String? tourId,
    String? addedAt,
  }) {
    return FavoriteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tourId: tourId ?? this.tourId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'tourId': tourId,
      'addedAt': addedAt,
    };
  }

  factory FavoriteModel.fromMap(Map<String, dynamic> map) {
    return FavoriteModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      tourId: map['tourId'] as String,
      addedAt: (map['addedAt'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }
}
