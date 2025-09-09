import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for managing doctor navigation state
class DoctorNavigationNotifier extends StateNotifier<int> {
  DoctorNavigationNotifier() : super(0);

  void setTabIndex(int index) {
    state = index;
  }

  void goToDashboard() => setTabIndex(0);
  void goToAppointments() => setTabIndex(1);
  void goToPatients() => setTabIndex(2);
  void goToAnalytics() => setTabIndex(3);
  void goToProfile() => setTabIndex(4);
}

final doctorNavigationProvider = StateNotifierProvider<DoctorNavigationNotifier, int>(
  (ref) => DoctorNavigationNotifier(),
);
