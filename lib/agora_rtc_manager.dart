// import 'package:agora_rtc_engine/agora_rtc_engine.dart';

// class AgoraRtcManager {
//   static RtcEngine? _engine;

//   static Future<void> init(String appId) async {
//     if (_engine != null) return; // prevent reinit
//     _engine = createAgoraRtcEngine();
//     await _engine!.initialize(
//       RtcEngineContext(
//         appId: appId,
//         channelProfile: ChannelProfileType.channelProfileCommunication,
//       ),
//     );

//     // Enable audio by default
//     await _engine!.enableAudio();
//   }

//   static Future<void> joinChannel({
//     required String token,
//     required String channelId,
//     required int uid,
//   }) async {
//     await _engine?.joinChannel(
//       token: token,
//       channelId: channelId,
//       uid: uid,
//       options: const ChannelMediaOptions(),
//     );
//   }

//   static Future<void> leaveChannel() async {
//     await _engine?.leaveChannel();
//   }

//   static Future<void> dispose() async {
//     await _engine?.release();
//     _engine = null;
//   }
// }
