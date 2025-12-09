import 'package:agora_chat_callkit/agora_chat_call_manager.dart';
import 'package:agora_chat_callkit/agora_chat_callkit_define.dart';
import 'package:agora_chat_callkit/agora_chat_callkit_error.dart';
import 'package:agora_chat_uikit/chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:p2p_chat_with_agora_ui_kit/agora_rtc_manager.dart';
import 'package:p2p_chat_with_agora_ui_kit/call_pages/single_call_page.dart';
import 'package:p2p_chat_with_agora_ui_kit/constants.dart';
import 'package:p2p_chat_with_agora_ui_kit/chat_state.dart';

class ChatPage extends StatefulWidget {
  final String userId;
  final String username;

  const ChatPage({super.key, required this.userId, required this.username});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final AgoraRtcManager _agoraManager = AgoraRtcManager();

  @override
  void initState() {
    super.initState();
    ChatState.currentChatUserId = widget.userId;
    _initializeAgora();
  }

  Future<void> _initializeAgora() async {
    await _agoraManager.initialize(agoraAppId);
  }

  @override
  void dispose() {
    ChatState.currentChatUserId = null;
    _agoraManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => _startVoiceCall(),
          ),
        ],
      ),
      body: MessagesView(profile: ChatUIKitProfile.contact(id: widget.userId)),
    );
  }

  Future<void> _startVoiceCall() async {
    try {
      await AgoraChatCallManager.initRTC();
      try {
        // userId: The Agora Chat user ID of the callee.
        // type: The call type, which can be `AgoraChatCallType.audio_1v1` or `AgoraChatCallType.video_1v1`.

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SingleCallPage.call(
              widget.userId,
              type: AgoraChatCallType.audio_1v1,
            ),
          ),
        );
      } on AgoraChatCallError catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call error: ${e.errDescription}')),
        );
      }
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (_) => VoiceCallScreen(
      //       channelId: channelName,
      //       contactName: widget.username,
      //       agoraManager: _agoraManager,
      //     ),
      //   ),
      // );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start call: $e')));
    }
  }
}
