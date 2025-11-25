import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agora_chat_uikit/chat_uikit.dart';
import 'package:p2p_chat_with_agora_ui_kit/call_pages/single_call_page.dart';
import 'package:p2p_chat_with_agora_ui_kit/chat_page.dart';
import 'package:p2p_chat_with_agora_ui_kit/constants.dart';
import 'package:p2p_chat_with_agora_ui_kit/conversations_list_page.dart';
import 'package:p2p_chat_with_agora_ui_kit/firebase_options.dart';
import 'package:agora_chat_callkit/agora_chat_callkit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:p2p_chat_with_agora_ui_kit/token_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart' as agora_sdk;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
  debugPrint("Background message data: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final options = Options(appKey: appKey, autoLogin: false);
  options.enableFCM("1040816516698");
  ChatUIKit.instance.init(options: options).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  MyApp({super.key});
  final ChatUIKitLocalizations _localization = ChatUIKitLocalizations();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
  final TextEditingController _userIdController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupFCMListeners();
    _setupLocalNotifications();
  }

  Future<void> _setupLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // Handle notification tap
          debugPrint("Notification tapped with payload: ${response.payload}");
          // Navigate to chat page
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ChatPage(
                userId: response.payload!,
                username: response.payload!,
              ),
            ),
          );
        }
      },
    );
  }

  void _setupFCMListeners() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message received: ${message.messageId}");
      debugPrint("Foreground message data: ${message.data}");
      if (message.data.isNotEmpty) {
        _handlePush(message.data);
      }
    });

    // Background tap (app in background, user taps notification)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Background message opened: ${message.messageId}");
      debugPrint("Background message data: ${message.data}");
      if (message.data.isNotEmpty) {
        _handlePush(message.data);
      }
    });

    // Terminated tap (app was killed, user taps notification)
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        debugPrint("Terminated message opened: ${message.messageId}");
        debugPrint("Terminated message data: ${message.data}");
        if (message.data.isNotEmpty) {
          _handlePush(message.data);
        }
      }
    });
  }

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
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    labelText: 'Enter User ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_isLoading)
                const CircularProgressIndicator()
              else
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
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a user ID')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Fetch Chat Token
      final chatToken = await TokenService().fetchChatToken(userId);

      // 2. Login with fetched token
      await ChatUIKit.instance.loginWithToken(userId: userId, token: chatToken);

      // 3. Configure FCM
      try {
        // Request permission
        await FirebaseMessaging.instance.requestPermission();

        // Register push token to Agora
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await ChatClient.getInstance.pushManager.updateFCMPushToken(token);
          debugPrint("FCM Token updated: $token");
        }

        // Listen for token refresh
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          debugPrint("FCM Token refreshed: $newToken");
          ChatClient.getInstance.pushManager.updateFCMPushToken(newToken);
        });
      } catch (e) {
        debugPrint("FCM Config Error: $e");
      }

      //voice call initial handler setup
      // Do this right after user login succeeds
      AgoraChatCallManager.setRTCTokenHandler((channel, appId) async {
        final result = await TokenService().fetchRtcToken(
          channel,
          ChatUIKit.instance.currentUserId!,
        );
        return {result['rtcToken']: result['uid']};
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

      // Setup Agora Chat message listener for foreground/background notifications
      _setupAgoraChatMessageListener();

      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
      });
      debugPrint('Login successful');
      _navigateToConversations();
    } catch (e) {
      debugPrint('login error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
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

  void _handlePush(Map<String, dynamic> data) {
    debugPrint("Handling push data: $data");
    if (data.containsKey("callId")) {
      // incoming call
      final String fromUserId = data["f"];
      final String callId = data["callId"];
      final callType = data["callType"] == "video"
          ? AgoraChatCallType.video_1v1
          : AgoraChatCallType.audio_1v1;

      pushToCallPage([fromUserId], callType, callId);
      return;
    }

    // default = chat message push
    final String fromUserId = data["f"];
    final String username = data["u"] ?? "";
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(userId: fromUserId, username: username),
      ),
    );
  }

  void _setupAgoraChatMessageListener() {
    // Listen for messages while app is connected (foreground/background)
    ChatClient.getInstance.chatManager.addMessageEvent(
      "MESSAGE_LISTENER",
      ChatMessageEvent(
        onSuccess: (msgId, msg) {
          debugPrint("Message sent successfully: $msgId");
        },
        onProgress: (msgId, progress) {
          debugPrint("Message progress: $msgId - $progress");
        },
        onError: (msgId, msg, error) {
          debugPrint("Message error: $msgId - ${error.description}");
        },
      ),
    );

    ChatClient.getInstance.chatManager.addEventHandler(
      "CHAT_EVENT_HANDLER",
      ChatEventHandler(
        onMessagesReceived: (messages) async {
          debugPrint("Received ${messages.length} message(s) while connected");

          // Show local notification for each message
          for (var message in messages) {
            if (message.body.type == agora_sdk.MessageType.TXT) {
              final txtBody = message.body as ChatTextMessageBody;
              await _showLocalNotification(
                title: "New message from ${message.from}",
                body: txtBody.content,
                payload: message.from,
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'chat_messages',
          'Chat Messages',
          channelDescription: 'Notifications for incoming chat messages',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
