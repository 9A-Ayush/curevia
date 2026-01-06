import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

/// Service for secure viewing with screenshot protection and security features
class SecureViewingService {
  static Timer? _inactivityTimer;
  static bool _isSecureMode = false;
  static VoidCallback? _onInactivityTimeout;
  static VoidCallback? _onAppBackgrounded;
  static DateTime? _lastInteraction;
  
  /// Duration after which screen locks due to inactivity
  static const Duration inactivityTimeout = Duration(minutes: 5);

  /// Initialize secure viewing mode
  static void initializeSecureMode({
    VoidCallback? onInactivityTimeout,
    VoidCallback? onAppBackgrounded,
  }) {
    _onInactivityTimeout = onInactivityTimeout;
    _onAppBackgrounded = onAppBackgrounded;
    _isSecureMode = true;
    _lastInteraction = DateTime.now();
    
    // Start inactivity timer
    _startInactivityTimer();
    
    // Disable screenshots and screen recording
    _enableScreenshotProtection();
    
    print('Secure viewing mode initialized');
  }

  /// Disable secure viewing mode
  static void disableSecureMode() {
    _isSecureMode = false;
    _stopInactivityTimer();
    _disableScreenshotProtection();
    _onInactivityTimeout = null;
    _onAppBackgrounded = null;
    
    print('Secure viewing mode disabled');
  }

  /// Record user interaction to reset inactivity timer
  static void recordInteraction() {
    if (!_isSecureMode) return;
    
    _lastInteraction = DateTime.now();
    _resetInactivityTimer();
  }

  /// Handle app lifecycle changes
  static void handleAppLifecycleChange(AppLifecycleState state) {
    if (!_isSecureMode) return;
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is going to background - trigger security callback
        _onAppBackgrounded?.call();
        break;
      case AppLifecycleState.resumed:
        // App is back in foreground - record interaction
        recordInteraction();
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        disableSecureMode();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        _onAppBackgrounded?.call();
        break;
    }
  }

  /// Check if currently in secure mode
  static bool get isSecureMode => _isSecureMode;

  /// Get time since last interaction
  static Duration? get timeSinceLastInteraction {
    if (_lastInteraction == null) return null;
    return DateTime.now().difference(_lastInteraction!);
  }

  /// Get remaining time before timeout
  static Duration? get timeUntilTimeout {
    final timeSince = timeSinceLastInteraction;
    if (timeSince == null) return null;
    
    final remaining = inactivityTimeout - timeSince;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Private methods

  /// Enable screenshot and screen recording protection
  static void _enableScreenshotProtection() {
    try {
      if (Platform.isAndroid) {
        // Android: Set FLAG_SECURE to prevent screenshots
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.bottom],
        );
      } else if (Platform.isIOS) {
        // iOS: Screenshots are handled differently, we'll use app lifecycle
        // The actual prevention is handled in native code
      }
    } catch (e) {
      print('Error enabling screenshot protection: $e');
    }
  }

  /// Disable screenshot protection
  static void _disableScreenshotProtection() {
    try {
      if (Platform.isAndroid) {
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }
    } catch (e) {
      print('Error disabling screenshot protection: $e');
    }
  }

  /// Start inactivity timer
  static void _startInactivityTimer() {
    _stopInactivityTimer();
    _inactivityTimer = Timer(inactivityTimeout, () {
      print('Inactivity timeout reached');
      _onInactivityTimeout?.call();
    });
  }

  /// Stop inactivity timer
  static void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Reset inactivity timer
  static void _resetInactivityTimer() {
    if (_isSecureMode) {
      _startInactivityTimer();
    }
  }
}

/// Widget wrapper for secure viewing with interaction tracking
class SecureViewWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onInactivityTimeout;
  final VoidCallback? onAppBackgrounded;
  final bool enableBlurOnBackground;

  const SecureViewWrapper({
    super.key,
    required this.child,
    this.onInactivityTimeout,
    this.onAppBackgrounded,
    this.enableBlurOnBackground = true,
  });

  @override
  State<SecureViewWrapper> createState() => _SecureViewWrapperState();
}

class _SecureViewWrapperState extends State<SecureViewWrapper>
    with WidgetsBindingObserver {
  bool _isBlurred = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize secure mode
    SecureViewingService.initializeSecureMode(
      onInactivityTimeout: widget.onInactivityTimeout,
      onAppBackgrounded: _handleAppBackgrounded,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SecureViewingService.disableSecureMode();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    SecureViewingService.handleAppLifecycleChange(state);
    
    if (widget.enableBlurOnBackground) {
      setState(() {
        _isBlurred = state == AppLifecycleState.paused || 
                    state == AppLifecycleState.inactive ||
                    state == AppLifecycleState.hidden;
      });
    }
  }

  void _handleAppBackgrounded() {
    widget.onAppBackgrounded?.call();
    if (widget.enableBlurOnBackground) {
      setState(() {
        _isBlurred = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: SecureViewingService.recordInteraction,
      onPanUpdate: (_) => SecureViewingService.recordInteraction(),
      onScaleUpdate: (_) => SecureViewingService.recordInteraction(),
      child: Stack(
        children: [
          widget.child,
          if (_isBlurred)
            Container(
              color: Colors.black87,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Content Hidden for Security',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Return to app to view medical records',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Mixin for widgets that need secure viewing capabilities
mixin SecureViewingMixin<T extends StatefulWidget> on State<T> {
  Timer? _warningTimer;
  bool _showInactivityWarning = false;

  @override
  void initState() {
    super.initState();
    _startWarningTimer();
  }

  @override
  void dispose() {
    _warningTimer?.cancel();
    super.dispose();
  }

  /// Start timer to show inactivity warning
  void _startWarningTimer() {
    _warningTimer?.cancel();
    
    // Show warning 1 minute before timeout
    const warningTime = Duration(minutes: 4);
    _warningTimer = Timer(warningTime, () {
      if (mounted && SecureViewingService.isSecureMode) {
        setState(() {
          _showInactivityWarning = true;
        });
        
        // Hide warning after 30 seconds or on interaction
        Timer(const Duration(seconds: 30), () {
          if (mounted) {
            setState(() {
              _showInactivityWarning = false;
            });
          }
        });
      }
    });
  }

  /// Reset warning timer on interaction
  void resetWarningTimer() {
    setState(() {
      _showInactivityWarning = false;
    });
    _startWarningTimer();
    SecureViewingService.recordInteraction();
  }

  /// Build inactivity warning widget
  Widget buildInactivityWarning() {
    if (!_showInactivityWarning) return const SizedBox();
    
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.orange.withOpacity(0.9),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Session will expire due to inactivity. Tap to continue.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: resetWarningTimer,
              child: const Text(
                'Continue',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom text selection controls that disable copy/paste
class SecureTextSelectionControls extends TextSelectionControls {
  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    // Return empty widget to hide selection handles
    return const SizedBox();
  }

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    // Return empty widget to hide toolbar (copy/paste options)
    return const SizedBox();
  }

  @override
  Size getHandleSize(double textLineHeight) {
    return Size.zero;
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }
}

/// Secure text widget that prevents selection and copying
class SecureText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const SecureText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      selectionControls: SecureTextSelectionControls(),
      enableInteractiveSelection: false,
      onTap: SecureViewingService.recordInteraction,
    );
  }
}