import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/notifications/notification_manager.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

/// Ultra-stunning animated splash screen with mind-blowing effects
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _textController;
  late AnimationController _waveController;
  late AnimationController _orbController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _logoOpacity;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _backgroundGradient;
  late Animation<double> _waveAnimation;
  late Animation<double> _orbAnimation;
  late Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();
    
    // Set status bar to transparent for fullscreen splash
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 3500),
      vsync: this,
    );

    // Pulse animation controller
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 5000),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Wave animation controller
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Orb animation controller
    _orbController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Logo animations with enhanced curves
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _logoRotation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Enhanced pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Particle animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.linear,
      ),
    );

    // Wave animation
    _waveAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.linear,
      ),
    );

    // Orb animation
    _orbAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _orbController,
        curve: Curves.linear,
      ),
    );

    // Enhanced text animations
    _textSlide = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Enhanced background gradient animation
    _backgroundGradient = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Small delay to ensure smooth transition from native splash
    await Future.delayed(const Duration(milliseconds: 100));
    
    // Start main animation
    _mainController.forward();
    
    // Start wave animation
    _waveController.repeat();
    
    // Start orb animation
    _orbController.repeat();
    
    // Start pulse animation with repeat
    await Future.delayed(const Duration(milliseconds: 800));
    _pulseController.repeat(reverse: true);
    
    // Start particle animation
    await Future.delayed(const Duration(milliseconds: 200));
    _particleController.forward();
    
    // Start text animation
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    
    // Initialize app after animations
    _initializeApp();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _textController.dispose();
    _waveController.dispose();
    _orbController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // Start initialization in background while animations play
      final initFuture = NotificationManager.instance.initialize();
      
      // Wait for minimum splash duration to show the beautiful animations
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // Ensure initialization is complete
      await initFuture;
      
      // Check authentication state and navigate
      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      debugPrint('Error during app initialization: $e');
      // Still navigate even if there's an error
      if (mounted) {
        _navigateToNextScreen();
      }
    }
  }

  void _navigateToNextScreen() {
    final authState = ref.read(authProvider);
    
    if (authState.isAuthenticated && authState.userModel != null) {
      // User is logged in, go to home
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    } else {
      // User is not logged in, go to login
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _mainController,
          _pulseController,
          _particleController,
          _textController,
          _waveController,
          _orbController,
        ]),
        builder: (context, child) {
          return Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.8,
                colors: [
                  Color.lerp(
                    const Color(0xFF0175C2),
                    const Color(0xFF00D4AA),
                    _backgroundGradient.value * 0.4,
                  )!,
                  Color.lerp(
                    const Color(0xFF014A8A),
                    const Color(0xFF0175C2),
                    _backgroundGradient.value * 0.6,
                  )!,
                  Color.lerp(
                    const Color(0xFF001F3F),
                    const Color(0xFF003366),
                    _backgroundGradient.value * 0.3,
                  )!,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Animated wave background
                ...List.generate(3, (index) => _buildWave(index, size)),
                
                // Floating orbs
                ...List.generate(8, (index) => _buildOrb(index, size)),
                
                // Enhanced particles background
                ...List.generate(30, (index) => _buildParticle(index, size)),
                
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ultra-enhanced logo with multiple effects
                      Transform.scale(
                        scale: _logoScale.value * _pulseAnimation.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value * math.pi,
                          child: Opacity(
                            opacity: _logoOpacity.value,
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  // Multiple layered shadows for depth
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.4 * _logoGlow.value),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF00D4AA).withOpacity(0.6 * _logoGlow.value),
                                    blurRadius: 60,
                                    spreadRadius: 15,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF0175C2).withOpacity(0.8 * _logoGlow.value),
                                    blurRadius: 80,
                                    spreadRadius: 20,
                                  ),
                                  BoxShadow(
                                    color: Colors.cyan.withOpacity(0.3 * _logoGlow.value),
                                    blurRadius: 100,
                                    spreadRadius: 25,
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.3),
                                    Colors.white.withOpacity(0.1),
                                    const Color(0xFF00D4AA).withOpacity(0.2),
                                  ],
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.2),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/icons/curevia_icon.png',
                                    width: 160,
                                    height: 160,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(40),
                                        ),
                                        child: const Icon(
                                          Icons.local_hospital,
                                          size: 80,
                                          color: AppColors.primary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 50),
                      
                      // Ultra-enhanced app name with multiple effects
                      Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00D4AA).withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.white,
                                  const Color(0xFF00D4AA),
                                  Colors.cyan,
                                  Colors.white,
                                ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'Curevia',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black38,
                                      offset: Offset(0, 6),
                                      blurRadius: 12,
                                    ),
                                    Shadow(
                                      color: Color(0xFF00D4AA),
                                      offset: Offset(0, 0),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Enhanced tagline with glow effect
                      Transform.translate(
                        offset: Offset(0, _textSlide.value * 0.5),
                        child: Opacity(
                          opacity: _textOpacity.value * 0.9,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Your Smart Path to Better Health',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 70),
                      
                      // Ultra-modern loading indicator with multiple rings
                      Opacity(
                        opacity: _textOpacity.value,
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Stack(
                            children: [
                              // Outer ring
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white.withOpacity(0.2),
                                  ),
                                ),
                              ),
                              // Middle ring
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF00D4AA).withOpacity(0.8),
                                  ),
                                ),
                              ),
                              // Inner ring
                              Positioned(
                                left: 10,
                                top: 10,
                                child: SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.cyan,
                                    ),
                                  ),
                                ),
                              ),
                              // Center dot
                              Positioned(
                                left: 35,
                                top: 35,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF00D4AA),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Enhanced bottom branding
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: _textOpacity.value * 0.9,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Powered by Advanced AI & Healthcare Technology',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEnhancedFeatureBadge(Icons.security, 'Secure'),
                            const SizedBox(width: 24),
                            _buildEnhancedFeatureBadge(Icons.verified_user, 'Trusted'),
                            const SizedBox(width: 24),
                            _buildEnhancedFeatureBadge(Icons.health_and_safety, 'Reliable'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWave(int index, Size size) {
    final waveHeight = 100.0 + (index * 50);
    final waveSpeed = 1.0 + (index * 0.5);
    
    return Positioned(
      bottom: -50,
      left: 0,
      right: 0,
      child: Opacity(
        opacity: 0.1 - (index * 0.02),
        child: CustomPaint(
          size: Size(size.width, waveHeight),
          painter: WavePainter(
            waveAnimation: _waveAnimation.value * waveSpeed,
            color: const Color(0xFF00D4AA),
            waveHeight: waveHeight,
          ),
        ),
      ),
    );
  }

  Widget _buildOrb(int index, Size size) {
    final random = math.Random(index + 100);
    final orbSize = random.nextDouble() * 20 + 10;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = 150.0 + (index * 30);
    final speed = 0.5 + (index * 0.2);
    
    final x = centerX + radius * math.cos(_orbAnimation.value * speed + index);
    final y = centerY + radius * math.sin(_orbAnimation.value * speed + index) * 0.5;
    
    return Positioned(
      left: x - orbSize / 2,
      top: y - orbSize / 2,
      child: Opacity(
        opacity: (math.sin(_orbAnimation.value * 2 + index) + 1) * 0.3,
        child: Container(
          width: orbSize,
          height: orbSize,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                const Color(0xFF00D4AA).withOpacity(0.8),
                Colors.cyan.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildParticle(int index, Size size) {
    final random = math.Random(index);
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;
    final endX = random.nextDouble() * size.width;
    final endY = random.nextDouble() * size.height;
    final particleSize = random.nextDouble() * 6 + 2;
    final speed = random.nextDouble() * 0.5 + 0.5;
    
    return Positioned(
      left: math.max(0, math.min(size.width - particleSize, 
        startX + (endX - startX) * (_particleAnimation.value * speed) % 1)),
      top: math.max(0, math.min(size.height - particleSize,
        startY + (endY - startY) * (_particleAnimation.value * speed) % 1)),
      child: Opacity(
        opacity: (math.sin(_particleAnimation.value * math.pi * 4 + index) + 1) * 0.4,
        child: Container(
          width: particleSize,
          height: particleSize,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.8),
                const Color(0xFF00D4AA).withOpacity(0.6),
                Colors.transparent,
              ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFeatureBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D4AA).withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF00D4AA),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final double waveAnimation;
  final Color color;
  final double waveHeight;

  WavePainter({
    required this.waveAnimation,
    required this.color,
    required this.waveHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);

    for (double x = 0; x <= size.width; x++) {
      final y = size.height / 2 + 
          math.sin((x / size.width * 2 * math.pi) + waveAnimation) * 30;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}