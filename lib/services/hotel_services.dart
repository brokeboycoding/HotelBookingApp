import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/hotel_model.dart';
import '../models/review_model.dart';
import '../models/room_model.dart';
import 'firebase_services.dart';

class HotelService {
  final FirebaseService _firebaseService = FirebaseService();

  // HOTEL SERVICES

  Future<String> _uploadImage(String hotelId, File imageFile) async {
    String fileName =
        'hotel_${hotelId}_${DateTime.now().millisecondsSinceEpoch}';
    Reference ref = _firebaseService.storage
        .ref()
        .child('hotel_images')
        .child(fileName);
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> createHotel({
    required String ownerId,
    required String name,
    required String description,
    required String address,
    required GeoPoint location,
    required List<String> amenities,
    required List<File> imageFiles,
  }) async {
    try {
      DocumentReference hotelRef = await _firebaseService.hotelsCollection.add(
        null,
      );

      List<String> imageUrls = [];
      for (var imageFile in imageFiles) {
        String url = await _uploadImage(hotelRef.id, imageFile);
        imageUrls.add(url);
      }

      HotelModel newHotel = HotelModel(
        hotelId: hotelRef.id,
        ownerId: ownerId,
        name: name,
        description: description,
        address: address,
        location: location,
        amenities: amenities,
        images: imageUrls,
        rating: 0,
        createdAt: DateTime.now(),
      );

      await hotelRef.set(newHotel.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<HotelModel>> getOwnerHotels(String ownerId) {
    return _firebaseService.hotelsCollection
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => HotelModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> updateHotel({
    required String hotelId,
    String? name,
    String? description,
    String? address,
    GeoPoint? location,
    List<String>? amenities,
    List<File>? newImages,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (address != null) updates['address'] = address;
      if (location != null) updates['location'] = location;
      if (amenities != null) updates['amenities'] = amenities;

      if (newImages != null && newImages.isNotEmpty) {
        List<String> newImageUrls = [];
        for (var imageFile in newImages) {
          String url = await _uploadImage(hotelId, imageFile);
          newImageUrls.add(url);
        }
        updates['imageUrls'] = FieldValue.arrayUnion(newImageUrls);
      }

      await _firebaseService.hotelsCollection.doc(hotelId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteHotel(String hotelId) async {
    try {
      await _firebaseService.hotelsCollection.doc(hotelId).delete();
      // Also delete rooms associated with the hotel
      QuerySnapshot roomsSnapshot = await _firebaseService.roomsCollection
          .where('hotelId', isEqualTo: hotelId)
          .get();
      for (var doc in roomsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<HotelModel?> getHotelById(String hotelId) async {
    try {
      DocumentSnapshot doc =
          await _firebaseService.hotelsCollection.doc(hotelId).get();
      if (doc.exists) {
        return HotelModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // ROOM SERVICES

  Future<void> createRoom({
    required String hotelId,
    required String roomNumber,
    required String type,
    required double price,
    required String description,
    required int maxGuests,
    required List<String> amenities,
    required List<String> imageUrls,
  }) async {
    try {
      DocumentReference roomRef = _firebaseService.roomsCollection.doc();

      RoomModel newRoom = RoomModel(
        roomId: roomRef.id,
        hotelId: hotelId,
        roomNumber: roomNumber,
        type: type,
        price: price,
        description: description,
        images: imageUrls,
        maxGuests: maxGuests,
        amenities: amenities,
        createdAt: DateTime.now(),
      );

      await roomRef.set(newRoom.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<RoomModel>> getHotelRooms(String hotelId) {
    return _firebaseService.roomsCollection
        .where('hotelId', isEqualTo: hotelId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<RoomModel?> getRoomById(String roomId) async {
    try {
      DocumentSnapshot doc = await _firebaseService.roomsCollection
          .doc(roomId)
          .get();
      if (doc.exists) {
        return RoomModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRoom({
    required String roomId,
    String? roomNumber,
    String? type,
    double? price,
    String? description,
    int? maxGuests,
    List<String>? amenities,
    RoomStatus? status,
    List<String>? imageUrls,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (roomNumber != null) updates['roomNumber'] = roomNumber;
      if (type != null) updates['type'] = type;
      if (price != null) updates['price'] = price;
      if (description != null) updates['description'] = description;
      if (maxGuests != null) updates['maxGuests'] = maxGuests;
      if (amenities != null) updates['amenities'] = amenities;
      if (status != null) updates['status'] = status.name;
      if (imageUrls != null) updates['images'] = imageUrls;

      await _firebaseService.roomsCollection.doc(roomId).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      await _firebaseService.roomsCollection.doc(roomId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ReviewModel>> getHotelReviews(String hotelId) {
    return _firebaseService.roomsCollection
        .where('hotelId', isEqualTo: hotelId)
        .snapshots()
        .asyncMap((roomSnapshot) async {
          List<ReviewModel> reviews = [];
          for (var roomDoc in roomSnapshot.docs) {
            QuerySnapshot reviewSnapshot = await _firebaseService
                .reviewsCollection
                .where('roomId', isEqualTo: roomDoc.id)
                .get();
            reviews.addAll(
              reviewSnapshot.docs
                  .map((doc) => ReviewModel.fromFirestore(doc))
                  .toList(),
            );
          }
          return reviews;
        });
  }

  Future<List<RoomModel>> searchAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    String? hotelId,
  }) async {
    // 1. Find all bookings that overlap with the selected date range
    QuerySnapshot bookingSnapshot = await _firebaseService.bookingsCollection
        .where('checkInDate', isLessThan: checkOut)
        .where('checkOutDate', isGreaterThan: checkIn)
        .get();

    List<String> unavailableRoomIds = bookingSnapshot.docs
        .map((doc) => doc['roomId'] as String)
        .toList();

    // 2. Fetch all rooms (or rooms for a specific hotel)
    Query query = _firebaseService.roomsCollection;
    if (hotelId != null) {
      query = query.where('hotelId', isEqualTo: hotelId);
    }

    QuerySnapshot roomSnapshot = await query.get();

    // 3. Filter out the unavailable rooms
    List<RoomModel> allRooms = roomSnapshot.docs
        .map((doc) => RoomModel.fromFirestore(doc))
        .toList();

    allRooms.removeWhere((room) => unavailableRoomIds.contains(room.roomId));

    return allRooms;
  }

  Future<List<RoomModel>> fetchAllRooms() async {
    try {
      QuerySnapshot snapshot = await _firebaseService.roomsCollection.get();
      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    } catch (e) {
      rethrow;
    }
  }

  // ADMIN-SPECIFIC METHODS

  Stream<List<RoomModel>> getPendingRooms() {
    return _firebaseService.roomsCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      await _firebaseService.roomsCollection.doc(roomId).update({
        'status': status.name,
      });
    } catch (e) {
      rethrow;
    }
  }

  // REVIEW SERVICES

  Future<void> addReview({
    required String roomId,
    required String userId,
    required String userName,
    required String userAvatarUrl,
    required double rating,
    required String comment,
  }) async {
    try {
      DocumentReference reviewRef = _firebaseService.reviewsCollection.doc();
      ReviewModel newReview = ReviewModel(
        reviewId: reviewRef.id,
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        roomId: roomId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );
      await reviewRef.set(newReview.toMap());
    } catch (e) {
      rethrow;
    }
  }
}
