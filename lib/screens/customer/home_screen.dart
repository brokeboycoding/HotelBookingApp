import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ⭐ Import màn Login (chỉnh lại path nếu khác)
import '../login/login_screen.dart';
// ⭐ Import màn hồ sơ dùng chung (admin/owner/customer)
import '../user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loggingOut = false;

  Future<void> _logout() async {
    if (loggingOut) return; // tránh bấm liên tục

    setState(() => loggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // ⭐ Sau khi logout → quay về LoginScreen và xóa toàn bộ stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đăng xuất: $e')),
      );
      setState(() => loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Khách sạn Tiền Luxury"),
        backgroundColor: Colors.blueAccent,
        elevation: 3,
        actions: [
          // ⭐ Nút hồ sơ khách
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: "Hồ sơ của bạn",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Đăng xuất",
            onPressed: loggingOut ? null : _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 LIST PHÒNG
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("rooms")
                  .orderBy("price")
                  .snapshots(),
              builder: (context, snapshot) {
                // Đang load
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Lỗi
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Lỗi tải dữ liệu: ${snapshot.error}"),
                  );
                }

                // Không có dữ liệu
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Chưa có phòng nào được cấu hình"),
                  );
                }

                final rooms = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final data =
                    rooms[index].data() as Map<String, dynamic>;

                    final imageUrl = data["imageUrl"] as String? ??
                        "https://via.placeholder.com/400x200?text=Room";
                    final roomNumber =
                        data["roomNumber"]?.toString() ?? "N/A";
                    final description =
                        data["description"]?.toString() ?? "Không có mô tả";
                    final price = data["price"] ?? 0;
                    final status =
                        data["status"]?.toString() ?? "unknown";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // IMAGE
                          AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                    ),
                                  ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Phòng $roomNumber",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  "${price.toString()} VNĐ / đêm",
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status),
                                        borderRadius:
                                        BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    ElevatedButton(
                                      onPressed: status == "available"
                                          ? () {
                                        // TODO: sau này chuyển sang màn đặt phòng chi tiết
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Đặt phòng $roomNumber (demo)",
                                            ),
                                          ),
                                        );
                                      }
                                          : null, // phòng không available thì disable
                                      child: const Text("Đặt ngay"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 🔹 NÚT ĐĂNG XUẤT TO Ở DƯỚI (OPTIONAL)
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loggingOut ? null : _logout,
                icon: const Icon(Icons.logout),
                label: loggingOut
                    ? const Text('Đang đăng xuất...')
                    : const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // màu trạng thái phòng
  Color _statusColor(String status) {
    switch (status) {
      case "available":
        return Colors.green;
      case "occupied":
        return Colors.orange;
      case "maintenance":
        return Colors.grey;
      default:
        return Colors.black45;
    }
  }
}
