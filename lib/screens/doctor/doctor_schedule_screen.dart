import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/doctor/doctor_service.dart';
import '../../widgets/common/custom_button.dart';

/// Doctor schedule screen for managing availability
class DoctorScheduleScreen extends ConsumerStatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  ConsumerState<DoctorScheduleScreen> createState() =>
      _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends ConsumerState<DoctorScheduleScreen> {
  Map<String, List<Map<String, dynamic>>> _schedule = {};
  bool _isLoading = true;

  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayDisplayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        final schedule = await DoctorService.getDoctorSchedule(user.uid);
        setState(() {
          _schedule = schedule;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading schedule: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Calendar view
            },
            icon: const Icon(Icons.calendar_view_month),
            tooltip: 'Calendar View',
          ),
          IconButton(
            onPressed: _showEditScheduleDialog,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Schedule',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedule,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weekly overview
                    _buildWeeklyOverview(),

                    const SizedBox(height: 24),

                    // Schedule details
                    _buildScheduleDetails(),

                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWeeklyOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Overview',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weekDays.map((day) {
                  final isToday = _isToday(day);
                  final hasSchedule = _schedule[day]?.isNotEmpty ?? false;

                  return Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isToday
                              ? AppColors.primary
                              : hasSchedule
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.borderLight.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            _dayDisplayNames[day]![0],
                            style: TextStyle(
                              color: isToday
                                  ? AppColors.textOnPrimary
                                  : hasSchedule
                                  ? AppColors.success
                                  : ThemeUtils.getTextSecondaryColor(context),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dayDisplayNames[day]!.substring(0, 3),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildLegendItem(AppColors.primary, 'Today'),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.success, 'Available'),
                  const SizedBox(width: 16),
                  _buildLegendItem(AppColors.borderLight, 'Off'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ThemeUtils.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule Details',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ..._weekDays.map((day) => _buildDaySchedule(day)),
      ],
    );
  }

  Widget _buildDaySchedule(String day) {
    final daySchedule = _schedule[day] ?? [];
    final isToday = _isToday(day);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isToday ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _dayDisplayNames[day]!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isToday ? AppColors.primary : null,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () => _editDaySchedule(day),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit ${_dayDisplayNames[day]} schedule',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (daySchedule.isEmpty)
              Text(
                'No schedule set',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...daySchedule.map(
                (slot) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${slot['startTime']} - ${slot['endTime']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          slot['type'] ?? 'consultation',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.info,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Set Availability',
                onPressed: _showEditScheduleDialog,
                backgroundColor: AppColors.primary,
                textColor: AppColors.textOnPrimary,
                icon: Icons.schedule,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Block Time',
                onPressed: _showBlockTimeDialog,
                backgroundColor: AppColors.warning,
                textColor: AppColors.textOnPrimary,
                icon: Icons.block,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            text: 'Copy Schedule to Next Week',
            onPressed: _copyScheduleToNextWeek,
            backgroundColor: AppColors.info,
            textColor: AppColors.textOnPrimary,
            icon: Icons.copy,
          ),
        ),
      ],
    );
  }

  bool _isToday(String day) {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday, 7 = Sunday
    final todayIndex = weekday == 7 ? 6 : weekday - 1; // Convert to 0-6 index
    return _weekDays[todayIndex] == day;
  }

  void _editDaySchedule(String day) {
    _showEditScheduleDialog(day);
  }

  void _showEditScheduleDialog([String? specificDay]) {
    final daySchedule = specificDay != null ? _schedule[specificDay] ?? [] : [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          specificDay != null
              ? 'Edit ${_dayDisplayNames[specificDay]} Schedule'
              : 'Edit Schedule',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current schedule:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (daySchedule.isEmpty)
                const Text('No schedule set for this day')
              else
                ...daySchedule.map((slot) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('${slot['startTime']} - ${slot['endTime']}'),
                    )),
              const SizedBox(height: 16),
              const Text(
                'Use the time slot management feature to add or modify your schedule.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to detailed schedule editor
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _showBlockTimeDialog() {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController startTimeController = TextEditingController();
    final TextEditingController endTimeController = TextEditingController();
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Time Slot'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    dateController.text = '${date.day}/${date.month}/${date.year}';
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: startTimeController,
                decoration: const InputDecoration(
                  labelText: 'Start Time',
                  hintText: 'Select start time',
                  prefixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    startTimeController.text = time.format(context);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: endTimeController,
                decoration: const InputDecoration(
                  labelText: 'End Time',
                  hintText: 'Select end time',
                  prefixIcon: Icon(Icons.access_time),
                ),
                readOnly: true,
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    endTimeController.text = time.format(context);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  hintText: 'Enter reason for blocking',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (dateController.text.isEmpty ||
                  startTimeController.text.isEmpty ||
                  endTimeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all required fields'),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              
              try {
                final user = ref.read(authProvider).userModel;
                if (user != null) {
                  await DoctorService.blockTimeSlot(
                    doctorId: user.uid,
                    date: dateController.text,
                    startTime: startTimeController.text,
                    endTime: endTimeController.text,
                    reason: reasonController.text,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Time slot blocked successfully')),
                    );
                    _loadSchedule();
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error blocking time slot: $e')),
                  );
                }
              }
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _copyScheduleToNextWeek() async {
    try {
      final user = ref.read(authProvider).userModel;
      if (user != null) {
        await DoctorService.copyScheduleToNextWeek(user.uid);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule copied to next week successfully')),
          );
          _loadSchedule();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error copying schedule: $e')),
        );
      }
    }
  }
}
