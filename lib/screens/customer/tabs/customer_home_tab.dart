import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerHomeTab extends StatelessWidget {
  final String who;
  final VoidCallback onOpenSearch;
  final void Function(String roomId) onViewedRoom;
  final void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms) onOpenMap;

  const CustomerHomeTab({
    super.key,
    required this.who,
    required this.onOpenSearch,
    required this.onViewedRoom,
    required this.onOpenMap,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> _roomsStream() {
    return FirebaseFirestore.instance
        .collection("rooms")
        .where("isActive", isEqualTo: true)
        .snapshots();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3F7CFF), Color(0xFF6EA8FF)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.hotel, color: Colors.white, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Xin chào, $who 👋',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onOpenSearch,
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: 'Tìm kiếm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _roomsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) return const Center(child: Text('Chưa có phòng nào đang mở.'));

                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () => onOpenMap(docs),
                        icon: const Icon(Icons.map),
                        label: const Text('Xem trên bản đồ'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2F6BFF),
                          side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final d = docs[i];
                          final data = d.data();
                          final title = _s(data['name']).isEmpty ? 'Phòng' : _s(data['name']);
                          final sub = [
                            _s(data['hotelName']),
                            _s(data['hotelAddress']),
                          ].where((e) => e.trim().isNotEmpty).join(' • ');

                          return InkWell(
                            onTap: () => onViewedRoom(d.id),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                                  if (sub.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      sub,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.black.withValues(alpha: 0.55)),
                                    ),
                                  ]
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
