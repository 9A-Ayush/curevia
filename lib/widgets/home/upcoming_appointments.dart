import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme_utils.dart';
import '../../screens/appointment/appointments_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import 'package:intl/intl.dart';

/// My appointments widget for home screen
class UpcomingAppointments extends ConsumerWidget {
  const UpcomingAppointments({super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final appointmentDay = DateTime(date.year, date.month, date.day);

    if (appointmentDay == today) {
      return 'Today';
    } else if (appointmentDay == tomorrow) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  String _formatTime(String timeSlot) {
    // timeSlot is in format "HH:mm" or "HH:mm AM/PM"
    return timeSlot;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider);
    
    if (user == null) {
      return const SizedBox.shrink();
    }

    // Force refresh by using a different approach
    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider(user.uid));

    return appointmentsAsync.when(
      data: (appointments) {
        // Always show the section, even if empty
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'My Appointments',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Force refresh
                      ref.invalidate(upcomingAppointmentsProvider(user.uid));
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Refresh',
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppointmentsScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (appointments.isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No appointments scheduled',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Book your first appointment to get started',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: appointments.take(3).length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return Container(
                      width: 280,
                      margin: EdgeInsets.only(
                        right: index < appointments.take(3).length - 1 ? 16 : 0,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).shadowColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                            child: Icon(
                              Icons.person,
                              color: ThemeUtils.getPrimaryColor(context),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  appointment.doctorName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  appointment.doctorSpecialty,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color: ThemeUtils.getTextSecondaryColor(context),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${_formatDate(appointment.appointmentDate)} • ${_formatTime(appointment.timeSlot)}',
                                        style: Theme.of(context).textTheme.bodySmall
                                            ?.copyWith(
                                              color: ThemeUtils.getTextSecondaryColor(context),
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: appointment.consultationType == 'online'
                                        ? Colors.blue.withOpacity(0.1)
                                        : ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    appointment.consultationTypeText,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: appointment.consultationType == 'online'
                                              ? Colors.blue
                                              : ThemeUtils.getPrimaryColor(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
          ],
        );
      },
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'My Appointments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 24),
        ],
      ),
      error: (error, stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'My Appointments',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                Text(
                  'Error loading appointments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap refresh to try again',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
