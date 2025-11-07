# p2p_chat_with_agora_ui_kit

Flutter project with agora UI kit.

## Getting Started

const String appKey = "";
const String agoraAppId = "";
const String userId = '';
const String token ="";

are mandatory



Generate RTC temp tokens

In the Agora Console → Generate Temporary Token page:

Enter Channel Name → p2p_test

Click Generate 

Copy that token → give it to User A

Click Generate again (it gives a different token for the same channel) → give that to User B

then go to package file ->
AgoraChatCallKitTools.dart create a function static String get channelStr {
    return "p2p_test5";
  }

then go to package file agora_chat_manager: 
line 608 change to channel: AgoraChatCallKitTools.channelStr, and line 527 change to : channel: AgoraChatCallKitTools.channelStr,