import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'room_create_screen.dart';

class OwnerRoomsScreen extends StatelessWidget {
  const OwnerRoomsScreen({super.key});

  User? get _user => FirebaseAuth.instance.currentUser;

  // ✅ FIX: bỏ orderBy để không cần composite index
  Stream<QuerySnapshot<Map<String, dynamic>>>? _roomsStream() {
    final u = _user;
    if (u == null) return null;
    return FirebaseFirestore.instance
        .collection("rooms")
        .where("ownerId", isEqualTo: u.uid)
        .snapshots();
  }

  Future<void> _toggleActive(BuildContext context, String roomId, bool current) async {
    try {
      await FirebaseFirestore.instance.collection("rooms").doc(roomId).update({
        "isActive": !current,
        "updatedAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi cập nhật trạng thái: $e")),
      );
    }
  }

  Future<void> _deleteRoom(BuildContext context, String roomId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xoá phòng?"),
        content: const Text("Bạn có chắc chắn muốn xoá phòng này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Huỷ")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xoá"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance.collection("rooms").doc(roomId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã xoá phòng")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Lỗi xoá phòng: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;

    return Scaffold(
      body: u == null
          ? const Center(child: Text("Bạn chưa đăng nhập"))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _roomsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            // ✅ Hiển thị lỗi gọn, dễ hiểu
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Lỗi tải phòng: ${snap.error}",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Chưa có phòng nào. Nhấn + để tạo phòng."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();

              final name = (data["name"] ?? "Phòng").toString();
              final type = (data["type"] ?? "").toString();
              final price = (data["pricePerNight"] ?? 0).toString();
              final cap = (data["capacity"] ?? 0).toString();
              final active = (data["isActive"] ?? true) as bool;

              return Card(
                child: ListTile(
                  leading: Icon(active ? Icons.meeting_room : Icons.meeting_room_outlined),
                  title: Text(name),
                  subtitle: Text("Loại: $type • Giá: $price • Sức chứa: $cap"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: active ? "Tắt phòng" : "Bật phòng",
                        icon: Icon(active ? Icons.toggle_on : Icons.toggle_off),
                        onPressed: () => _toggleActive(context, d.id, active),
                      ),
                      IconButton(
                        tooltip: "Xoá phòng",
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteRoom(context, d.id),
                      ),
                    ],
                  ),
                  onTap: () {
                    // sau này bạn có thể mở màn sửa phòng tại đây
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoomCreateScreen()),
          );
          if (ok == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ Đã tạo phòng!")),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
