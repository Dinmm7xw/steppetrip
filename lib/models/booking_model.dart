enum BookingStatus { pending, confirmed, cancelled, completed }

class BookingModel {
  final String id;
  final String tourId;
  final String tourName;
  final String date;
  final int peopleCount;
  final int totalPrice;
  final BookingStatus status;
  final String clientName;
  final String clientPhone;
  final String notes;

  const BookingModel({
    required this.id,
    required this.tourId,
    required this.tourName,
    required this.date,
    required this.peopleCount,
    required this.totalPrice,
    required this.status,
    required this.clientName,
    required this.clientPhone,
    this.notes = '',
  });

  BookingModel copyWith({
    String? id,
    String? tourId,
    String? tourName,
    String? date,
    int? peopleCount,
    int? totalPrice,
    BookingStatus? status,
    String? clientName,
    String? clientPhone,
    String? notes,
  }) {
    return BookingModel(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      tourName: tourName ?? this.tourName,
      date: date ?? this.date,
      peopleCount: peopleCount ?? this.peopleCount,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tourId': tourId,
      'tourName': tourName,
      'date': date,
      'peopleCount': peopleCount,
      'totalPrice': totalPrice,
      'status': status.name,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'notes': notes,
    };
  }

  /// REST API: Convert to JSON map
  Map<String, dynamic> toJson() => toMap();

  /// REST API: Create model from JSON map
  factory BookingModel.fromJson(Map<String, dynamic> json) => BookingModel.fromMap(json);

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    BookingStatus parseStatus(String? val) {
      switch (val) {
        case 'confirmed':
          return BookingStatus.confirmed;
        case 'cancelled':
          return BookingStatus.cancelled;
        case 'completed':
          return BookingStatus.completed;
        case 'pending':
        default:
          return BookingStatus.pending;
      }
    }

    return BookingModel(
      id: map['id'] as String,
      tourId: map['tourId'] as String,
      tourName: map['tourName'] as String,
      date: map['date'] as String,
      peopleCount: (map['peopleCount'] as num).toInt(),
      totalPrice: (map['totalPrice'] as num).toInt(),
      status: parseStatus(map['status'] as String?),
      clientName: map['clientName'] as String,
      clientPhone: map['clientPhone'] as String,
      notes: (map['notes'] as String?) ?? '',
    );
  }
}
