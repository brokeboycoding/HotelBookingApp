import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_providers.dart';
import '../../providers/chat_providers.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final maNguoiDung = authProvider.currentUser?.uid;
      if (maNguoiDung != null && maNguoiDung.isNotEmpty) {
        context.read<ChatProvider>().loadChats(maNguoiDung);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final authProvider = context.watch<AuthProvider>();
    final maNguoiDungHienTai = authProvider.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.chats.isEmpty) {
            return Center(
              child: Text(
                'Chưa có cuộc trò chuyện nào.',
                style: TextStyle(color: cs.onSurface.withValues(alpha: 0.75)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final cuocTroChuyen = chatProvider.chats[index];

              final maNguoiConLai = cuocTroChuyen.participants.firstWhere(
                    (id) => id != maNguoiDungHienTai,
                orElse: () => '',
              );

              final tenNguoiConLai =
              cuocTroChuyen.participantNames[maNguoiConLai]?.trim().isNotEmpty ==
                  true
                  ? cuocTroChuyen.participantNames[maNguoiConLai]!.trim()
                  : 'Người dùng';

              final tinNhanCuoi = (cuocTroChuyen.lastMessage).trim().isEmpty
                  ? 'Chưa có tin nhắn'
                  : cuocTroChuyen.lastMessage;

              final gioPhut =
              DateFormat('HH:mm').format(cuocTroChuyen.lastMessageTime);

              final soChuaDoc = (maNguoiDungHienTai == null)
                  ? 0
                  : (cuocTroChuyen.unreadCount[maNguoiDungHienTai] ?? 0);

              return Card(
                color: cs.surface,
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.secondary.withValues(alpha: 0.20),
                    child: Text(
                      tenNguoiConLai.isNotEmpty ? tenNguoiConLai[0].toUpperCase() : '•',
                      style: TextStyle(
                        color: cs.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  title: Text(
                    tenNguoiConLai,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    tinNhanCuoi,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurface.withValues(alpha: 0.65)),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        gioPhut,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (soChuaDoc > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            soChuaDoc.toString(),
                            style: TextStyle(
                              color: cs.onSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    if (maNguoiDungHienTai == null || maNguoiDungHienTai.isEmpty) {
                      return;
                    }

                    Navigator.of(context).pushNamed(
                      '/chat',
                      arguments: {
                        'chatId': cuocTroChuyen.chatId,
                        'currentUserId': maNguoiDungHienTai,
                        'otherUserName': tenNguoiConLai,
                      },
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
