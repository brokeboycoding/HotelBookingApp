import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPopup extends StatefulWidget {
  final Function(DateTime start, DateTime end) onSelected;

  const CalendarPopup({super.key, required this.onSelected});

  @override
  State<CalendarPopup> createState() => _CalendarPopupState();
}

class _CalendarPopupState extends State<CalendarPopup>
    with SingleTickerProviderStateMixin {
  DateTime? startDate;
  DateTime? endDate;

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ⭐ Animation mở popup: scale + fade
    _controller =
        AnimationController(
            vsync: this, duration: const Duration(milliseconds: 220));

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0)
        .animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withValues(alpha: 0.32),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Container(
              width: 390,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _monthCalendar(DateTime.now()),
                      _monthCalendar(
                          DateTime.now().add(const Duration(days: 32))),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _actionButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ⭐ HEADER (cấp độ 4 – thêm icon + số đêm đẹp hơn)
  Widget _header() {
    String text = "Chọn ngày nhận phòng";

    if (startDate != null && endDate == null) {
      text = "Chọn ngày trả phòng";
    } else if (startDate != null && endDate != null) {
      int nights = endDate!.difference(startDate!).inDays;
      text =
      "${DateFormat('dd MMM', 'vi').format(startDate!)} → ${DateFormat(
          'dd MMM', 'vi').format(endDate!)} • $nights đêm";
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.calendar_month, color: Colors.blueAccent, size: 22),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // ⭐ BUTTON XÓA / ÁP DỤNG – VIP PRO
  Widget _actionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          child: const Text(
            "Xóa",
            style: TextStyle(
                color: Colors.red, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          onPressed: () {
            setState(() {
              startDate = null;
              endDate = null;
            });
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: (startDate != null && endDate != null)
              ? () {
            widget.onSelected(startDate!, endDate!);
            Navigator.pop(context);
          }
              : null,
          child: const Text(
            "Áp dụng",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  // ⭐ CALENDAR UI LEVEL 4 – full chuyên nghiệp
  Widget _monthCalendar(DateTime month) {
    DateTime first = DateTime(month.year, month.month, 1);
    int weekday = first.weekday;
    int days = DateTime(month.year, month.month + 1, 0).day;

    List<Widget> dayWidgets = [];

    // Padding đầu tháng
    for (int i = 1; i < weekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Các ngày thực sự
    for (int d = 1; d <= days; d++) {
      DateTime day = DateTime(month.year, month.month, d);

      bool isDisabled = day.isBefore(DateTime.now());
      bool isStart = startDate != null && day.isAtSameMomentAs(startDate!);
      bool isEnd = endDate != null && day.isAtSameMomentAs(endDate!);

      bool inRange = false;
      if (startDate != null && endDate != null) {
        inRange = day.isAfter(startDate!) && day.isBefore(endDate!);
      }

      Color bgColor = Colors.transparent;
      if (inRange) {
        bgColor = const Color(0xFF3FA9F5).withValues(alpha:0.18);
      }
      if (isStart || isEnd) {
        bgColor = Colors.blueAccent;
      }

      dayWidgets.add(
        GestureDetector(
          onTap: isDisabled
              ? null
              : () {
            setState(() {
              if (startDate == null || endDate != null) {
                startDate = day;
                endDate = null;
              } else {
                if (day.isAfter(startDate!)) {
                  endDate = day;
                } else {
                  startDate = day;
                  endDate = null;
                }
              }
            });
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(
                  isStart || isEnd ? 50 : 8,
                ),
                border: (isStart || isEnd)
                    ? Border.all(color: Colors.white, width: 2)
                    : null,
              ),
              alignment: Alignment.center,
              width: 40,
              height: 40,
              child: Text(
                d.toString(),
                style: TextStyle(
                  color: isDisabled
                      ? Colors.grey
                      : isStart || isEnd
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight
                      .normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // ⭐ TRẢ VỀ TOÀN BỘ LỊCH SAU KHI THÊM HẾT NGÀY
    return SizedBox(
      width: 170,
      child: Column(
        children: [
          Text(
            DateFormat("MMMM yyyy", "vi").format(month),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: dayWidgets,
          ),
        ],
      ),
    );
  }
}
