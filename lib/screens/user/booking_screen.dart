import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/room_model.dart';
import '../../providers/booking_providers.dart';
import '../../providers/auth_providers.dart';

class BookingScreen extends StatefulWidget {
  final RoomModel room;

  const BookingScreen({Key? key, required this.room}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final String hotelName = "Khách sạn ABC"; // Hardcoded hotel name
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  final _notesController = TextEditingController();
  String _selectedPayment = 'Credit Card';

  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'E-Wallet',
    'Cash',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isCheckIn
              ? _checkInDate
              : _checkOutDate ?? _checkInDate?.add(const Duration(days: 1))) ??
          DateTime.now().add(const Duration(days: 1)),
      firstDate:
          isCheckIn ? DateTime.now() : _checkInDate!.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.secondary,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate != null && !_checkOutDate!.isAfter(_checkInDate!)) {
            _checkOutDate = null;
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  int get numberOfNights {
    if (_checkInDate == null || _checkOutDate == null) return 0;
    final nights = _checkOutDate!.difference(_checkInDate!).inDays;
    return nights > 0 ? nights : 0;
  }

  double get totalPrice {
    return widget.room.price * numberOfNights;
  }

  Future<void> _handleBooking() async {
    if (_checkInDate == null || _checkOutDate == null || numberOfNights <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select valid check-in and check-out dates.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    try {
      String? bookingId = await bookingProvider.createBooking(
        userId: authProvider.currentUser!.uid,
        hotelId: widget.room.hotelId,
        roomId: widget.room.roomId,
        checkInDate: _checkInDate!,
        checkOutDate: _checkOutDate!,
        notes: _notesController.text.trim(),
      );

      if (!mounted || bookingId == null) return;

      bool paymentSuccess = await bookingProvider.makePayment(
        bookingId: bookingId,
        paymentMethod: _selectedPayment,
      );

      if (!mounted) return;

      if (paymentSuccess) {
        _showSuccessDialog();
      } else {
        throw Exception(bookingProvider.errorMessage ?? 'Payment failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Booking Successful!'),
        content: const Text(
            'Your booking has been confirmed. Please check your email for details.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/my-bookings', (Route<dynamic> route) => route.isFirst);
            },
            child: const Text('View My Bookings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, yyyy');
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Booking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRoomInfo(theme),
            const SizedBox(height: 24),
            _buildDateSelection(context, dateFormat),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Special requests...', 
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedPayment,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPayment = value!;
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildPriceSummary(theme),
    );
  }

  Widget _buildRoomInfo(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(widget.room.images.first),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hotelName,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                widget.room.type,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDateSelection(BuildContext context, DateFormat dateFormat) {
    return Row(
      children: [
        Expanded(
          child: _buildDateChip(
            context: context,
            label: 'Check-in',
            date: _checkInDate,
            onTap: () => _selectDate(context, true),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Icon(Icons.arrow_forward),
        ),
        Expanded(
          child: _buildDateChip(
            context: context,
            label: 'Check-out',
            date: _checkOutDate,
            onTap: () => _selectDate(context, false),
          ),
        ),
      ],
    );
  }

  Widget _buildDateChip({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              date == null ? 'Select Date' : DateFormat('dd MMM').format(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary(ThemeData theme) {
    final currencyFormatter = NumberFormat('#,###', 'vi_VN');
    return Container(
      padding: const EdgeInsets.all(20).copyWith(top: 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ($numberOfNights nights)',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                '${currencyFormatter.format(totalPrice)} VNĐ',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Consumer<BookingProvider>(
              builder: (context, bookingProvider, _) => ElevatedButton(
                onPressed: bookingProvider.isLoading || numberOfNights <= 0
                    ? null
                    : _handleBooking,
                child: bookingProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text('Confirm & Book'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
