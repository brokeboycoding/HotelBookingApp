import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminOwnerRequestsScreen extends StatelessWidget {
  const AdminOwnerRequestsScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingStream() {
    return FirebaseFirestore.instance
        .collection("owner_requests")
        .where("status", isEqualTo: "pending")
        .snapshots();
    // Nếu muốn orderBy createdAt:
    // .orderBy("createdAt", descending: true)
    // -> có thể cần index
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Duyệt đăng ký Owner")),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _pendingStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Lỗi: ${snap.error}"));
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text("Không có đơn pending."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final fullName = (data["fullName"] ?? "").toString();
              final hotelName = (data["hotelName"] ?? "").toString();
              final phone = (data["phone"] ?? "").toString();
              final uid = (data["uid"] ?? d.id).toString();

              return Card(
                child: ListTile(
                  title: Text("$fullName • $hotelName"),
                  subtitle: Text("SĐT: $phone\nUID: $uid"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminOwnerRequestDetailScreen(requestId: d.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminOwnerRequestDetailScreen extends StatelessWidget {
  final String requestId;
  const AdminOwnerRequestDetailScreen({super.key, required this.requestId});

  Future<void> _approve(BuildContext context, Map<String, dynamic> data) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    final uid = (data["uid"] ?? requestId).toString();
    final reqRef = FirebaseFirestore.instance.collection("owner_requests").doc(requestId);
    final userRef = FirebaseFirestore.instance.collection("users").doc(uid);

    final batch = FirebaseFirestore.instance.batch();
    batch.update(reqRef, {
      "status": "approved",
      "reviewedAt": FieldValue.serverTimestamp(),
      "reviewedBy": admin.uid,
      "rejectReason": null,
    });
    batch.set(userRef, {
      "role": "owner",
      "ownerApproved": true,
      "ownerApprovedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã duyệt và set role=owner.")),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _reject(BuildContext context, Map<String, dynamic> data) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null) return;

    final reasonCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Từ chối đơn"),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(labelText: "Lý do (tuỳ chọn)"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text("Từ chối"),
            ),
          ],
        );
      },
    );


    if (ok != true) return;

    final reqRef = FirebaseFirestore.instance.collection("owner_requests").doc(requestId);
    await reqRef.update({
      "status": "rejected",
      "reviewedAt": FieldValue.serverTimestamp(),
      "reviewedBy": admin.uid,
      "rejectReason": reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim(),
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã từ chối đơn.")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance.collection("owner_requests").doc(requestId);

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết đơn Owner")),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: ref.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text("Lỗi: ${snap.error}"));
          }
          final data = snap.data?.data();
          if (data == null) return const Center(child: Text("Không tìm thấy đơn."));

          final status = (data["status"] ?? "").toString();
          final fullName = (data["fullName"] ?? "").toString();
          final phone = (data["phone"] ?? "").toString();
          final hotelName = (data["hotelName"] ?? "").toString();
          final hotelAddress = (data["hotelAddress"] ?? "").toString();

          final docs = (data["docFiles"] is List) ? (data["docFiles"] as List) : const [];
          final fileItems = docs
              .whereType<Map>()
              .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text("Trạng thái: $status", style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text("Họ tên: $fullName"),
              Text("SĐT: $phone"),
              const SizedBox(height: 8),
              Text("Khách sạn: $hotelName"),
              Text("Địa chỉ: $hotelAddress"),
              const SizedBox(height: 14),

              const Text("Giấy tờ đính kèm:", style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              if (fileItems.isEmpty)
                const Text("Không có file.")
              else
                for (final f in fileItems)
                  Card(
                    child: ListTile(
                      leading: Icon(((f["ext"] ?? "").toString().toLowerCase() == "pdf")
                          ? Icons.picture_as_pdf
                          : Icons.image),
                      title: Text((f["name"] ?? "").toString()),
                      subtitle: Text((f["url"] ?? "").toString()),
                    ),
                  ),

              const SizedBox(height: 16),

              if (status == "pending")
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _reject(context, data),
                        icon: const Icon(Icons.close),
                        label: const Text("Từ chối"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approve(context, data),
                        icon: const Icon(Icons.check),
                        label: const Text("Duyệt"),
                      ),
                    ),
                  ],
                )
              else
                const Text("Đơn đã được xử lý."),
            ],
          );
        },
      ),
    );
  }
}
