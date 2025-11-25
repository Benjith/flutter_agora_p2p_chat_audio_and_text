import 'package:agora_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:p2p_chat_with_agora_ui_kit/chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _userIdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter Contact ID',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final userId = _userIdController.text.trim();
                    if (userId.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ChatPage(userId: userId, username: userId),
                        ),
                      );
                      _userIdController.clear();
                    }
                  },
                  child: const Text('Chat'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ConversationsView(
              onItemTap: (context, ConversationItemModel data) {
                var userId = data.profile.id;
                var remark = data.profile.showName;
                // When a conversation is tapped, navigate to chat page
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatPage(userId: userId, username: remark ?? ""),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final TextEditingController _userIdController = TextEditingController();
}
