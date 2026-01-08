import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../models/doctor_model.dart';
import '../../models/appointment_model.dart';
import '../../models/notification_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../services/firebase/appointment_service.dart';
import '../../services/notifications/notification_manager.dart';
import '../../services/notifications/notification_integration_service.dart';
import '../payment/payment_screen.dart';

/// Video consultation appointment booking screen
class AppointmentBookingScreen extends ConsumerStatefulWidget {
  final DoctorModel doctor;
  final String? consultationType; // 'online' or 'offline'

  const AppointmentBookingScreen({
    super.key,
    required this.doctor,
    this.consultationType,
  });

  @override
  ConsumerState<AppointmentBookingScreen> createState() => _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends ConsumerState<AppointmentBookingScreen> {
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  String _consultationType = 'online';

  @override
  void initState() {
    super.initState();
    _consultationType = widget.consultationType ?? 'online';
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
        title: const Text('Book Video Consultation'),
        backgroundColor: ThemeUtils.getAppBarBackgroundColor(context),
        foregroundColor: ThemeUtils.getAppBarForegroundColor(context),
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
              
              // Consultation Type Selector
              _buildConsultationTypeSelector(),
              
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
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
            backgroundImage: widget.doctor.profileImageUrl != null
                ? NetworkImage(widget.doctor.profileImageUrl!)
                : null,
            child: widget.doctor.profileImageUrl == null
                ? Icon(Icons.person, color: ThemeUtils.getPrimaryColor(context), size: 30)
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
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: AppColors.ratingFilled),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.doctor.rating?.toStringAsFixed(1) ?? 'N/A'} (${widget.doctor.totalReviews ?? 0} reviews)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (widget.doctor.consultationFee != null)
            Text(
              widget.doctor.consultationFeeText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consultation Type',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildConsultationTypeCard(
                'Video Consultation',
                'online',
                Icons.video_call,
                'Consult from home',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildConsultationTypeCard(
                'In-Person Visit',
                'offline',
                Icons.local_hospital,
                'Visit clinic',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsultationTypeCard(
    String title,
    String type,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _consultationType == type;
    
    return InkWell(
      onTap: () {
        setState(() {
          _consultationType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ThemeUtils.getPrimaryColorWithOpacity(context, 0.1) : ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ThemeUtils.getPrimaryColor(context) : ThemeUtils.getBorderLightColor(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? ThemeUtils.getPrimaryColor(context) : ThemeUtils.getTextSecondaryColor(context),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? ThemeUtils.getPrimaryColor(context) : ThemeUtils.getTextPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: ThemeUtils.getShadowLightColor(context),
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
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(context),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: ThemeUtils.getSecondaryColor(context),
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
              color: ThemeUtils.getSurfaceVariantColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No available slots for this date',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
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
                        ? ThemeUtils.getPrimaryColor(context)
                        : ThemeUtils.getSurfaceColor(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? ThemeUtils.getPrimaryColor(context)
                          : ThemeUtils.getBorderLightColor(context),
                    ),
                  ),
                  child: Text(
                    slot,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? ThemeUtils.getTextOnPrimaryColor(context)
                          : ThemeUtils.getTextPrimaryColor(context),
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
        color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.3)),
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
          _buildSummaryRow('Type', _consultationType == 'online' ? 'Video Consultation' : 'In-Person Visit'),
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
        color: ThemeUtils.getErrorColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeUtils.getErrorColor(context).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: ThemeUtils.getErrorColor(context), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getErrorColor(context),
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
        color: ThemeUtils.getSuccessColor(context).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeUtils.getSuccessColor(context).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: ThemeUtils.getSuccessColor(context), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getSuccessColor(context),
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

    // First, book the appointment with pending status
    final appointmentId = await ref.read(appointmentBookingProvider.notifier).bookAppointment(
      patientId: userModel.uid,
      doctorId: widget.doctor.uid,
      patientName: userModel.fullName,
      doctorName: widget.doctor.fullName,
      doctorSpecialty: widget.doctor.specialty ?? 'General Medicine',
      consultationType: _consultationType,
      consultationFee: widget.doctor.consultationFee,
      paymentStatus: 'pending',
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (appointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create appointment. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create appointment object for payment
    final appointment = AppointmentModel(
      id: appointmentId,
      patientId: userModel.uid,
      doctorId: widget.doctor.uid,
      patientName: userModel.fullName,
      doctorName: widget.doctor.fullName,
      doctorSpecialty: widget.doctor.specialty ?? 'General Medicine',
      appointmentDate: _selectedDate,
      timeSlot: _selectedTimeSlot ?? '',
      consultationType: _consultationType,
      status: 'pending',
      consultationFee: widget.doctor.consultationFee,
      paymentStatus: 'pending',
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Navigate to payment screen
    final paymentId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          appointment: appointment,
          doctor: widget.doctor,
          patient: userModel,
          onPaymentSuccess: (paymentId) async {
            // Update appointment status to confirmed and add payment info
            try {
              await AppointmentService.updateAppointmentStatus(
                appointmentId: appointmentId,
                status: 'confirmed',
              );
              
              // Send comprehensive appointment booking confirmation to patient
              // This includes both appointment details and payment confirmation
              final currentFCMToken = NotificationIntegrationService.instance.currentFCMToken;
              if (currentFCMToken != null) {
                await NotificationIntegrationService.instance.notifyPatientAppointmentBookedWithPayment(
                  patientId: userModel.uid,
                  patientName: userModel.fullName,
                  patientFCMToken: currentFCMToken,
                  doctorName: widget.doctor.fullName,
                  appointmentId: appointmentId,
                  appointmentTime: DateTime(
                    _selectedDate.year,
                    _selectedDate.month,
                    _selectedDate.day,
                    int.parse(_selectedTimeSlot!.split(':')[0]),
                    int.parse(_selectedTimeSlot!.split(':')[1]),
                  ),
                  appointmentType: 'Video Consultation',
                  paymentId: paymentId,
                  amount: widget.doctor.consultationFee?.toDouble() ?? 0.0,
                  currency: 'INR',
                  paymentMethod: 'Online Payment',
                );
              } else {
                debugPrint('⚠️ FCM token not available, cannot send patient notification');
              }
              
              // Send payment received notification to doctor
              await NotificationIntegrationService.instance.notifyDoctorPaymentReceived(
                doctorId: widget.doctor.uid,
                doctorFCMToken: 'doctor_token', // TODO: Get actual doctor FCM token
                patientName: userModel.fullName,
                paymentId: paymentId,
                amount: widget.doctor.consultationFee?.toDouble() ?? 0.0,
                currency: 'INR',
                appointmentId: appointmentId,
              );
              
              // Send notification to doctor
              await NotificationManager.instance.sendTestNotification(
                title: 'New Video Consultation Booked',
                body: 'You have a new video consultation with ${userModel.fullName}',
                type: NotificationType.appointmentBooking,
                data: {
                  'appointmentId': appointmentId,
                  'patientId': userModel.uid,
                  'patientName': userModel.fullName,
                  'type': 'appointment',
                },
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video consultation booked successfully! Doctor has been notified.'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              print('Error updating appointment status: $e');
            }
          },
        ),
      ),
    );

    if (paymentId != null && mounted) {
      // Show success dialog and navigate back
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Appointment Booked!'),
          content: const Text('Your appointment has been successfully booked and payment completed. You will receive a confirmation shortly.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Go back with success result
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Payment was cancelled or failed, cancel the appointment
      try {
        await AppointmentService.updateAppointmentStatus(
          appointmentId: appointmentId,
          status: 'cancelled',
          cancellationReason: 'Payment failed or cancelled',
          cancelledBy: 'patient',
        );
      } catch (e) {
        print('Error cancelling appointment: $e');
      }
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
