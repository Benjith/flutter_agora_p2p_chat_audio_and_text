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
      body: ConversationsView(
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
    );
  }
}
