import 'dart:async';
import 'package:booking_app/models/review_model.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/hotel_services.dart';

class HotelProvider extends ChangeNotifier {
  final HotelService _hotelService = HotelService();

  List<HotelModel> _hotels = [];
  List<RoomModel> _rooms = [];
  List<ReviewModel> _reviews = [];
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

  // Tạo khách sạn mới
  Future<bool> createHotel({
    required String ownerId,
    required String name,
    required String description,
    required String address,
    required GeoPoint location,
    required List<String> amenities,
    required List<File> images,
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

  // Tạo phòng mới
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

  // ... (other methods remain the same) ...

  // Cập nhật phòng
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

  // Load phòng của khách sạn

  void loadHotelRooms(String hotelId) {
    _roomsSubscription?.cancel();

    _roomsSubscription = _hotelService.getHotelRooms(hotelId).listen((rooms) {
      _rooms = rooms;

      notifyListeners();
    });
  }

  // Load reviews của khách sạn

  void loadHotelReviews(String hotelId) {
    _reviewsSubscription?.cancel();

    _reviewsSubscription = _hotelService.getHotelReviews(hotelId).listen((reviews) {
      _reviews = reviews;
      notifyListeners();
    });
  }

  // ADMIN METHODS
  void loadPendingRooms() {
    _roomsSubscription?.cancel();
    _roomsSubscription = _hotelService.getPendingRooms().listen((rooms) {
      _rooms = rooms;
      notifyListeners();
    });
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

  // Cập nhật khách sạn
  Future<bool> updateHotel({
    required String hotelId,
    String? name,
    String? description,
    String? address,
    GeoPoint? location,
    List<String>? amenities,
    List<File>? newImages,
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
      // notifyListeners(); // Removed
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

  // Xóa khách sạn
  Future<bool> deleteHotel(String hotelId) async {
    try {
      _isLoading = true;

      _errorMessage = null;

      notifyListeners();

      await _hotelService.deleteHotel(hotelId);

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

  // Xóa phòng
  Future<bool> deleteRoom(String roomId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _hotelService.deleteRoom(roomId);

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

  // Tìm kiếm phòng
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Fetch all rooms for search screen
  Future<void> fetchAllRooms() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      _rooms = await _hotelService.fetchAllRooms();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      // In a real app, get user details from AuthProvider
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
}
