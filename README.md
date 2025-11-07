# Flutter P2P Chat with Agora UI Kit

A real-time peer-to-peer chat application built with Flutter and Agora UI Kit.

## 🚀 Getting Started

### Prerequisites

Before running the application, you need to configure the following mandatory constants in your project:

```dart
const String appKey = "";        // Your Agora App Key
const String agoraAppId = "";    // Your Agora App ID  
const String channelId = "";     // Channel ID for communication
const String tempToken = "";     // Agora RTC Token

const List<Map<String, String>> staticUsers = [
  {
    "id": '',
    "token": "",
    "channelToken": "",
  },
  {
    "id": '',
    "token": "",
    "channelToken": "",
  },
];
```

### 🔑 Token Generation

#### RTC Token Generation
To generate temporary RTC tokens:

1. Go to **Agora Console** → **Generate Temporary Token** page
2. Enter your Channel Name
3. Click **Generate**
4. Copy the token and assign it to User A
5. Click **Generate** again (this creates a different token for the same channel)
6. Copy the new token and assign it to User B

#### Chat User Token Generation
The `"token"` in `staticUsers` is created from:
- **Agora Console** → **Chat** → **Basic Information** → **Chat User Temp Token**

### 🛠 Server Setup

#### Node.js Token Server
1. **Clone and run the token server**:
   ```bash
   git clone https://github.com/Benjith/node_agora_RtcTokenBuilder
   cd node_agora_RtcTokenBuilder
   npm install
   node server.js
   ```

2. **Update IP Address in Flutter App**:
   - Open `main.dart` file
   - Locate the server configuration section
   - Change the IP address to match your local server IP:
   ```dart
   // In main.dart, update the base URL to your Node.js server IP
   await dioClient.Dio().get("http://YOUR_LOCAL_IP:8000"; // Replace with your actual IP
   ```

3. **Get your local IP address**:
   - **Windows**: Run `ipconfig` in command prompt
   - **Mac/Linux**: Run `ifconfig` in terminal
   - Look for your local IP (usually starting with `192.168.` or `10.0.`)

### ⚙️ Configuration Steps

1. **Set Channel Name**  
   In `AgoraChatCallKitTools.dart`, create the channel function:
   ```dart
   static String get channelStr {
     return "your_channel_name_here";
   }
   ```

2. **Update Channel References**  
   In `agora_chat_manager`:
   - Line 608: Change to `channel: AgoraChatCallKitTools.channelStr`
   - Line 527: Change to `channel: AgoraChatCallKitTools.channelStr`

### 🔗 Additional Resources

- **Lightweight Node.js RTC Token Builder**:  
  [https://github.com/Benjith/node_agora_RtcTokenBuilder](https://github.com/Benjith/node_agora_RtcTokenBuilder)

## 📱 Features

- Real-time peer-to-peer messaging
- Agora UI Kit integration
- Secure token-based authentication
- Multiple user support with static user configuration
- Easy channel configuration
- Local token server for development

---

*For detailed implementation guide, refer to the Agora documentation.*