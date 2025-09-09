import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation state for managing bottom navigation tabs
class NavigationState {
  final int currentIndex;

  const NavigationState({
    this.currentIndex = 0,
  });

  NavigationState copyWith({
    int? currentIndex,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

/// Navigation notifier for managing tab navigation
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  /// Set the current tab index
  void setCurrentIndex(int index) {
    state = state.copyWith(currentIndex: index);
  }

  /// Navigate to home tab
  void goToHome() {
    state = state.copyWith(currentIndex: 0);
  }

  /// Navigate to profile tab
  void goToProfile() {
    state = state.copyWith(currentIndex: 4);
  }
}

/// Navigation provider
final navigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

/// Current tab index provider
final currentTabIndexProvider = Provider<int>((ref) {
  return ref.watch(navigationProvider).currentIndex;
});
