import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Helper widget for enhanced swipe navigation with gestures and animations
class SwipeNavigationHelper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final bool enableHapticFeedback;
  final bool showSwipeIndicator;
  final Duration animationDuration;

  const SwipeNavigationHelper({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.enableHapticFeedback = true,
    this.showSwipeIndicator = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<SwipeNavigationHelper> createState() => _SwipeNavigationHelperState();
}

class _SwipeNavigationHelperState extends State<SwipeNavigationHelper>
    with TickerProviderStateMixin {
  late AnimationController _swipeAnimationController;
  late Animation<double> _swipeAnimation;
  late AnimationController _indicatorController;
  late Animation<double> _indicatorAnimation;

  @override
  void initState() {
    super.initState();
    _swipeAnimationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _swipeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeInOut,
    ));

    _indicatorController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _indicatorAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _indicatorController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    _indicatorController.dispose();
    super.dispose();
  }

  void _handleSwipe(DismissDirection direction) {
    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }

    _swipeAnimationController.forward().then((_) {
      _swipeAnimationController.reverse();
    });

    if (widget.showSwipeIndicator) {
      _indicatorController.forward().then((_) {
        _indicatorController.reverse();
      });
    }

    switch (direction) {
      case DismissDirection.startToEnd:
        widget.onSwipeRight?.call();
        break;
      case DismissDirection.endToStart:
        widget.onSwipeLeft?.call();
        break;
      case DismissDirection.up:
        widget.onSwipeUp?.call();
        break;
      case DismissDirection.down:
        widget.onSwipeDown?.call();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content with swipe detection
        GestureDetector(
          onPanEnd: (details) {
            final velocity = details.velocity.pixelsPerSecond;
            const minVelocity = 500.0;

            if (velocity.dx.abs() > velocity.dy.abs()) {
              // Horizontal swipe
              if (velocity.dx > minVelocity) {
                _handleSwipe(DismissDirection.startToEnd);
              } else if (velocity.dx < -minVelocity) {
                _handleSwipe(DismissDirection.endToStart);
              }
            } else {
              // Vertical swipe
              if (velocity.dy > minVelocity) {
                _handleSwipe(DismissDirection.down);
              } else if (velocity.dy < -minVelocity) {
                _handleSwipe(DismissDirection.up);
              }
            }
          },
          child: AnimatedBuilder(
            animation: _swipeAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _swipeAnimation.value,
                child: widget.child,
              );
            },
          ),
        ),

        // Swipe indicator overlay
        if (widget.showSwipeIndicator)
          AnimatedBuilder(
            animation: _indicatorAnimation,
            builder: (context, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: _indicatorAnimation.value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Enhanced swipe detector with directional callbacks
class SwipeDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final double sensitivity;

  const SwipeDetector({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.sensitivity = 50.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dx > sensitivity) {
          onSwipeRight?.call();
        } else if (details.delta.dx < -sensitivity) {
          onSwipeLeft?.call();
        } else if (details.delta.dy > sensitivity) {
          onSwipeDown?.call();
        } else if (details.delta.dy < -sensitivity) {
          onSwipeUp?.call();
        }
      },
      child: child,
    );
  }
}

/// Swipe navigation indicators for visual feedback
class SwipeIndicators extends StatelessWidget {
  final bool showLeftIndicator;
  final bool showRightIndicator;
  final bool showUpIndicator;
  final bool showDownIndicator;
  final Color? indicatorColor;

  const SwipeIndicators({
    super.key,
    this.showLeftIndicator = false,
    this.showRightIndicator = false,
    this.showUpIndicator = false,
    this.showDownIndicator = false,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = indicatorColor ?? Theme.of(context).primaryColor;

    return Stack(
      children: [
        // Left indicator
        if (showLeftIndicator)
          Positioned(
            left: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.chevron_left,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          ),

        // Right indicator
        if (showRightIndicator)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          ),

        // Up indicator
        if (showUpIndicator)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.keyboard_arrow_up,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          ),

        // Down indicator
        if (showDownIndicator)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
    );
  }
}