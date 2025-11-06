import 'package:flutter/material.dart';
import 'package:agora_chat_uikit/chat_uikit.dart';
import 'package:agora_chat_callkit/agora_chat_callkit.dart';

const String appKey = "";
const String agoraAppId = "";
const String userId = '';
const String token =
    "";

void main() {
  ChatUIKit.instance
      .init(options: Options(appKey: appKey, autoLogin: false))
      .then((value) {
        runApp(MyApp());
      });
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final ChatUIKitLocalizations _localization = ChatUIKitLocalizations();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      supportedLocales: _localization.supportedLocales,
      localizationsDelegates: _localization.localizationsDelegates,
      localeResolutionCallback: _localization.localeResolutionCallback,
      locale: _localization.currentLocale,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return ChatCallKit(agoraAppId: agoraAppId, child: child!);
      },
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (!_isLoggedIn)
              ElevatedButton(onPressed: login, child: const Text('Login')),
            if (_isLoggedIn)
              ElevatedButton(onPressed: _logout, child: const Text('Logout')),
            const SizedBox(height: 20),
            if (_isLoggedIn)
              ElevatedButton(
                onPressed: () => _navigateToConversations(),
                child: const Text('Chat'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> login() async {
    try {
      await ChatUIKit.instance.loginWithToken(userId: userId, token: token);
      setState(() {
        _isLoggedIn = true;
      });
      debugPrint('Login successful');
    } catch (e) {
      debugPrint('login error: $e');
    }
  }

  Future<void> _logout() async {
    try {
      await ChatUIKit.instance.logout();
      setState(() {
        _isLoggedIn = false;
      });
    } catch (e) {
      debugPrint('logout error: $e');
    }
  }

  void _navigateToConversations() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ConversationsListPage()),
    );
  }
}

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
        onItemTap: (conversations, data) {
          // When a conversation is tapped, navigate to chat page
          if (data is ChatUIKitProfile) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChatPage(chatterId: data.profile.id),
              ),
            );
          }
        },
        itemBuilder: (context, ConversationItemModel data) {
          return ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ChatPage(chatterId: data.profile.id),
                ),
              );
            },
            leading: CircleAvatar(child: Text(data.profile.avatarUrl ?? "")),
            title: Text(data.profile.contactShowName),
            subtitle: Text(data.lastMessage?.textContent ?? ""),
            trailing: data.unreadCount > 0
                ? CircleAvatar(
                    radius: 12,
                    child: Text(data.unreadCount.toString()),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({required this.chatterId, super.key});
  final String chatterId;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatterId),
        actions: [
          // Voice Call Button
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () async {
              await ChatCallKitManager.initRTC();
              try {
                // userId: The Agora Chat user ID of the callee.
                // type: The call type, which can be `ChatCallKitCallType.audio_1v1` or `ChatCallKitCallType.video_1v1`.
                String callId = await ChatCallKitManager.startSingleCall(
                  userId,
                  type: ChatCallKitCallType.audio_1v1,
                );
              } on ChatCallKitError catch (e) {
                print(e.errDescription);
                debugPrint('Error starting call: ${e.toString()}');
              }
            },
          ),
        ],
      ),
      body: MessagesView(
        profile: ChatUIKitProfile.contact(id: widget.chatterId),
      ),
    );
  }
}

class CallPage extends StatelessWidget {
  const CallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Text("data");
    // return ChatCallKit(agoraAppId: appKey, child: child);
  }
}
