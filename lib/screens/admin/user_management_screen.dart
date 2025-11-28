import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
        backgroundColor: Colors.blueAccent,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("users").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(
              child: Text(
                "Chưa có người dùng nào",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              final name = data["name"] ?? "Không tên";
              final email = data["email"] ?? "Không có email";
              final role = data["role"] ?? "unknown";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(name),
                  subtitle: Text("$email • Vai trò: $role"),

                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      if (value == "edit") {
                        _showEditUserDialog(context, doc, data);
                      } else if (value == "delete") {
                        _deleteUser(doc.id);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: "edit", child: Text("Sửa thông tin")),
                      PopupMenuItem(value: "delete", child: Text("Xóa người dùng")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ============================================================
  // ADD USER DIALOG
  // ============================================================

  void _showAddUserDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String role = "customer";

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Thêm người dùng mới"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên người dùng"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              // Role dropdown — Flutter 3.33+ requires initialValue
              DropdownButtonFormField(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(value: "owner", child: Text("Owner")),
                  DropdownMenuItem(value: "customer", child: Text("Khách hàng")),
                ],
                onChanged: (v) => role = v!,
                decoration: const InputDecoration(labelText: "Vai trò"),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection("users").add({
                  "name": nameController.text.trim(),
                  "email": emailController.text.trim(),
                  "role": role,
                  "active": true,
                  "created_at": Timestamp.now(),
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

  // ============================================================
  // EDIT USER DIALOG
  // ============================================================

  void _showEditUserDialog(
      BuildContext context, DocumentSnapshot doc, Map<String, dynamic> data) {
    final nameController = TextEditingController(text: data["name"]);
    final emailController = TextEditingController(text: data["email"]);
    String role = data["role"];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Sửa thông tin người dùng"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Tên"),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),

              DropdownButtonFormField(
                initialValue: role,
                items: const [
                  DropdownMenuItem(value: "admin", child: Text("Admin")),
                  DropdownMenuItem(value: "owner", child: Text("Owner")),
                  DropdownMenuItem(value: "customer", child: Text("Khách hàng")),
                ],
                onChanged: (v) => role = v!,
                decoration: const InputDecoration(labelText: "Vai trò"),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection("users").doc(doc.id).update({
                  "name": nameController.text.trim(),
                  "email": emailController.text.trim(),
                  "role": role,
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

  // ============================================================
  // DELETE USER
  // ============================================================

  void _deleteUser(String id) {
    FirebaseFirestore.instance.collection("users").doc(id).delete();
  }
}
