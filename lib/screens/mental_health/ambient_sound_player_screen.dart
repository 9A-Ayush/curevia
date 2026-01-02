import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

/// Ambient Sound Player Screen for meditation and relaxation
class AmbientSoundPlayerScreen extends StatefulWidget {
  final String soundName;
  final String soundFile;
  final IconData icon;
  final Color color;

  const AmbientSoundPlayerScreen({
    super.key,
    required this.soundName,
    required this.soundFile,
    required this.icon,
    required this.color,
  });

  @override
  State<AmbientSoundPlayerScreen> createState() =>
      _AmbientSoundPlayerScreenState();
}

class _AmbientSoundPlayerScreenState extends State<AmbientSoundPlayerScreen>
    with TickerProviderStateMixin {
  bool _isPlaying = false;
  double _volume = 0.7;
  Timer? _sessionTimer;
  int _timeRemaining = 0;
  bool _hasTimer = false;

  late AudioPlayer _audioPlayer;

  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  final List<int> _timerOptions = [
    300,
    600,
    900,
    1200,
    1800,
  ]; // 5, 10, 15, 20, 30 minutes

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * pi,
    ).animate(CurvedAnimation(parent: _waveController, curve: Curves.linear));
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _sessionTimer?.cancel();
    super.dispose();
  }

  void _initializeAudio() async {
    try {
      // Set up audio player for looping
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_volume);

      // Load audio from local assets
      final assetPath = 'sounds/${widget.soundFile}';
      await _audioPlayer.setSource(AssetSource(assetPath));
      
      print('Audio initialized successfully: $assetPath');
    } catch (e) {
      print('Audio initialization failed: $e');
      // Audio initialization failed - will use visual-only mode
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.soundName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(_hasTimer ? Icons.timer : Icons.timer_off),
            onPressed: _showTimerDialog,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              widget.color.withOpacity(0.3),
              Colors.black,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Sound Visualization
                Expanded(child: Center(child: _buildSoundVisualization())),

                // Timer Display
                if (_hasTimer && _timeRemaining > 0) _buildTimerDisplay(),

                const SizedBox(height: 40),

                // Volume Control
                _buildVolumeControl(),

                const SizedBox(height: 32),

                // Play/Pause Button
                _buildPlayButton(),

                const SizedBox(height: 24),

                // Sound Description
                _buildSoundDescription(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundVisualization() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ripple effect
        if (_isPlaying) ...[
          AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(300, 300),
                painter: WaveRipplePainter(
                  animation: _waveAnimation.value,
                  color: widget.color,
                ),
              );
            },
          ),
        ],

        // Main sound icon with pulse
        AnimatedBuilder(
          animation: _isPlaying
              ? _pulseAnimation
              : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.2),
                  border: Border.all(color: widget.color, width: 3),
                  boxShadow: _isPlaying
                      ? [
                          BoxShadow(
                            color: widget.color.withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ]
                      : null,
                ),
                child: Icon(widget.icon, size: 80, color: widget.color),
              ),
            );
          },
        ),

        // Play/pause overlay
        if (!_isPlaying)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.7),
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
          ),
      ],
    );
  }

  Widget _buildTimerDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: widget.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: widget.color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, color: widget.color, size: 20),
          const SizedBox(width: 8),
          Text(
            _formatTime(_timeRemaining),
            style: TextStyle(
              color: widget.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeControl() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.volume_down, color: Colors.white.withOpacity(0.7)),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: widget.color,
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  thumbColor: widget.color,
                  overlayColor: widget.color.withOpacity(0.2),
                ),
                child: Slider(
                  value: _volume,
                  onChanged: (value) {
                    setState(() {
                      _volume = value;
                    });
                    // Update audio player volume
                    _audioPlayer.setVolume(_volume);
                  },
                ),
              ),
            ),
            Icon(Icons.volume_up, color: Colors.white.withOpacity(0.7)),
          ],
        ),
        Text(
          'Volume: ${(_volume * 100).round()}%',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _togglePlayback,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildSoundDescription() {
    final descriptions = {
      'Rain':
          'Gentle rainfall creates a peaceful atmosphere, perfect for relaxation and focus.',
      'Ocean Waves':
          'Rhythmic ocean waves provide a natural, calming soundscape for meditation.',
      'Forest':
          'Immerse yourself in the tranquil sounds of nature with birds and rustling leaves.',
      'White Noise':
          'Consistent background noise helps mask distractions and improve concentration.',
      'Singing Bowls':
          'Traditional Tibetan singing bowls create harmonic tones for deep meditation.',
      'Birds':
          'Gentle bird songs bring the serenity of nature to your meditation practice.',
      'Thunderstorm':
          'Distant thunder and rain create a powerful yet soothing natural symphony.',
      'Campfire':
          'Crackling fire sounds evoke warmth and comfort, perfect for cozy meditation.',
      'Wind Chimes':
          'Delicate chimes dancing in the breeze create ethereal, peaceful melodies.',
      'Waterfall':
          'Cascading water sounds provide a continuous, refreshing natural backdrop.',
      'Night Crickets':
          'Evening cricket songs create a serene nighttime atmosphere for deep relaxation.',
      'Cafe Ambience':
          'Gentle coffee shop sounds with soft chatter and ambient noise for focus.',
      'Piano Meditation':
          'Soft, contemplative piano melodies designed specifically for meditation.',
      'Tibetan Chants':
          'Sacred Tibetan mantras and chants for spiritual meditation and mindfulness.',
      'Mountain Wind':
          'High-altitude wind sounds create a sense of vastness and tranquility.',
      'River Stream':
          'Babbling brook sounds provide gentle, continuous water flow for peace.',
      'Desert Wind':
          'Subtle desert breeze creates a minimalist, spacious soundscape for clarity.',
      'Monastery Bells':
          'Sacred temple bells ring softly, creating a spiritual meditation atmosphere.',
    };

    return Column(
      children: [
        Text(
          widget.soundName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descriptions[widget.soundName] ??
              'Relaxing ambient sound for meditation.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: widget.color.withOpacity(0.3)),
          ),
          child: Text(
            '💡 Tip: Focus on the breathing animation and imagine the peaceful sounds of ${widget.soundName.toLowerCase()}. Let your mind relax and follow the rhythm.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      // Stop audio and visual meditation
      try {
        await _audioPlayer.pause();
      } catch (e) {
        print('Error pausing audio: $e');
      }

      _pulseController.stop();
      _waveController.stop();
      _sessionTimer?.cancel();

      setState(() {
        _isPlaying = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meditation session paused'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.grey[600],
          ),
        );
      }
    } else {
      // Start audio and visual meditation
      setState(() {
        _isPlaying = true;
      });

      try {
        // Try to play audio from local assets
        await _audioPlayer.setVolume(_volume);
        await _audioPlayer.resume();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎵 Playing ${widget.soundName}...'),
              duration: const Duration(seconds: 2),
              backgroundColor: widget.color,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // Give a moment for audio to start
        await Future.delayed(const Duration(milliseconds: 300));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${widget.soundName} is now playing!'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        print('Error playing audio: $e');
        // Audio failed, show visual-only message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🧘‍♀️ ${widget.soundName} visual meditation started. Audio may not be available.',
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: widget.color,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      // Start visual animations
      _pulseController.repeat(reverse: true);
      _waveController.repeat();

      // Play a system sound to indicate start
      HapticFeedback.lightImpact();

      if (_hasTimer) {
        _startTimer();
      }
    }
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose how long to play the sound:'),
            const SizedBox(height: 16),
            ...(_timerOptions.map((seconds) {
              final minutes = seconds ~/ 60;
              return ListTile(
                title: Text('$minutes minutes'),
                onTap: () {
                  setState(() {
                    _timeRemaining = seconds;
                    _hasTimer = true;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList()),
            ListTile(
              title: const Text('No timer'),
              onTap: () {
                setState(() {
                  _hasTimer = false;
                  _timeRemaining = 0;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startTimer() {
    _sessionTimer?.cancel(); // Cancel any existing timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _sessionTimer?.cancel();
        _audioPlayer.pause(); // Stop the audio
        setState(() {
          _isPlaying = false;
          _hasTimer = false;
        });
        _pulseController.stop();
        _waveController.stop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🧘‍♀️ Timer finished. Meditation session completed!'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class WaveRipplePainter extends CustomPainter {
  final double animation;
  final Color color;

  WaveRipplePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw multiple ripple circles
    for (int i = 0; i < 3; i++) {
      final radius = (size.width / 2) * (animation + i * 0.3) % 1.5;
      final opacity = (1.0 - (animation + i * 0.3) % 1.0) * 0.5;

      paint.color = color.withOpacity(opacity);
      canvas.drawCircle(center, radius * 100, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
