import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_overlay.dart';

/// Reschedule appointment screen
class RescheduleAppointmentScreen extends ConsumerStatefulWidget {
  final AppointmentModel appointment;

  const RescheduleAppointmentScreen({
    super.key,
    required this.appointment,
  });

  @override
  ConsumerState<RescheduleAppointmentScreen> createState() => _RescheduleAppointmentScreenState();
}

class _RescheduleAppointmentScreenState extends ConsumerState<RescheduleAppointmentScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  bool _isRescheduling = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.appointment.appointmentDate;
    _loadAvailableSlots();
  }

  void _loadAvailableSlots() {
    if (mounted) {
      ref.read(appointmentBookingProvider.notifier).loadAvailableSlots(
        doctorId: widget.appointment.doctorId,
        date: _selectedDate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(appointmentBookingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Appointment'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: LoadingOverlay(
        isLoading: bookingState.isLoading || _isRescheduling,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current appointment info
                    _buildCurrentAppointmentInfo(),
                    
                    const SizedBox(height: 24),
                    
                    // Date Selection
                    _buildDateSelection(bookingState),
                    
                    const SizedBox(height: 24),
                    
                    // Time Slot Selection
                    _buildTimeSlotSelection(bookingState),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Fixed Reschedule Button at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ThemeUtils.getBackgroundColor(context),
                boxShadow: [
                  BoxShadow(
                    color: ThemeUtils.getShadowLightColor(context),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Reschedule Appointment',
                  onPressed: _selectedTimeSlot != null && !_isRescheduling ? _rescheduleAppointment : null,
                  isLoading: _isRescheduling,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentAppointmentInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Appointment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 20,
                color: ThemeUtils.getPrimaryColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                widget.appointment.doctorName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 20,
                color: ThemeUtils.getPrimaryColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                widget.appointment.formattedDateTime,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
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
          'Select New Date',
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
                if (mounted) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _selectedTimeSlot = null;
                  });
                  _loadAvailableSlots();
                }
              }
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(context),
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(context).withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
              weekendTextStyle: Theme.of(context).textTheme.bodyMedium!,
              outsideTextStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context).withOpacity(0.3),
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: Theme.of(context).textTheme.titleMedium!,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              weekendStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
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
          'Select New Time Slot',
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
              color: ThemeUtils.getSurfaceColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
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
                  if (mounted) {
                    setState(() {
                      _selectedTimeSlot = slot;
                    });
                  }
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

  Future<void> _rescheduleAppointment() async {
    if (_selectedTimeSlot == null || _isRescheduling) return;

    setState(() {
      _isRescheduling = true;
    });

    try {
      await ref.read(appointmentsListProvider.notifier).rescheduleAppointment(
        appointmentId: widget.appointment.id,
        newDate: _selectedDate,
        newTimeSlot: _selectedTimeSlot!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment rescheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rescheduling appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });
      }
    }
  }
}