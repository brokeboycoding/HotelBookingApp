import 'dart:async';

import 'package:booking_app/models/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/hotel_services.dart';
import '../services/cloudinary_service.dart'; // ✅ thêm để dùng CloudinaryBytesFile

class HotelProvider extends ChangeNotifier {
  final HotelService _hotelService = HotelService();

  // ✅ FIX: private fields có thể final (vì không gán lại list nữa)
  final List<HotelModel> _hotels = <HotelModel>[];
  final List<RoomModel> _rooms = <RoomModel>[];
  final List<ReviewModel> _reviews = <ReviewModel>[];

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _hotelsSubscription;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _reviewsSubscription;

  List<HotelModel> get hotels => _hotels;
  List<RoomModel> get rooms => _rooms;
  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    disposeListeners();
    super.dispose();
  }

  void disposeListeners() {
    _hotelsSubscription?.cancel();
    _roomsSubscription?.cancel();
    _reviewsSubscription?.cancel();
  }

  // ============================================================
  // HOTEL
  // ============================================================

  Future<bool> createHotel({
    required String ownerId,
    required String name,
    required String description,
    required String address,
    required GeoPoint location,
    required List<String> amenities,

    /// ✅ đổi File -> CloudinaryBytesFile
    required List<CloudinaryBytesFile> images,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.createHotel(
        ownerId: ownerId,
        name: name,
        description: description,
        address: address,
        location: location,
        amenities: amenities,

        // ✅ service đang nhận imageFiles: List<CloudinaryBytesFile>
        imageFiles: images,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHotel({
    required String hotelId,
    String? name,
    String? description,
    String? address,
    GeoPoint? location,
    List<String>? amenities,

    /// ✅ đổi File -> CloudinaryBytesFile
    List<CloudinaryBytesFile>? newImages,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.updateHotel(
        hotelId: hotelId,
        name: name,
        description: description,
        address: address,
        location: location,
        amenities: amenities,

        // ✅ service đang nhận newImages: List<CloudinaryBytesFile>?
        newImages: newImages,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<HotelModel?> getHotelById(String hotelId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      return await _hotelService.getHotelById(hotelId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteHotel(String hotelId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.deleteHotel(hotelId);

      // ✅ local update
      _hotels.removeWhere((h) => h.hotelId == hotelId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // ROOMS
  // ============================================================

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
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.createRoom(
        hotelId: hotelId,
        roomNumber: roomNumber,
        type: type,
        price: price,
        description: description,
        maxGuests: maxGuests,
        amenities: amenities,
        imageUrls: imageUrls,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
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
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.updateRoom(
        roomId: roomId,
        roomNumber: roomNumber,
        type: type,
        price: price,
        description: description,
        maxGuests: maxGuests,
        amenities: amenities,
        status: status,
        imageUrls: imageUrls,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ FIX: void -> Future<void> để await được
  Future<void> loadHotelRooms(String hotelId) async {
    _roomsSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    _roomsSubscription = _hotelService.getHotelRooms(hotelId).listen(
          (rooms) {
        _rooms
          ..clear()
          ..addAll(rooms);

        if (_isLoading) _isLoading = false;
        notifyListeners();

        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();

        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _isLoading = false;
        _errorMessage ??= 'Tải danh sách phòng quá lâu, vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  Future<bool> deleteRoom(String roomId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.deleteRoom(roomId);

      _rooms.removeWhere((r) => r.roomId == roomId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ============================================================
  // REVIEWS
  // ============================================================

  Future<void> loadHotelReviews(String hotelId) async {
    _reviewsSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    _reviewsSubscription = _hotelService.getHotelReviews(hotelId).listen(
          (reviews) {
        _reviews
          ..clear()
          ..addAll(reviews);

        if (_isLoading) _isLoading = false;
        notifyListeners();

        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();

        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _isLoading = false;
        _errorMessage ??= 'Tải đánh giá quá lâu, vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  Future<void> addReview({
    required String roomId,
    required String hotelId,
    required double rating,
    required String comment,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.addReview(
        roomId: roomId,
        userId: 'mock_user_id',
        userName: 'Mock User',
        userAvatarUrl: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // ADMIN
  // ============================================================

  Future<void> loadPendingRooms() async {
    _roomsSubscription?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final completer = Completer<void>();

    _roomsSubscription = _hotelService.getPendingRooms().listen(
          (rooms) {
        _rooms
          ..clear()
          ..addAll(rooms);

        if (_isLoading) _isLoading = false;
        notifyListeners();

        if (!completer.isCompleted) completer.complete();
      },
      onError: (e) {
        _isLoading = false;
        _errorMessage = e.toString();
        notifyListeners();

        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        _isLoading = false;
        _errorMessage ??= 'Tải phòng chờ duyệt quá lâu, vui lòng thử lại.';
        notifyListeners();
      },
    );
  }

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.updateRoomStatus(roomId, status);
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<RoomModel>> searchRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    String? hotelId,
  }) async {
    try {
      return await _hotelService.searchAvailableRooms(
        checkIn: checkIn,
        checkOut: checkOut,
        hotelId: hotelId,
      );
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<void> fetchAllRooms() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final allRooms = await _hotelService.fetchAllRooms();
      _rooms
        ..clear()
        ..addAll(allRooms);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // UTILS
  // ============================================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
