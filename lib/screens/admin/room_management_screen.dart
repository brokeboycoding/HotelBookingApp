import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomManagementScreen extends StatelessWidget {
  const RoomManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý phòng"),
        backgroundColor: Colors.blueAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("rooms")
            .orderBy("roomNumber")
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Center(
              child: Text("Chưa có phòng nào", style: TextStyle(fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final doc = rooms[index];
              final data = doc.data() as Map<String, dynamic>;

              final String imageUrl = (data["imageUrl"] ?? "").toString();
              final String status = data["status"] ?? "available";

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? const Icon(Icons.image_not_supported)
                        : null,
                  ),

                  title: Text(
                    "Phòng ${data["roomNumber"]}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  subtitle: Text(
                    "Loại: ${data["typeId"]} • Giá: ${data["price"]} VNĐ\n"
                        "Trạng thái: $status",
                    style: const TextStyle(fontSize: 13),
                  ),

                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == "edit") {
                        _editRoom(context, doc, data);
                      } else if (value == "delete") {
                        _deleteRoom(context, doc.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: "edit",
                        child: Text("Sửa phòng"),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text("Xóa phòng"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRoom(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ==================================================
  // ADD ROOM
  // ==================================================
  void _addRoom(BuildContext context) {
    final roomController = TextEditingController();
    final priceController = TextEditingController();
    String typeId = "standard";

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Thêm phòng mới"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: "Số phòng"),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Giá phòng"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // FIXED: use initialValue
                DropdownButtonFormField(
                  initialValue: typeId,
                  decoration: const InputDecoration(labelText: "Loại phòng"),
                  items: const [
                    DropdownMenuItem(
                      value: "standard",
                      child: Text("Standard"),
                    ),
                    DropdownMenuItem(
                      value: "deluxe",
                      child: Text("Deluxe"),
                    ),
                    DropdownMenuItem(
                      value: "vip",
                      child: Text("VIP"),
                    ),
                  ],
                  onChanged: (v) => typeId = v!,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),

            ElevatedButton(
              onPressed: () async {
                final roomNumber = roomController.text.trim();
                final price = int.tryParse(priceController.text) ?? 0;

                if (roomNumber.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
                  );
                  return;
                }

                final check = await FirebaseFirestore.instance
                    .collection("rooms")
                    .where("roomNumber", isEqualTo: roomNumber)
                    .get();

                if (check.docs.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Số phòng đã tồn tại!")),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection("rooms").add({
                  "roomNumber": roomNumber,
                  "price": price,
                  "typeId": typeId,
                  "status": "available",
                  "imageUrl":
                  "https://cf.bstatic.com/xdata/images/hotel/max1024x768/272232841.jpg?k=1f",
                  "created_at": DateTime.now(),
                });

                Navigator.pop(context);
              },
              child: const Text("Thêm"),
            ),
          ],
        );
      },
    );
  }

  // ==================================================
  // EDIT ROOM
  // ==================================================
  void _editRoom(
      BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    final roomController = TextEditingController(text: data["roomNumber"]);
    final priceController = TextEditingController(text: data["price"].toString());
    String typeId = data["typeId"];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Sửa phòng"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: roomController,
                  decoration: const InputDecoration(labelText: "Số phòng"),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: "Giá phòng"),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // FIXED: use initialValue
                DropdownButtonFormField(
                  initialValue: typeId,
                  decoration: const InputDecoration(labelText: "Loại phòng"),
                  items: const [
                    DropdownMenuItem(
                      value: "standard",
                      child: Text("Standard"),
                    ),
                    DropdownMenuItem(
                      value: "deluxe",
                      child: Text("Deluxe"),
                    ),
                    DropdownMenuItem(
                      value: "vip",
                      child: Text("VIP"),
                    ),
                  ],
                  onChanged: (v) => typeId = v!,
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),

            ElevatedButton(
              onPressed: () async {
                final roomNumber = roomController.text.trim();
                final price = int.tryParse(priceController.text) ?? 0;

                if (roomNumber.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
                  );
                  return;
                }

                await FirebaseFirestore.instance
                    .collection("rooms")
                    .doc(doc.id)
                    .update({
                  "roomNumber": roomNumber,
                  "price": price,
                  "typeId": typeId,
                  "updated_at": DateTime.now(),
                });

                Navigator.pop(context);
              },
              child: const Text("Lưu"),
            ),
          ],
        );
      },
    );
  }

  // ==================================================
  // DELETE ROOM
  // ==================================================
  void _deleteRoom(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa phòng"),
        content: const Text("Bạn có chắc muốn xóa phòng này?"),
        actions: [
          TextButton(
            child: const Text("Hủy"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Xóa"),
            onPressed: () async {
              await FirebaseFirestore.instance.collection("rooms").doc(id).delete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
