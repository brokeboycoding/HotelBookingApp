import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingManagementScreen extends StatelessWidget {
  const BookingManagementScreen({super.key});

  // Format ngày giờ đẹp
  String formatDate(dynamic date) {
    if (date is Timestamp) {
      return DateFormat("dd/MM/yyyy HH:mm").format(date.toDate());
    }
    return date?.toString() ?? "Không rõ";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý đặt phòng"),
        backgroundColor: Colors.blueAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("bookings")
            .orderBy("created_at", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(
              child: Text(
                "Chưa có đơn đặt phòng nào",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final doc = bookings[index];
              final data = doc.data() as Map<String, dynamic>;

              String name = data["customerName"] ?? "Khách";
              String email = data["customerEmail"] ?? "Không có email";
              String room = data["roomNumber"]?.toString() ?? "???";
              String status = data["status"] ?? "pending";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text("$name – Phòng $room"),
                  subtitle: Text(
                    "$email\nTrạng thái: $status",
                    style: const TextStyle(fontSize: 13),
                  ),

                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      switch (value) {
                        case "details":
                          _showBookingDetails(context, doc, data);
                          break;
                        case "confirm":
                          _updateStatus(doc.id, "confirmed");
                          break;
                        case "cancel":
                          _updateStatus(doc.id, "cancelled");
                          break;
                        case "checkin":
                          _updateStatus(doc.id, "checked-in");
                          break;
                        case "checkout":
                          _updateStatus(doc.id, "checked-out");
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "details",
                        child: Text("Xem chi tiết"),
                      ),

                      if (status == "pending")
                        const PopupMenuItem(
                          value: "confirm",
                          child: Text("Duyệt đặt phòng"),
                        ),

                      if (status == "pending" || status == "confirmed")
                        const PopupMenuItem(
                          value: "cancel",
                          child: Text("Hủy đơn"),
                        ),

                      if (status == "confirmed")
                        const PopupMenuItem(
                          value: "checkin",
                          child: Text("Check-in"),
                        ),

                      if (status == "checked-in")
                        const PopupMenuItem(
                          value: "checkout",
                          child: Text("Check-out"),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================================
  // UPDATE STATUS + LOG THỜI GIAN
  // ================================
  void _updateStatus(String id, String status) {
    FirebaseFirestore.instance.collection("bookings").doc(id).update({
      "status": status,
      "updated_at": DateTime.now(),
    });
  }

  // ================================
  // SHOW DETAILS (Dialog UI đẹp)
  // ================================
  void _showBookingDetails(
      BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chi tiết đặt phòng"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _item("Tên khách", data["customerName"]),
                _item("Email", data["customerEmail"]),
                _item("Phòng", data["roomNumber"]),
                _item("Giá", "${data["price"]} VNĐ"),
                _item("Check-in", formatDate(data["checkIn"])),
                _item("Check-out", formatDate(data["checkOut"])),
                _item("Trạng thái", data["status"]),
                _item("Ngày tạo", formatDate(data["created_at"])),
                _item("Cập nhật", formatDate(data["updated_at"])),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng"),
            )
          ],
        );
      },
    );
  }

  // Widget item dòng thông tin
  Widget _item(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        "$label: ${value ?? 'Không có'}",
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}
