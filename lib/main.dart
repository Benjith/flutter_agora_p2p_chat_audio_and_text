import 'package:dio/dio.dart' as dioClient;
import 'package:flutter/material.dart';
import 'package:agora_chat_uikit/chat_uikit.dart';
import 'package:p2p_chat_with_agora_ui_kit/call_pages/single_call_page.dart';
import 'package:p2p_chat_with_agora_ui_kit/constants.dart';
import 'package:p2p_chat_with_agora_ui_kit/conversations_list_page.dart';
import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:permission_handler/permission_handler.dart';

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
        return AgoraChatCallKit(agoraAppId: agoraAppId, child: child!);
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

  Map<String, String>? selectedUser;

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
            if (!_isLoggedIn) ...[
              DropdownButton<Map<String, String>?>(
                value: selectedUser,
                items: staticUsers
                    .map(
                      (user) => DropdownMenuItem<Map<String, String>>(
                        value: user,
                        child: Text('User ID: ${user['id']}'),
                      ),
                    )
                    .toList(),
                hint: const Text('Select User ID'),
                onChanged: (value) {
                  setState(() => selectedUser = value!);
                },
              ),
              ElevatedButton(onPressed: login, child: const Text('Login')),
            ],

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
      if (selectedUser == null) {
        debugPrint('Please select a user ID to login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a user ID to login')),
        );
        return;
      }
      await ChatUIKit.instance.loginWithToken(
        userId: selectedUser!["id"]!,
        token: selectedUser!["token"]!,
      );

      //voice call initial handler setup
      // Do this right after user login succeeds
      AgoraChatCallManager.setRTCTokenHandler((channel, appId) async {
        final response = await dioClient.Dio().get(
          'http://192.168.1.6:8000/rtc-token',
          queryParameters: {
            'channelName': channel,
            'uid': ChatUIKit.instance.currentUserId,
          },
        );
        final agoraToken = response.data['rtcToken'];
        final agoraUid = response.data['uid'];
        return {agoraToken: agoraUid};
      });

      AgoraChatCallManager.setUserMapperHandler((channel, agoraUid) async {
        print("channel name $channel agoraId is $agoraUid");
        return AgoraChatCallUserMapper(channel, {
          agoraUid: agoraUid.toString(),
        });
      });

      AgoraChatCallManager.addEventListener(
        "UNIQUE_HANDLER_ID",
        AgoraChatCallKitEventHandler(
          onReceiveCall: onReceiveCall,
          onCallEnd: (callId, reason) async {
            // try {
            //   if (callId != null) await AgoraChatCallManager.releaseRTC();
            // } catch (e) {}
          },
        ),
      );

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

  void onReceiveCall(
    String userId,
    String callId,
    AgoraChatCallType callType,
    Map<String, String>? ext,
  ) async {
    pushToCallPage([userId], callType, callId);
  }

  void pushToCallPage(
    List<String> userIds,
    AgoraChatCallType callType, [
    String? callId,
  ]) async {
    Widget page;

    if (callId == null) {
      page = SingleCallPage.call(userIds.first, type: callType);
    } else {
      page = SingleCallPage.receive(userIds.first, callId, type: callType);
    }

    [Permission.microphone, Permission.camera].request().then((value) {
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) {
                return page;
              },
            ),
          )
          .then((value) {
            if (value != null) {
              debugPrint('call end: $value');
            }
          });
    });
  }

  @override
  void dispose() {
    AgoraChatCallManager.removeEventListener("UNIQUE_HANDLER_ID");
    super.dispose();
  }
}
