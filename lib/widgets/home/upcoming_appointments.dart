import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';

/// Upcoming appointments widget for home screen
class UpcomingAppointments extends StatelessWidget {
  const UpcomingAppointments({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data - replace with actual data from provider
    final appointments = [
      {
        'doctorName': 'Dr. Sarah Johnson',
        'specialty': 'Cardiologist',
        'date': 'Today',
        'time': '2:30 PM',
        'type': 'Video Call',
        'avatar': 'https://via.placeholder.com/50',
      },
      {
        'doctorName': 'Dr. Michael Chen',
        'specialty': 'Dermatologist',
        'date': 'Tomorrow',
        'time': '10:00 AM',
        'type': 'In-Person',
        'avatar': 'https://via.placeholder.com/50',
      },
    ];

    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Appointments',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to all appointments
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return Container(
                width: 280,
                margin: EdgeInsets.only(
                  right: index < appointments.length - 1 ? 16 : 0,
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
                            appointment['doctorName'] as String,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            appointment['specialty'] as String,
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
                                '${appointment['date']} • ${appointment['time']}',
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
                              color: appointment['type'] == 'Video Call'
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
                              appointment['type'] as String,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: appointment['type'] == 'Video Call'
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
  }
}
