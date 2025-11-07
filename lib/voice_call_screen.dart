import 'package:flutter/material.dart';
import 'package:p2p_chat_with_agora_ui_kit/agora_rtc_manager.dart';

class VoiceCallScreen extends StatefulWidget {
  final String channelId;
  final String contactName;
  final AgoraRtcManager agoraManager;

  const VoiceCallScreen({
    required this.channelId,
    required this.contactName,
    required this.agoraManager,
    super.key,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen>
    with SingleTickerProviderStateMixin {
  bool _isJoined = false;
  bool _isLoading = true;
  bool _isMuted = false;
  bool _isSpeakerOn = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _joinChannel();
    _setupAnimation();
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _joinChannel() async {
    try {
      await widget.agoraManager.joinChannel(
        token: '',
        channelId: widget.channelId,
        uid: 0,
      );

      setState(() {
        _isJoined = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join channel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveChannel() async {
    await widget.agoraManager.leaveChannel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    // Implement actual mute functionality with Agora
    widget.agoraManager.engine!.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    // Implement actual speaker functionality with Agora
    widget.agoraManager.engine!.setEnableSpeakerphone(_isSpeakerOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
          child: Column(
            children: [
              // Header with time and status
              _buildHeader(),

              // Main content area
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Contact avatar with pulse animation
                    _buildContactAvatar(),

                    const SizedBox(height: 32),

                    // Contact name and call status
                    _buildContactInfo(),

                    const SizedBox(height: 60),

                    // Call duration (would be dynamic in real app)
                    _buildCallDuration(),
                  ],
                ),
              ),

              // Call control buttons
              _buildCallControls(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Current time
          Text(
            _formatTime(DateTime.now()),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Call status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isJoined
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isJoined ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  color: _isJoined ? Colors.green : Colors.orange,
                  size: 8,
                ),
                const SizedBox(width: 6),
                Text(
                  _isJoined ? 'Connected' : 'Connecting...',
                  style: TextStyle(
                    color: _isJoined ? Colors.green : Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAvatar() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isJoined ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    widget.contactName.isNotEmpty
                        ? widget.contactName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isLoading)
                  const Positioned.fill(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        Text(
          widget.contactName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isJoined ? 'Voice Call' : 'Establishing connection...',
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildCallDuration() {
    return Text(
      _isJoined ? '05:24' : '00:00', // This would be dynamic in real app
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCallControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute Button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            label: 'Mute',
            isActive: _isMuted,
            onPressed: _toggleMute,
            backgroundColor: _isMuted ? Colors.red : Colors.white24,
          ),

          // Speaker Button
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            label: 'Speaker',
            isActive: _isSpeakerOn,
            onPressed: _toggleSpeaker,
            backgroundColor: _isSpeakerOn ? Colors.blue : Colors.white24,
          ),

          // End Call Button
          _buildControlButton(
            icon: Icons.call_end,
            label: 'End',
            isActive: true,
            onPressed: _leaveChannel,
            backgroundColor: Colors.red,
            isEndCall: true,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isEndCall = false,
  }) {
    return Column(
      children: [
        Container(
          width: isEndCall ? 70 : 60,
          height: isEndCall ? 70 : 60,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 3,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: isEndCall ? 30 : 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
