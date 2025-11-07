
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraRtcManager {
  RtcEngine? engine;
  bool _isInitialized = false;

  Future<void> initialize(String appId) async {
    if (_isInitialized) return;

    // Request microphone permission
    await Permission.microphone.request();

    engine = createAgoraRtcEngine();
    await engine!.initialize(RtcEngineContext(appId: appId));

    // Set channel profile and enable audio
    await engine!.setChannelProfile(
      ChannelProfileType.channelProfileCommunication,
    );
    await engine!.enableAudio();

    _isInitialized = true;
  }

  Future<void> joinChannel({
    required String token,
    required String channelId,
    required int uid,
  }) async {
    if (!_isInitialized) {
      throw Exception('Agora RTC Engine not initialized');
    }

    await engine!.joinChannel(
      token: token,
      channelId: channelId,
      uid: uid,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> leaveChannel() async {
    await engine?.leaveChannel();
  }

  Future<void> dispose() async {
    await leaveChannel();
    await engine?.release();
    _isInitialized = false;
  }
}