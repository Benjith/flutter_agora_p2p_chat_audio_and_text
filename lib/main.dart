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
import 'package:p2p_chat_with_agora_ui_kit/chat_state.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:agora_chat_sdk/agora_chat_sdk.dart' as agora_sdk;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling background message: ${message.messageId}");
  debugPrint("Background message data: ${message.data}");

  // If it is a call and app is in background (terminated handler)
  if (message.data.containsKey("callId")) {
    final String fromUserName = message.data["u"] ?? "Unknown";

    // Initialize local notifications in background isolate
    final FlutterLocalNotificationsPlugin flnp =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initIOS = DarwinInitializationSettings();
    await flnp.initialize(
      InitializationSettings(android: initAndroid, iOS: initIOS),
    );

    await _createCallNotificationChannel(flnp);

    // Show Local Notification
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'incoming_calls',
          'Incoming Calls',
          channelDescription: 'Notifications for incoming voice/video calls',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          playSound: true,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound:
          'system_ringtone_default.aiff', // ensure exists or remove for default
    );

    final payload = jsonEncode({'type': 'call', 'data': message.data});

    await flnp.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Incoming Call',
      '$fromUserName is calling...',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }
}

Future<void> _createCallNotificationChannel(
  FlutterLocalNotificationsPlugin flnp,
) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'incoming_calls', // id
    'Incoming Calls', // title
    description: 'Notifications for incoming voice/video calls',
    importance: Importance.max,
    playSound: true,
  );

  await flnp
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool _isLoggedIn = false;
  final TextEditingController _userIdController = TextEditingController();
  bool _isLoading = false;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;
  String? _pendingNavigationUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupFCMListeners();
    _setupLocalNotifications();
    _checkAutoLogin();
  }

  /// Automatically login if a user ID is saved in shared preferences.
  Future<void> _checkAutoLogin() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('current_user_id');

    debugPrint("Checking auto-login. Saved ID: $userId");

    if (userId != null && userId.isNotEmpty) {
      _userIdController.text = userId;
      // Trigger login automatically
      await login();
    } else {
      setState(() => _isLoading = false);
    }
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
          debugPrint("Notification tapped with payload: ${response.payload}");
          try {
            final data = jsonDecode(response.payload!);

            if (data is Map && data['type'] == 'call') {
              final callData = data['data'];
              final String fromUserId = callData["f"];
              final bool isVideo = callData["callType"] == "video";
              final String? callId = callData["callId"];

              final callType = isVideo
                  ? AgoraChatCallType.video_1v1
                  : AgoraChatCallType.audio_1v1;

              if (_isLoggedIn) {
                debugPrint(
                  "Call notification tapped. Let Agora SDK handle UI.",
                );
                // pushToCallPage([fromUserId], callType, callId); // REMOVED per user request
              } else {
                debugPrint(
                  "Not logged in. App open will trigger auto-login and Agora listeners.",
                );
              }
              return;
            } else {
              // Chat message
              if (_isLoggedIn) {
                _navigateToChat(response.payload!, response.payload!);
              } else {
                debugPrint("Notification tapped but not logged in. Queueing.");
                _pendingNavigationUserId = response.payload;
              }
            }
          } catch (e) {
            // Fallback for plain string payloads (old logic)
            if (_isLoggedIn) {
              _navigateToChat(response.payload!, response.payload!);
            }
          }
        }
      },
    );

    // Explicitly request permissions for iOS and debug status
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final status = await Permission.notification.status;
      debugPrint("Current iOS Notification Permission Status: $status");
      if (status.isDenied || status.isRestricted) {
        final result = await Permission.notification.request();
        debugPrint("Requested iOS Notification Permission: $result");
      }

      // Also try the plugin's native request method check
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      debugPrint("Plugin native permission request result: $result");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleState = state;
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
      // Check if already logged in first to avoid error 200
      bool isLoggedIn = await ChatClient.getInstance.isConnected();
      if (!isLoggedIn) {
        try {
          await ChatUIKit.instance.loginWithToken(
            userId: userId,
            token: chatToken,
          );
        } on agora_sdk.ChatError catch (e) {
          // Error 200 means already logged in. Treat as success.
          if (e.code == 200) {
            debugPrint("User already logged in (Error 200). Proceeding.");
          } else {
            rethrow;
          }
        }
      } else {
        debugPrint("User already logged in (isConnected=true). Proceeding.");
      }

      // Save valid login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);

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

      if (_pendingNavigationUserId != null) {
        // Navigate to the pending chat
        _navigateToChat(_pendingNavigationUserId!, _pendingNavigationUserId!);
        // Clear it
        setState(() {
          _pendingNavigationUserId = null;
        });
      } else {
        _navigateToConversations();
      }
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
      // Clear saved login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user_id');

      setState(() {
        _isLoggedIn = false;
        _pendingNavigationUserId = null;
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

  void _navigateToChat(String userId, String username) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(userId: userId, username: username),
      ),
    );
  }

  void onReceiveCall(
    String userId,
    String callId,
    AgoraChatCallType callType,
    Map<String, String>? ext,
  ) async {
    // Only handle calls if logged in
    if (_isLoggedIn) {
      pushToCallPage([userId], callType, callId);
    }
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
    WidgetsBinding.instance.removeObserver(this);
    AgoraChatCallManager.removeEventListener("UNIQUE_HANDLER_ID");
    super.dispose();
  }

  void _handlePush(Map<String, dynamic> data) async {
    debugPrint("Handling push data: $data");
    if (data.containsKey("callId")) {
      // incoming call
      final String fromUserId = data["f"];
      final String fromUserName = data["u"] ?? fromUserId;
      final String callId = data["callId"];
      final bool isVideo = data["callType"] == "video";
      final callType = isVideo
          ? AgoraChatCallType.video_1v1
          : AgoraChatCallType.audio_1v1;

      // If app is in background, show Local Notification
      if (_appLifecycleState != AppLifecycleState.resumed) {
        await _showLocalNotificationCall(fromUserName, data);
        return;
      }

      if (_isLoggedIn) {
        pushToCallPage([fromUserId], callType, callId);
      } else {
        debugPrint("Not logged in, queuing call logic logic or ignoring");
      }
      return;
    }

    // default = chat message push
    final String fromUserId = data["f"];
    final String username =
        data["u"] ?? ""; // payload usually has 'u' for username

    if (_isLoggedIn) {
      _navigateToChat(fromUserId, username);
    } else {
      // Save for after login
      debugPrint(
        "Not logged in. Saving pending chat navigation for $fromUserId",
      );
      _pendingNavigationUserId = fromUserId;
    }
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
            bool shouldShow = true;
            if (_appLifecycleState == AppLifecycleState.resumed) {
              if (ChatState.currentChatUserId == message.from) {
                shouldShow = false;
              }
            }

            if (shouldShow && message.body.type == agora_sdk.MessageType.TXT) {
              final txtBody = message.body as ChatTextMessageBody;

              // Check if this is a call invite message
              if (txtBody.content == "invite info: voice" ||
                  txtBody.content == "invite info: video") {
                final bool isVideo = txtBody.content.contains("video");

                // Try to find a callId/channelId in attributes
                // Note: Agora Chat CallKit usually puts details in attributes.
                // If not available, we use messageId as a fallback unique ID.
                String callId = message.msgId;
                if (message.attributes != null &&
                    message.attributes!.containsKey("callId")) {
                  callId = message.attributes!["callId"] as String;
                }

                if (_appLifecycleState != AppLifecycleState.resumed) {
                  final Map<String, dynamic> data = {
                    'f': message.from,
                    'u': message.from,
                    'callId': callId,
                    'callType': isVideo ? 'video' : 'voice',
                  };
                  await _showLocalNotificationCall(
                    message.from ?? "Unknown",
                    data,
                  );
                }
                // Do NOT show standard local notification for calls
                continue;
              }

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
    debugPrint("Showing local notification: $title, $body");

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

  Future<void> _showLocalNotificationCall(
    String fromUserName,
    Map<String, dynamic> data,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'incoming_calls',
          'Incoming Calls',
          channelDescription: 'Notifications for incoming voice/video calls',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call,
          playSound: true,
        );
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'system_ringtone_default.aiff',
    );

    final payload = jsonEncode({'type': 'call', 'data': data});

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1, // distinct ID
      'Incoming Call',
      '$fromUserName is calling...',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }
}
