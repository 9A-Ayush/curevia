import 'package:flutter/material.dart';
import 'dart:async';

/// Guided Meditation Session Screen with actual meditation content
class GuidedMeditationSessionScreen extends StatefulWidget {
  final String title;
  final String description;
  final String duration;
  final Color color;

  const GuidedMeditationSessionScreen({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    required this.color,
  });

  @override
  State<GuidedMeditationSessionScreen> createState() =>
      _GuidedMeditationSessionScreenState();
}

class _GuidedMeditationSessionScreenState
    extends State<GuidedMeditationSessionScreen>
    with TickerProviderStateMixin {
  Timer? _sessionTimer;
  Timer? _stepTimer;
  int _currentStepIndex = 0;
  int _stepTimeRemaining = 0;
  bool _isSessionActive = false;
  bool _isPaused = false;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  List<MeditationStep> _steps = [];

  @override
  void initState() {
    super.initState();
    _initializeSteps();
    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _breathingAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _stepTimer?.cancel();
    _breathingController.dispose();
    super.dispose();
  }

  void _initializeSteps() {
    switch (widget.title) {
      case 'Mindful Breathing':
        _steps = [
          MeditationStep(
            'Welcome',
            'Find a comfortable position and close your eyes.',
            30,
          ),
          MeditationStep(
            'Settle In',
            'Take a moment to notice your body and surroundings.',
            45,
          ),
          MeditationStep(
            'Natural Breath',
            'Begin to notice your natural breathing pattern.',
            60,
          ),
          MeditationStep(
            'Focus',
            'Focus your attention on the sensation of breathing.',
            120,
          ),
          MeditationStep(
            'Deep Practice',
            'Continue focusing on your breath. When your mind wanders, gently return to your breath.',
            180,
          ),
          MeditationStep(
            'Closing',
            'Take three deep breaths and slowly open your eyes.',
            30,
          ),
        ];
        break;
      case 'Body Scan':
        _steps = [
          MeditationStep(
            'Preparation',
            'Lie down comfortably and close your eyes.',
            30,
          ),
          MeditationStep(
            'Head & Face',
            'Focus on your head, face, and jaw. Notice any tension and let it go.',
            90,
          ),
          MeditationStep(
            'Neck & Shoulders',
            'Move your attention to your neck and shoulders. Breathe and relax.',
            90,
          ),
          MeditationStep(
            'Arms & Hands',
            'Focus on your arms and hands. Feel them becoming heavy and relaxed.',
            90,
          ),
          MeditationStep(
            'Chest & Back',
            'Notice your chest rising and falling. Relax your back muscles.',
            90,
          ),
          MeditationStep(
            'Abdomen',
            'Focus on your abdomen. Feel it expanding and contracting with each breath.',
            90,
          ),
          MeditationStep(
            'Legs & Feet',
            'Move attention to your legs and feet. Let them sink into the surface.',
            90,
          ),
          MeditationStep(
            'Whole Body',
            'Feel your entire body relaxed and at peace.',
            60,
          ),
          MeditationStep(
            'Closing',
            'Slowly wiggle your fingers and toes, then gently open your eyes.',
            30,
          ),
        ];
        break;
      case 'Loving Kindness':
        _steps = [
          MeditationStep(
            'Centering',
            'Sit comfortably and take a few deep breaths.',
            30,
          ),
          MeditationStep(
            'Self-Love',
            'Place your hand on your heart. Send loving kindness to yourself: "May I be happy, may I be peaceful."',
            120,
          ),
          MeditationStep(
            'Loved One',
            'Think of someone you love. Send them loving kindness: "May you be happy, may you be peaceful."',
            120,
          ),
          MeditationStep(
            'Neutral Person',
            'Think of someone neutral. Extend loving kindness to them.',
            120,
          ),
          MeditationStep(
            'Difficult Person',
            'Think of someone challenging. Try to send them loving kindness.',
            120,
          ),
          MeditationStep(
            'All Beings',
            'Extend loving kindness to all beings everywhere: "May all beings be happy and free."',
            120,
          ),
          MeditationStep(
            'Closing',
            'Return to your breath and slowly open your eyes.',
            30,
          ),
        ];
        break;
      case 'Sleep Meditation':
        _steps = [
          MeditationStep(
            'Preparation',
            'Lie down in bed and get comfortable.',
            60,
          ),
          MeditationStep(
            'Body Release',
            'Starting from your toes, consciously relax each part of your body.',
            180,
          ),
          MeditationStep(
            'Breath Awareness',
            'Focus on slow, deep breathing. Let each exhale release tension.',
            240,
          ),
          MeditationStep(
            'Peaceful Imagery',
            'Imagine a peaceful place where you feel completely safe and calm.',
            300,
          ),
          MeditationStep(
            'Letting Go',
            'Release all thoughts and worries. Let yourself drift into peaceful sleep.',
            300,
          ),
        ];
        break;
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
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        actions: [
          if (_isSessionActive)
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
              onPressed: _togglePause,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              widget.color.withOpacity(0.3),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Session Info
                if (!_isSessionActive) _buildSessionInfo(),

                // Active Session Content
                if (_isSessionActive) _buildActiveSession(),

                const Spacer(),

                // Control Button
                _buildControlButton(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.2),
            border: Border.all(color: widget.color, width: 2),
          ),
          child: Icon(Icons.self_improvement, size: 60, color: widget.color),
        ),
        const SizedBox(height: 32),
        Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          widget.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.color.withOpacity(0.5)),
          ),
          child: Text(
            'Duration: ${widget.duration}',
            style: TextStyle(color: widget.color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSession() {
    final currentStep = _currentStepIndex < _steps.length
        ? _steps[_currentStepIndex]
        : null;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress Indicator
          Container(
            margin: const EdgeInsets.only(bottom: 32),
            child: Row(
              children: List.generate(_steps.length, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index <= _currentStepIndex
                          ? widget.color
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Breathing Animation (for breathing meditation)
          if (widget.title == 'Mindful Breathing' &&
              _isSessionActive &&
              !_isPaused)
            AnimatedBuilder(
              animation: _breathingAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _breathingAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.color.withOpacity(0.3),
                      border: Border.all(color: widget.color, width: 2),
                    ),
                    child: Icon(Icons.air, size: 60, color: widget.color),
                  ),
                );
              },
            ),

          if (widget.title != 'Mindful Breathing' ||
              !_isSessionActive ||
              _isPaused)
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.2),
                border: Border.all(color: widget.color, width: 2),
              ),
              child: Center(
                child: Text(
                  _formatTime(_stepTimeRemaining),
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 40),

          // Current Step
          if (currentStep != null) ...[
            Text(
              currentStep.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              currentStep.instruction,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSessionActive ? _stopSession : _startSession,
        icon: Icon(_isSessionActive ? Icons.stop : Icons.play_arrow),
        label: Text(_isSessionActive ? 'End Session' : 'Start Meditation'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isSessionActive ? Colors.red : widget.color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _startSession() {
    setState(() {
      _isSessionActive = true;
      _currentStepIndex = 0;
      _stepTimeRemaining = _steps[0].duration;
    });

    _startStepTimer();

    if (widget.title == 'Mindful Breathing') {
      _breathingController.repeat(reverse: true);
    }
  }

  void _stopSession() {
    _sessionTimer?.cancel();
    _stepTimer?.cancel();
    _breathingController.stop();

    setState(() {
      _isSessionActive = false;
      _isPaused = false;
      _currentStepIndex = 0;
    });

    Navigator.pop(context);
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _stepTimer?.cancel();
      _breathingController.stop();
    } else {
      _startStepTimer();
      if (widget.title == 'Mindful Breathing') {
        _breathingController.repeat(reverse: true);
      }
    }
  }

  void _startStepTimer() {
    _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _stepTimeRemaining--;
        });

        if (_stepTimeRemaining <= 0) {
          _nextStep();
        }
      }
    });
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _stepTimeRemaining = _steps[_currentStepIndex].duration;
      });
    } else {
      // Session completed
      _stepTimer?.cancel();
      _breathingController.stop();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Session Complete'),
          content: const Text(
            'Congratulations! You have completed your meditation session.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class MeditationStep {
  final String title;
  final String instruction;
  final int duration; // in seconds

  MeditationStep(this.title, this.instruction, this.duration);
}
