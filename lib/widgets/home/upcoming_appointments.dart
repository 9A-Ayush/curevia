import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme_utils.dart';
import '../../screens/patient/my_appointments_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/appointment_provider.dart';
import 'package:intl/intl.dart';

/// Upcoming appointments widget for home screen
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

    final appointmentsAsync = ref.watch(upcomingAppointmentsProvider(user.uid));

    return appointmentsAsync.when(
      data: (appointments) {
        if (appointments.isEmpty) {
          return const SizedBox.shrink();
        }

        // Take only first 3 appointments
        final displayAppointments = appointments.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Appointments',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyAppointmentsScreen(),
                        ),
                      );
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: displayAppointments.length,
                itemBuilder: (context, index) {
                  final appointment = displayAppointments[index];
                  return Container(
                    width: 280,
                    margin: EdgeInsets.only(
                      right: index < displayAppointments.length - 1 ? 16 : 0,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThemeUtils.getSurfaceColor(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeUtils.getShadowLightColor(context),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: ThemeUtils.getPrimaryColorWithOpacity(
                            context,
                            0.1,
                          ),
                          child: Icon(
                            Icons.person,
                            color: ThemeUtils.getPrimaryColor(context),
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
                                      color: ThemeUtils.getTextSecondaryColor(
                                        context,
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: ThemeUtils.getTextSecondaryColor(
                                      context,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_formatDate(appointment.appointmentDate)} • ${_formatTime(appointment.timeSlot)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: ThemeUtils.getTextSecondaryColor(
                                            context,
                                          ),
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
                                      ? ThemeUtils.getPrimaryColorWithOpacity(
                                          context,
                                          0.1,
                                        )
                                      : ThemeUtils.getSecondaryColorWithOpacity(
                                          context,
                                          0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  appointment.consultationTypeText,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: appointment.consultationType == 'online'
                                            ? ThemeUtils.getPrimaryColor(context)
                                            : ThemeUtils.getSecondaryColor(context),
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
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
