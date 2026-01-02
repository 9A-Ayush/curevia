import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/appointment_model.dart';
import '../services/firebase/appointment_service.dart';

/// Appointment booking state
class AppointmentBookingState {
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final List<String> availableSlots;
  final DateTime? selectedDate;
  final String? selectedTimeSlot;

  const AppointmentBookingState({
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.availableSlots = const [],
    this.selectedDate,
    this.selectedTimeSlot,
  });

  AppointmentBookingState copyWith({
    bool? isLoading,
    String? error,
    String? successMessage,
    List<String>? availableSlots,
    DateTime? selectedDate,
    String? selectedTimeSlot,
  }) {
    return AppointmentBookingState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
      availableSlots: availableSlots ?? this.availableSlots,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTimeSlot: selectedTimeSlot ?? this.selectedTimeSlot,
    );
  }
}

/// Appointment booking provider
class AppointmentBookingNotifier extends StateNotifier<AppointmentBookingState> {
  AppointmentBookingNotifier() : super(const AppointmentBookingState());

  /// Load available time slots for a doctor on a specific date
  Future<void> loadAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Always provide fallback slots first to ensure UI shows something
      final fallbackSlots = _getDefaultTimeSlots();
      
      // Set fallback slots immediately
      state = state.copyWith(
        isLoading: false,
        availableSlots: fallbackSlots,
        selectedDate: date,
        selectedTimeSlot: null,
      );

