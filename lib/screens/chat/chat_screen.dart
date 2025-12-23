import 'package:flutter/material.dart';

import '../../models/chat_model.dart';
import '../../services/chat_services.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _dichVuChat = ChatService();
  final TextEditingController _boDieuKhienTinNhan = TextEditingController();
  final ScrollController _boDieuKhienCuon = ScrollController();

  @override
  void initState() {
    super.initState();
    // Đánh dấu đã đọc khi vào cuộc trò chuyện
    _dichVuChat.markAsRead(widget.chatId, widget.currentUserId);
  }

  @override
  void dispose() {
    _boDieuKhienTinNhan.dispose();
    _boDieuKhienCuon.dispose();
    super.dispose();
  }

  Future<void> _guiTinNhan() async {
    final noiDung = _boDieuKhienTinNhan.text.trim();
    if (noiDung.isEmpty) return;

    _boDieuKhienTinNhan.clear();

    try {
      await _dichVuChat.sendMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        text: noiDung,
      );

      // Vì ListView reverse: true nên về "đầu list" là xuống cuối cuộc chat
      if (_boDieuKhienCuon.hasClients) {
        _boDieuKhienCuon.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;

      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi tin nhắn không thành công: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          // Danh sách tin nhắn
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _dichVuChat.getChatMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final danhSachTinNhan = snapshot.data ?? <MessageModel>[];
                if (danhSachTinNhan.isEmpty) {
                  return Center(
                    child: Text(
                      'Chưa có tin nhắn nào.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _boDieuKhienCuon,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: danhSachTinNhan.length,
                  itemBuilder: (context, index) {
                    final tinNhan = danhSachTinNhan[index];
                    final laToi = tinNhan.senderId == widget.currentUserId;
                    return _bongTinNhan(tinNhan, laToi, theme);
                  },
                );
              },
            ),
          ),

          // Ô nhập tin nhắn
          _oNhapTinNhan(theme),
        ],
      ),
    );
  }

  Widget _oNhapTinNhan(ThemeData theme) {
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _boDieuKhienTinNhan,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn…',
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textInputAction: TextInputAction.newline,
                style: TextStyle(color: cs.onSurface),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send, color: cs.secondary),
              onPressed: _guiTinNhan,
              tooltip: 'Gửi tin nhắn',
            ),
          ],
        ),
      ),
    );
  }

  Widget _bongTinNhan(MessageModel tinNhan, bool laToi, ThemeData theme) {
    final cs = theme.colorScheme;

    final mauNen = laToi ? cs.secondary : cs.surface;
    final mauChu = laToi ? cs.onSecondary : cs.onSurface;

    return Row(
      mainAxisAlignment: laToi ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: mauNen,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            tinNhan.text,
            style: TextStyle(color: mauChu),
          ),
        ),
      ],
    );
  }
}
