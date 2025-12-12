import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../login/login_screen.dart';
import '../login/register_screen.dart';

// ⭐ IMPORT popup lịch mini
import '../../widgets/calendar_popup.dart';

class HomeBeforeLogin extends StatefulWidget {
  const HomeBeforeLogin({super.key});

  @override
  State<HomeBeforeLogin> createState() => _HomeBeforeLoginState();
}

class _HomeBeforeLoginState extends State<HomeBeforeLogin> {
  final TextEditingController location =
  TextEditingController(text: "Việt Nam");

  DateTime? checkIn;
  DateTime? checkOut;

  int adults = 2;
  int children = 0;
  int rooms = 1;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 600;
    final double maxWidth = isMobile ? size.width : 700;

    return Scaffold(
      backgroundColor: Colors.white,
      // Cho phép nền tràn sau app bar nếu sau này dùng AppBar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // NỀN ẢNH
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg_forest.png",
              fit: BoxFit.cover,
            ),
          ),

          // LỚP GRADIENT TỐI
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.75),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),

          // ⭐ NỘI DUNG CHÍNH (đặt TRƯỚC để không che header)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(height: isMobile ? 120 : 150),

                    Text(
                      "Trải nghiệm kỳ nghỉ tuyệt vời",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 28 : 34,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 10),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "Khách sạn – Resort – Villa – Combo du lịch giá tốt nhất",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 30),

                    _searchBox(isMobile: isMobile),

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          ),

          // ⭐ THANH TRÊN: LOGO + LOGIN / REGISTER (đặt CUỐI để nằm TRÊN cùng)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "QuanLiDatPhong",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 22 : 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Đăng ký",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueAccent,
                            elevation: 2,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text("Đăng nhập"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // SEARCH BOX
  // ============================
  Widget _searchBox({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: location,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: "Bạn muốn đi đâu?",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ⭐ LỊCH POPUP MINI
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) {
                  return Center(
                    child: CalendarPopup(
                      onSelected: (start, end) {
                        setState(() {
                          checkIn = start;
                          checkOut = end;
                        });
                      },
                    ),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      checkIn == null || checkOut == null
                          ? "Nhận phòng — Trả phòng"
                          : "${DateFormat('dd/MM').format(checkIn!)}  →  ${DateFormat('dd/MM').format(checkOut!)}",
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          InkWell(
            onTap: () => showModalBottomSheet(
              context: context,
              builder: (_) => _guestSelector(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "$adults người lớn · $children trẻ em · $rooms phòng",
                      style: const TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // TODO: Sau này điều hướng sang màn kết quả tìm kiếm
              },
              child: const Text(
                "Tìm kiếm",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================
  // POPUP CHỌN KHÁCH
  // ============================
  Widget _guestSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      height: 300,
      child: Column(
        children: [
          _numberRow("Người lớn", adults, (v) => setState(() => adults = v)),
          _numberRow("Trẻ em", children, (v) => setState(() => children = v)),
          _numberRow("Phòng", rooms, (v) => setState(() => rooms = v)),
        ],
      ),
    );
  }

  Widget _numberRow(String label, int value, Function(int) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 18)),
          Row(
            children: [
              IconButton(
                onPressed: value > 1 ? () => onChange(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text("$value", style: const TextStyle(fontSize: 18)),
              IconButton(
                onPressed: () => onChange(value + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
