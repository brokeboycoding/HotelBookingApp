import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/report_model.dart';
import '../services/report_services.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _reportService = ReportService();

  List<ReportModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _reportsSubscription;

  List<ReportModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    disposeListeners();
    super.dispose();
  }

  void disposeListeners() {
    _reportsSubscription?.cancel();
  }

  void loadReports() {
    _isLoading = true;
    notifyListeners();
    _reportsSubscription?.cancel();
    _reportsSubscription = _reportService.getReports().listen((reports) {
      _reports = reports;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateReportStatus(String reportId, ReportStatus status) async {
    try {
      await _reportService.updateReportStatus(reportId, status);
      // The stream will automatically update the list
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addReport({
    required String hotelId,
    String? roomId,
    required String reason,
    required String description,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
      // In a real app, get user details from AuthProvider
      await _reportService.addReport(
        reporterUserId: 'mock_user_id',
        reportedHotelId: hotelId,
        reportedRoomId: roomId,
        reason: reason,
        description: description,
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
