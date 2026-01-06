import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
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
import '../payment/payment_screen.dart';

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
  String? _selectedPaymentMethod; // Add payment method selection

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
              
              // Payment Method Selection (only for offline visits)
              if (widget.consultationType == 'offline') ...[
                const SizedBox(height: 24),
                _buildPaymentMethodSelection(),
              ],
              
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            backgroundImage: widget.doctor.profileImageUrl != null
                ? NetworkImage(widget.doctor.profileImageUrl!)
                : null,
            child: widget.doctor.profileImageUrl == null
                ? Icon(
                    Icons.person, 
                    color: Theme.of(context).primaryColor, 
                    size: 30,
                  )
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
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.consultationType == 'online'
                        ? Colors.blue.withOpacity(0.1)
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.consultationType == 'online' ? 'Video Consultation' : 'In-Person Visit',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: widget.consultationType == 'online'
                          ? Colors.blue
                          : Theme.of(context).primaryColor,
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
                color: Theme.of(context).primaryColor,
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
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
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              weekendTextStyle: Theme.of(context).textTheme.bodyMedium!,
              outsideTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context).textTheme.bodyMedium!.color!.withOpacity(0.3),
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleMedium!,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: Theme.of(context).iconTheme.color,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: Theme.of(context).iconTheme.color,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.bodySmall!,
              weekendStyle: Theme.of(context).textTheme.bodySmall!,
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
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No available slots for this date',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    slot,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyMedium?.color,
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
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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

  Widget _buildPaymentMethodSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Online Payment Option
          _buildPaymentMethodTile(
            'online_payment',
            'Pay Online',
            'Secure payment with card, UPI, or net banking',
            Icons.payment,
            AppColors.primary,
          ),
          
          const SizedBox(height: 8),
          
          // Pay on Clinic Option
          _buildPaymentMethodTile(
            'pay_on_clinic',
            'Pay on Clinic',
            'Pay directly at the clinic during your visit',
            Icons.location_on,
            AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(
    String methodId,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedPaymentMethod == methodId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = methodId;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? color
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : null,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton(AppointmentBookingState bookingState, userModel) {
    final canBook = _selectedTimeSlot != null && !bookingState.isLoading;
    
    // For offline visits, also check if payment method is selected
    final canBookOffline = widget.consultationType == 'offline' 
        ? (_selectedPaymentMethod != null && canBook)
        : canBook;
    
    return CustomButton(
      text: 'Book Appointment',
      onPressed: canBookOffline ? _bookAppointment : null,
      isLoading: bookingState.isLoading,
    );
  }

  Widget _buildErrorMessage(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
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
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
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

    // Check if this is a "Pay on Clinic" booking
    final isPayOnClinic = widget.consultationType == 'offline' && _selectedPaymentMethod == 'pay_on_clinic';

    if (isPayOnClinic) {
      // Direct booking without payment screen
      await _bookWithPayOnClinic(userModel);
    } else {
      // Regular booking with payment screen
      await _bookWithPayment(userModel);
    }
  }

  Future<void> _bookWithPayOnClinic(userModel) async {
    // Book appointment directly with "pay_on_clinic" status
    final appointmentId = await ref.read(appointmentBookingProvider.notifier).bookAppointment(
      patientId: userModel.uid,
      doctorId: widget.doctor.uid,
      patientName: userModel.fullName,
      doctorName: widget.doctor.fullName,
      doctorSpecialty: widget.doctor.specialty ?? 'General Medicine',
      consultationType: widget.consultationType,
      consultationFee: widget.doctor.consultationFee,
      paymentStatus: 'pay_on_clinic',
      symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (appointmentId != null) {
      // Update appointment status to confirmed (no payment needed)
      try {
        await AppointmentService.updateAppointmentStatus(
          appointmentId: appointmentId,
          status: 'confirmed',
          paymentStatus: 'pay_on_clinic',
        );
        
        // Notification is already sent in the payment screen, no need to send again here
        
        if (mounted) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  const Text('Appointment Booked!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your appointment has been successfully booked.'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please bring the consultation fee (₹${widget.doctor.consultationFee?.round() ?? 0}) when you visit the clinic.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
        }
      } catch (e) {
        print('Error updating appointment status: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment booked but there was an error: $e'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to book appointment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _bookWithPayment(userModel) async {
    // First, book the appointment with pending status
    final appointmentId = await ref.read(appointmentBookingProvider.notifier).bookAppointment(
      patientId: userModel.uid,
      doctorId: widget.doctor.uid,
      patientName: userModel.fullName,
      doctorName: widget.doctor.fullName,
      doctorSpecialty: widget.doctor.specialty ?? 'General Medicine',
      consultationType: widget.consultationType,
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
      consultationType: widget.consultationType,
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
              
              // Send payment success notification to patient
              await NotificationManager.instance.sendPaymentSuccessNotification(
                paymentId: paymentId,
                orderId: appointmentId,
                amount: widget.doctor.consultationFee?.toDouble() ?? 0.0,
                currency: 'INR',
                paymentMethod: 'Online Payment',
                userFCMToken: 'patient_token', // TODO: Get actual FCM token
              );
              
              // Send appointment notification to doctor (only once)
              await NotificationManager.instance.sendTestNotification(
                title: 'New Appointment Booked',
                body: 'You have a new appointment with ${userModel.fullName}',
                type: NotificationType.appointmentReminder,
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
                    content: Text('Appointment booked successfully! Doctor has been notified.'),
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
