import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { pending, available, booked, maintenance, rejected }

class RoomModel {
  final String roomId;
  final String hotelId;
  final String roomNumber;
  final String type;
  final double price;
  final String description;
  final List<String> images;
  final int maxGuests;
  final List<String> amenities;
  final RoomStatus status;
  final DateTime createdAt;

  RoomModel({
    required this.roomId,
    required this.hotelId,
    required this.roomNumber,
    required this.type,
    required this.price,
    required this.description,
    required this.images,
    required this.maxGuests,
    required this.amenities,
    this.status = RoomStatus.pending, // Default to pending
    required this.createdAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      roomId: doc.id,
      hotelId: data['hotelId'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      maxGuests: data['maxGuests'] ?? 1,
      amenities: List<String>.from(data['amenities'] ?? []),
      status: _stringToStatus(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hotelId': hotelId,
      'roomNumber': roomNumber,
      'type': type,
      'price': price,
      'description': description,
      'images': images,
      'maxGuests': maxGuests,
      'amenities': amenities,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static RoomStatus _stringToStatus(String statusStr) {
    switch (statusStr) {
      case 'available':
        return RoomStatus.available;
      case 'booked':
        return RoomStatus.booked;
      case 'maintenance':
        return RoomStatus.maintenance;
      case 'rejected':
        return RoomStatus.rejected;
      default:
        return RoomStatus.pending;
    }
  }

  RoomModel copyWith({
    String? roomId,
    String? hotelId,
    String? roomNumber,
    String? type,
    double? price,
    String? description,
    List<String>? images,
    int? maxGuests,
    List<String>? amenities,
    RoomStatus? status,
    DateTime? createdAt,
  }) {
    return RoomModel(
      roomId: roomId ?? this.roomId,
      hotelId: hotelId ?? this.hotelId,
      roomNumber: roomNumber ?? this.roomNumber,
      type: type ?? this.type,
      price: price ?? this.price,
      description: description ?? this.description,
      images: images ?? this.images,
      maxGuests: maxGuests ?? this.maxGuests,
      amenities: amenities ?? this.amenities,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
