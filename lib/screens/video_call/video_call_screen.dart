import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'dart:async';
import '../../services/agora/agora_service.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String token;
  final int uid;
  final String? doctorName;
  final String? patientName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.token,
    required this.uid,
    this.doctorName,
    this.patientName,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  bool _isMuted = false;
  bool _isVideoDisabled = false;
  bool _isSpeakerEnabled = true;
  bool _isConnecting = true;
  int _callDuration = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    // Initialize Agora
    final initialized = await AgoraService.initialize();
    
    if (!initialized) {
      _showError('Failed to initialize video call');
      return;
    }

    // Register event handlers
    AgoraService.engine?.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('Local user joined: ${connection.localUid}');
          setState(() => _isConnecting = false);
          _startTimer();
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint('Remote user joined: $remoteUid');
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint('Remote user left: $remoteUid');
          setState(() => _remoteUid = null);
        },
        onError: (err, msg) {
          debugPrint('Agora error: $err - $msg');
        },
      ),
    );

    // Join channel
    final joined = await AgoraService.joinChannel(
      token: widget.token,
      channelName: widget.channelName,
      uid: widget.uid,
    );

    if (!joined) {
      _showError('Failed to join video call');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _callDuration++);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    Navigator.pop(context);
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video (full screen)
          if (_remoteUid != null)
            AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: AgoraService.engine!,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
          else
            _buildWaitingView(),

          // Local video (small preview)
          if (!_isVideoDisabled)
            Positioned(
              top: 60,
              right: 20,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: AgoraService.engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),

          // Top bar with info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildControls(),
          ),

          // Connecting overlay
          if (_isConnecting)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Connecting...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWaitingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.white54,
            ),
            const SizedBox(height: 24),
            Text(
              widget.doctorName ?? widget.patientName ?? 'Participant',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Waiting to join...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.doctorName ?? widget.patientName ?? 'Video Call',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDuration(_callDuration),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          IconButton(
            onPressed: () => AgoraService.switchCamera(),
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            onPressed: () {
              setState(() => _isMuted = !_isMuted);
              AgoraService.toggleMute(_isMuted);
            },
            color: _isMuted ? Colors.red : Colors.white,
          ),
          _buildControlButton(
            icon: Icons.call_end,
            onPressed: _endCall,
            color: Colors.red,
            size: 70,
          ),
          _buildControlButton(
            icon: _isVideoDisabled ? Icons.videocam_off : Icons.videocam,
            onPressed: () {
              setState(() => _isVideoDisabled = !_isVideoDisabled);
              AgoraService.toggleVideo(_isVideoDisabled);
            },
            color: _isVideoDisabled ? Colors.red : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    double size = 60,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.3),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.5,
        ),
      ),
    );
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    await AgoraService.leaveChannel();
    
    if (mounted) {
      Navigator.pop(context, {
        'duration': _callDuration,
        'completed': true,
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    AgoraService.dispose();
    super.dispose();
  }
}
