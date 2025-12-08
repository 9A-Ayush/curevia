import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../widgets/common/custom_button.dart';

/// Availability and schedule step in doctor onboarding
class AvailabilityStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Map<String, dynamic> initialData;

  const AvailabilityStep({
    super.key,
    required this.onContinue,
    required this.onBack,
    required this.onDataUpdate,
    required this.initialData,
  });

  @override
  ConsumerState<AvailabilityStep> createState() => _AvailabilityStepState();
}

class _AvailabilityStepState extends ConsumerState<AvailabilityStep> {
  Map<String, Map<String, dynamic>> _availability = {};
  int _consultationDuration = 30;
  bool _isLoading = false;

  final List<String> _weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final Map<String, String> _dayNames = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  final List<int> _durations = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final availability = widget.initialData['availability'];
    if (availability != null) {
      _availability = Map<String, Map<String, dynamic>>.from(availability);
    } else {
      // Initialize with default values
      for (final day in _weekDays) {
        _availability[day] = {
          'isAvailable': false,
          'startTime': '09:00',
          'endTime': '17:00',
        };
      }
    }

    _consultationDuration =
        widget.initialData['consultationDuration'] ?? 30;
  }

  void _toggleDay(String day) {
    setState(() {
      _availability[day]!['isAvailable'] =
          !(_availability[day]!['isAvailable'] as bool);
    });
  }

  Future<void> _selectTime(String day, String timeType) async {
    final currentTime = _availability[day]![timeType] as String;
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: ThemeUtils.getSurfaceColor(context),
                    onSurface: ThemeUtils.getTextPrimaryColor(context),
                  )
                : ColorScheme.light(
                    primary: AppColors.primary,
                    onPrimary: Colors.white,
                    surface: ThemeUtils.getSurfaceColor(context),
                    onSurface: ThemeUtils.getTextPrimaryColor(context),
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _availability[day]![timeType] =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveAndContinue() async {
    // Check if at least one day is selected
    final hasAvailability = _availability.values.any(
      (day) => day['isAvailable'] == true,
    );

    if (!hasAvailability) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one available day'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      // Prepare data
      final data = {
        'availability': _availability,
        'consultationDuration': _consultationDuration,
      };

      // Save to Firestore
      await DoctorOnboardingService.saveAvailability(user.uid, data);

      // Update parent widget
      widget.onDataUpdate(data);

      setState(() => _isLoading = false);

      // Continue to next step
      widget.onContinue();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving information: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Consultation Duration
        Text(
          'Consultation Duration *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: _durations.map((duration) {
            final isSelected = _consultationDuration == duration;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _consultationDuration = duration;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : ThemeUtils.getSurfaceColor(context),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : ThemeUtils.getBorderLightColor(context),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '$duration min',
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : ThemeUtils.getTextPrimaryColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Weekly Schedule
        Text(
          'Weekly Schedule *',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your working days and hours',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
        ),

        const SizedBox(height: 16),

        // Days list
        ..._weekDays.map((day) => _buildDayCard(day)),

        const SizedBox(height: 32),

        // Buttons
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Back',
                onPressed: widget.onBack,
                backgroundColor: ThemeUtils.getSurfaceColor(context),
                textColor: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: CustomButton(
                text: 'Continue',
                onPressed: _isLoading ? null : _saveAndContinue,
                backgroundColor: AppColors.primary,
                textColor: Colors.white,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
      ],
    ),
    );
  }

  Widget _buildDayCard(String day) {
    final dayData = _availability[day]!;
    final isAvailable = dayData['isAvailable'] as bool;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dayNames[day]!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (value) => _toggleDay(day),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start Time',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(
                                  context,
                                ),
                              ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectTime(day, 'startTime'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: ThemeUtils.getBorderLightColor(context),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dayData['startTime'] as String,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const Icon(Icons.access_time, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'End Time',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(
                                  context,
                                ),
                              ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectTime(day, 'endTime'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: ThemeUtils.getBorderLightColor(context),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dayData['endTime'] as String,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const Icon(Icons.access_time, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
