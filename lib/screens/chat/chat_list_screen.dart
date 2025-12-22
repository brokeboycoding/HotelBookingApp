import 'package:booking_app/providers/chat_providers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_providers.dart';
import '../../models/chat_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        Provider.of<ChatProvider>(context, listen: false)
            .loadChats(authProvider.currentUser!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (chatProvider.chats.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              final otherUserName =
                  chat.participantNames[chat.participants.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              )] ??
                      'Unknown User';

              return Card(
                color: Theme.of(context).colorScheme.surface,
                margin:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor:
                        Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    child: Text(
                      otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                  title: Text(
                    otherUserName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(chat.lastMessageTime),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      if ((chat.unreadCount[currentUserId] ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            chat.unreadCount[currentUserId].toString(),
                            style: const TextStyle(
                                color: Colors.black, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/chat',
                      arguments: {
                        'chatId': chat.chatId,
                        'currentUserId': currentUserId!,
                        'otherUserName': otherUserName,
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
