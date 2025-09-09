import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../models/time_slot_model.dart';
import '../../services/appointment_booking_service.dart';
import '../../widgets/common/custom_button.dart';

/// Appointment booking screen with calendar and time slot selection
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
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  TimeSlotModel? _selectedTimeSlot;
  List<TimeSlotModel> _availableSlots = [];
  List<DateTime> _availableDates = [];
  bool _isLoadingSlots = false;
  bool _isLoadingDates = true;
  String _consultationType = 'online';

  @override
  void initState() {
    super.initState();
    _consultationType = widget.consultationType ?? 'online';
    _loadAvailableDates();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableDates() async {
    setState(() => _isLoadingDates = true);
    
    try {
      final dates = await AppointmentBookingService.getAvailableDates(
        doctorId: widget.doctor.uid,
        daysAhead: 30,
      );
      
      setState(() {
        _availableDates = dates;
        _isLoadingDates = false;
        
        // Set selected date to first available date if current date is not available
        if (dates.isNotEmpty && !_isDateAvailable(_selectedDate)) {
          _selectedDate = dates.first;
          _focusedDate = dates.first;
        }
      });
      
      _loadAvailableSlots();
    } catch (e) {
      setState(() => _isLoadingDates = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading available dates: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoadingSlots = true);
    
    try {
      final slots = await AppointmentBookingService.getAvailableSlots(
        doctorId: widget.doctor.uid,
        date: _selectedDate,
      );
      
      setState(() {
        _availableSlots = slots;
        _selectedTimeSlot = null; // Reset selected slot when date changes
        _isLoadingSlots = false;
      });
    } catch (e) {
      setState(() => _isLoadingSlots = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading time slots: $e')),
        );
      }
    }
  }

  bool _isDateAvailable(DateTime date) {
    return _availableDates.any((availableDate) =>
        availableDate.year == date.year &&
        availableDate.month == date.month &&
        availableDate.day == date.day);
  }

  Future<void> _bookAppointment() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final appointmentId = await AppointmentBookingService.bookAppointment(
        doctorId: widget.doctor.uid,
        patientId: 'current_user_id', // TODO: Get from auth service
        timeSlotId: _selectedTimeSlot!.id,
        patientName: 'Current User', // TODO: Get from auth service
        doctorName: widget.doctor.fullName,
        doctorSpecialty: widget.doctor.specialty ?? 'General Physician',
        consultationType: _consultationType,
        consultationFee: widget.doctor.consultationFee ?? 0,
        symptoms: '', // TODO: Add symptoms input
        notes: '', // TODO: Add notes input
      );

      Navigator.pop(context); // Close loading dialog

      if (appointmentId != null) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Appointment Booked'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your appointment has been successfully booked!'),
                const SizedBox(height: 16),
                Text('Doctor: ${widget.doctor.fullName}'),
                Text('Date: ${_formatDate(_selectedDate)}'),
                Text('Time: ${_selectedTimeSlot!.timeRange}'),
                Text('Type: ${_consultationType == 'online' ? 'Video Consultation' : 'In-Person Visit'}'),
                Text('Fee: ${widget.doctor.consultationFeeText}'),
              ],
            ),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to book appointment. Please try again.')),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking appointment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: Column(
        children: [
          // Doctor info header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  backgroundImage: widget.doctor.profileImageUrl != null
                      ? NetworkImage(widget.doctor.profileImageUrl!)
                      : null,
                  child: widget.doctor.profileImageUrl == null
                      ? Icon(Icons.person, size: 30, color: AppColors.primary)
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
                        widget.doctor.specialty ?? 'General Physician',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        widget.doctor.consultationFeeText,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Consultation type selector
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
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
          ),

          // Calendar
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Calendar widget
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: TableCalendar<DateTime>(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 90)),
                      focusedDay: _focusedDate,
                      selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                      enabledDayPredicate: (day) => _isDateAvailable(day),
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        disabledDecoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                        ),
                        disabledTextStyle: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (_isDateAvailable(selectedDay)) {
                          setState(() {
                            _selectedDate = selectedDay;
                            _focusedDate = focusedDay;
                          });
                          _loadAvailableSlots();
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Time slots
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Time Slots',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        if (_isLoadingSlots)
                          const Center(child: CircularProgressIndicator())
                        else if (_availableSlots.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No available slots',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Please select a different date',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 2.5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _availableSlots.length,
                            itemBuilder: (context, index) {
                              final slot = _availableSlots[index];
                              final isSelected = _selectedTimeSlot?.id == slot.id;
                              
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTimeSlot = slot;
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
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
                                  child: Center(
                                    child: Text(
                                      slot.timeRange,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isSelected 
                                            ? AppColors.textOnPrimary 
                                            : AppColors.textPrimary,
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: CustomButton(
          text: 'Book Appointment',
          onPressed: _selectedTimeSlot != null ? _bookAppointment : null,
          backgroundColor: AppColors.primary,
          textColor: AppColors.textOnPrimary,
          icon: Icons.calendar_month,
        ),
      ),
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
