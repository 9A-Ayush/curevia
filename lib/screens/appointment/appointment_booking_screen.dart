import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';

/// Appointment booking screen
class AppointmentBookingScreen extends ConsumerStatefulWidget {
  final DoctorModel doctor;
  final String consultationType;

  const AppointmentBookingScreen({
    super.key,
    required this.doctor,
    required this.consultationType,
  });

  @override
  ConsumerState<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends ConsumerState<AppointmentBookingScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadAvailableSlots() {
    ref.read(appointmentBookingProvider.notifier).loadAvailableSlots(
      doctorId: widget.doctor.uid,
      date: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(appointmentBookingProvider);
    final userModel = ref.watch(currentUserModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: LoadingOverlay(
        isLoading: bookingState.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info Card
              _buildDoctorInfoCard(),
              
              const SizedBox(height: 24),
              
              // Date Selection
              _buildDateSelection(bookingState),
              
              const SizedBox(height: 24),
              
              // Time Slot Selection
              _buildTimeSlotSelection(bookingState),
              
              const SizedBox(height: 24),
              
              // Symptoms Input
              _buildSymptomsInput(),
              
              const SizedBox(height: 16),
              
              // Notes Input
              _buildNotesInput(),
              
              const SizedBox(height: 24),
              
              // Booking Summary
              _buildBookingSummary(),
              
              const SizedBox(height: 24),
              
              // Book Button
              _buildBookButton(bookingState, userModel),
              
              const SizedBox(height: 16),
              
              // Error/Success Messages
              if (bookingState.error != null)
                _buildErrorMessage(bookingState.error!),
              
              if (bookingState.successMessage != null)
                _buildSuccessMessage(bookingState.successMessage!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: widget.doctor.profileImageUrl != null
                ? NetworkImage(widget.doctor.profileImageUrl!)
                : null,
            child: widget.doctor.profileImageUrl == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 30)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.doctor.fullName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.doctor.specialty ?? 'General Medicine',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.consultationType == 'online'
                        ? AppColors.secondary.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.consultationType == 'online' ? 'Video Consultation' : 'In-Person Visit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.consultationType == 'online'
                          ? AppColors.secondary
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.doctor.consultationFee != null)
            Text(
              widget.doctor.consultationFeeText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateSelection(AppointmentBookingState bookingState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TableCalendar<dynamic>(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              if (selectedDay.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                setState(() {
                  _selectedDate = selectedDay;
                  _selectedTimeSlot = null;
                });
                _loadAvailableSlots();
              }
            },
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlotSelection(AppointmentBookingState bookingState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Time Slot',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (bookingState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (bookingState.availableSlots.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No available slots for this date',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bookingState.availableSlots.map((slot) {
              final isSelected = _selectedTimeSlot == slot;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTimeSlot = slot;
                  });
                  ref.read(appointmentBookingProvider.notifier).selectTimeSlot(slot);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSymptomsInput() {
    return CustomTextField(
      controller: _symptomsController,
      label: 'Symptoms (Optional)',
      hintText: 'Describe your symptoms...',
      maxLines: 3,
      prefixIcon: Icons.medical_services,
    );
  }

  Widget _buildNotesInput() {
    return CustomTextField(
      controller: _notesController,
      label: 'Additional Notes (Optional)',
      hintText: 'Any additional information...',
      maxLines: 2,
      prefixIcon: Icons.note,
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Doctor', widget.doctor.fullName),
          _buildSummaryRow('Specialty', widget.doctor.specialty ?? 'General Medicine'),
          _buildSummaryRow('Date', _formatDate(_selectedDate)),
          _buildSummaryRow('Time', _selectedTimeSlot ?? 'Not selected'),
          _buildSummaryRow('Type', widget.consultationType == 'online' ? 'Video Consultation' : 'In-Person Visit'),
          if (widget.doctor.consultationFee != null)
            _buildSummaryRow('Fee', widget.doctor.consultationFeeText),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookButton(AppointmentBookingState bookingState, userModel) {
    final canBook = _selectedTimeSlot != null && !bookingState.isLoading;
    
    return CustomButton(
      text: 'Book Appointment',
      onPressed: canBook ? _bookAppointment : null,
      isLoading: bookingState.isLoading,
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment() async {
    final userModel = ref.read(currentUserModelProvider);
    if (userModel == null) return;

    final appointmentId = await ref.read(appointmentBookingProvider.notifier).bookAppointment(
      patientId: userModel.uid,
      doctorId: widget.doctor.uid,
      patientName: userModel.fullName,
      doctorName: widget.doctor.fullName,
      doctorSpecialty: widget.doctor.specialty ?? 'General Medicine',
      consultationType: widget.consultationType,
      consultationFee: widget.doctor.consultationFee,
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (appointmentId != null && mounted) {
      // Show success dialog and navigate back
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Appointment Booked!'),
          content: const Text('Your appointment has been successfully booked. You will receive a confirmation shortly.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