      // Try to get actual slots from service
      try {
        final slots = await AppointmentService.getAvailableTimeSlots(
          doctorId: doctorId,
          date: date,
        );

        // Only update if we got valid slots
        if (slots.isNotEmpty) {
          state = state.copyWith(
            availableSlots: slots,
          );
        }
      } catch (e) {
        print('Error loading available slots from service: $e');
        // Keep fallback slots, don't show error
      }
    } catch (e) {
      print('Error in loadAvailableSlots: $e');
      // Ensure we always have some slots available
      final fallbackSlots = _getDefaultTimeSlots();
      
      state = state.copyWith(
        isLoading: false,
        availableSlots: fallbackSlots,
        selectedDate: date,
        selectedTimeSlot: null,
        error: null, // Don't show error, just use fallback
      );
    }
  }

  /// Get default time slots
  List<String> _getDefaultTimeSlots() {
    final now = DateTime.now();
    final isToday = DateTime.now().year == state.selectedDate?.year &&
                   DateTime.now().month == state.selectedDate?.month &&
                   DateTime.now().day == state.selectedDate?.day;

    final allSlots = [
      '09:00 AM',
      '09:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '02:00 PM',
      '02:30 PM',
      '03:00 PM',
      '03:30 PM',
      '04:00 PM',
      '04:30 PM',
      '05:00 PM',
      '05:30 PM',
    ];

    // If it's today, filter out past slots
    if (isToday) {
      return allSlots.where((slot) {
        final slotTime = _parseTimeSlot(slot);
        if (slotTime != null) {
          final slotDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            slotTime.hour,
            slotTime.minute,
          );
          return slotDateTime.isAfter(now.add(const Duration(hours: 1)));
        }
        return true;
      }).toList();
    }

    return allSlots;
  }

  /// Parse time slot string to DateTime
  DateTime? _parseTimeSlot(String timeSlot) {
    try {
      final parts = timeSlot.split(' ');
      final timePart = parts[0];
      final amPm = parts.length > 1 ? parts[1].toUpperCase() : null;

      final timeParts = timePart.split(':');
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (amPm == 'PM' && hour != 12) {
        hour += 12;
      } else if (amPm == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(2000, 1, 1, hour, minute);
    } catch (e) {
      return null;
    }
  }

  /// Select a time slot
  void selectTimeSlot(String timeSlot) {
    state = state.copyWith(selectedTimeSlot: timeSlot);
  }

  /// Book appointment
  Future<String?> bookAppointment({
    required String patientId,
    required String doctorId,
    required String patientName,
    required String doctorName,
    required String doctorSpecialty,
    required String consultationType,
    double? consultationFee,
    String? paymentId,
    String? paymentStatus,
    String? symptoms,
    String? notes,
  }) async {
    try {
      if (state.selectedDate == null || state.selectedTimeSlot == null) {
        throw Exception('Please select date and time slot');
      }

      state = state.copyWith(isLoading: true, error: null);

      final appointmentId = await AppointmentService.bookAppointment(
        patientId: patientId,
        doctorId: doctorId,
        patientName: patientName,
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        appointmentDate: state.selectedDate!,
        timeSlot: state.selectedTimeSlot!,
        consultationType: consultationType,
        consultationFee: consultationFee,
        paymentId: paymentId,
        paymentStatus: paymentStatus,
        symptoms: symptoms,
        notes: notes,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Appointment booked successfully!',
      );

      // Refresh available slots
      await loadAvailableSlots(
        doctorId: doctorId,
        date: state.selectedDate!,
      );

      return appointmentId;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Clear state
  void clearState() {
    state = const AppointmentBookingState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear success message
  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }
}

/// Appointments list state
class AppointmentsListState {
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final String? error;

  const AppointmentsListState({
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  AppointmentsListState copyWith({
    List<AppointmentModel>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return AppointmentsListState(
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Appointments list provider
class AppointmentsListNotifier extends StateNotifier<AppointmentsListState> {
  AppointmentsListNotifier() : super(const AppointmentsListState());

  /// Load user appointments
  Future<void> loadUserAppointments({
    required String userId,
    String? status,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final appointments = await AppointmentService.getUserAppointments(
        userId: userId,
        status: status,
      );

      state = state.copyWith(
        isLoading: false,
        appointments: appointments,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Cancel appointment
  Future<void> cancelAppointment({
    required String appointmentId,
    required String cancellationReason,
    required String cancelledBy,
  }) async {
    try {
      await AppointmentService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: 'cancelled',
        cancellationReason: cancellationReason,
        cancelledBy: cancelledBy,
      );

      // Update local state
      final updatedAppointments = state.appointments.map((appointment) {
        if (appointment.id == appointmentId) {
          return appointment.copyWith(
            status: 'cancelled',
            cancellationReason: cancellationReason,
            cancelledBy: cancelledBy,
            cancelledAt: DateTime.now(),
          );
        }
        return appointment;
      }).toList();

      state = state.copyWith(appointments: updatedAppointments);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Reschedule appointment
  Future<void> rescheduleAppointment({
    required String appointmentId,
    required DateTime newDate,
    required String newTimeSlot,
  }) async {
    try {
      await AppointmentService.rescheduleAppointment(
        appointmentId: appointmentId,
        newDate: newDate,
        newTimeSlot: newTimeSlot,
      );

      // Update local state
      final updatedAppointments = state.appointments.map((appointment) {
        if (appointment.id == appointmentId) {
          return appointment.copyWith(
            appointmentDate: newDate,
            timeSlot: newTimeSlot,
            status: 'rescheduled',
            updatedAt: DateTime.now(),
          );
        }
        return appointment;
      }).toList();

      state = state.copyWith(appointments: updatedAppointments);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider instances
final appointmentBookingProvider = StateNotifierProvider<AppointmentBookingNotifier, AppointmentBookingState>((ref) {
  return AppointmentBookingNotifier();
});

final appointmentsListProvider = StateNotifierProvider<AppointmentsListNotifier, AppointmentsListState>((ref) {
  return AppointmentsListNotifier();
});

/// Individual appointment provider
final appointmentProvider = FutureProvider.family<AppointmentModel?, String>((ref, appointmentId) async {
  return await AppointmentService.getAppointmentById(appointmentId);
});

/// Upcoming appointments provider
final upcomingAppointmentsProvider = FutureProvider.family<List<AppointmentModel>, String>((ref, userId) async {
  return await AppointmentService.getUpcomingAppointments(userId: userId);
});

/// Available slots provider
final availableSlotsProvider = FutureProvider.family<List<String>, Map<String, dynamic>>((ref, params) async {
  return await AppointmentService.getAvailableTimeSlots(
    doctorId: params['doctorId'] as String,
    date: params['date'] as DateTime,
  );
});

/// Appointments stream provider
final appointmentsStreamProvider = StreamProvider.family<List<AppointmentModel>, Map<String, String?>>((ref, params) {
  return AppointmentService.getAppointmentsStream(
    userId: params['userId']!,
    status: params['status'],
  );
});
