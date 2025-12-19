import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomerSearchScreen extends StatefulWidget {
  final List<String> recentSearches;
  final List<String> recentViewedRoomIds;
  final void Function(String query) onAddRecentSearch;
  final void Function(String roomId) onViewedRoom;

  const CustomerSearchScreen({
    super.key,
    required this.recentSearches,
    required this.recentViewedRoomIds,
    required this.onAddRecentSearch,
    required this.onViewedRoom,
  });

  @override
  State<CustomerSearchScreen> createState() => _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends State<CustomerSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  Stream<QuerySnapshot<Map<String, dynamic>>> _roomsStream() {
    return FirebaseFirestore.instance
        .collection('rooms')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final q = _ctrl.text.trim().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Tìm kiếm'),
        backgroundColor: const Color(0xFF3F7CFF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.black.withValues(alpha: 0.55)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (v) {
                        final t = v.trim();
                        if (t.isNotEmpty) widget.onAddRecentSearch(t);
                      },
                      decoration: InputDecoration(
                        hintText: 'Nhập tên khách sạn / địa chỉ / phòng…',
                        hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.35)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_ctrl.text.trim().isNotEmpty)
                    InkWell(
                      onTap: () {
                        _ctrl.clear();
                        setState(() {});
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.close, size: 18),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (widget.recentSearches.isNotEmpty && q.isEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Tìm gần đây',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withValues(alpha: 0.75),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.recentSearches.map((t) {
                  return ActionChip(
                    label: Text(t),
                    onPressed: () {
                      _ctrl.text = t;
                      _ctrl.selection = TextSelection.fromPosition(TextPosition(offset: t.length));
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _roomsStream(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) return Center(child: Text('Lỗi: ${snap.error}'));

                  final docs = snap.data?.docs ?? [];
                  final filtered = docs.where((d) {
                    if (q.isEmpty) return true;
                    final data = d.data();
                    final name = _s(data['name']).toLowerCase();
                    final hotel = _s(data['hotelName']).toLowerCase();
                    final addr = _s(data['hotelAddress']).toLowerCase();
                    return name.contains(q) || hotel.contains(q) || addr.contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(child: Text(q.isEmpty ? 'Nhập từ khóa để tìm.' : 'Không tìm thấy.'));
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final d = filtered[i];
                      final data = d.data();
                      final title = _s(data['name']).isEmpty ? 'Phòng' : _s(data['name']);
                      final sub = [
                        _s(data['hotelName']),
                        _s(data['hotelAddress']),
                      ].where((e) => e.trim().isNotEmpty).join(' • ');

                      return InkWell(
                        onTap: () {
                          widget.onViewedRoom(d.id);
                          Navigator.pop(context);
                        },
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
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
