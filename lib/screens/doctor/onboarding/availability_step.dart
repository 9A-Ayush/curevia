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

class _AvailabilityStepState extends ConsumerState<AvailabilityStep>
    with TickerProviderStateMixin {
  Map<String, Map<String, dynamic>> _availability = {};
  int _consultationDuration = 30;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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

  final Map<String, IconData> _dayIcons = {
    'monday': Icons.work,
    'tuesday': Icons.work,
    'wednesday': Icons.work,
    'thursday': Icons.work,
    'friday': Icons.work,
    'saturday': Icons.weekend,
    'sunday': Icons.weekend,
  };

  final List<int> _durations = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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
                    primary: AppColors.darkSuccess,
                    onPrimary: Colors.white,
                    surface: AppColors.darkSurface,
                    onSurface: Colors.white,
                    background: AppColors.darkBackground,
                    onBackground: Colors.white,
                  )
                : ColorScheme.light(
                    primary: AppColors.success,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppColors.textPrimary,
                  ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
              hourMinuteTextColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              hourMinuteColor: isDarkMode ? AppColors.darkSurfaceVariant : Colors.grey.shade100,
              dayPeriodTextColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              dayPeriodColor: isDarkMode ? AppColors.darkSurfaceVariant : Colors.grey.shade100,
              dialHandColor: isDarkMode ? AppColors.darkSuccess : AppColors.success,
              dialBackgroundColor: isDarkMode ? AppColors.darkSurfaceVariant : Colors.grey.shade100,
              dialTextColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              entryModeIconColor: isDarkMode ? Colors.white : AppColors.textPrimary,
              helpTextStyle: TextStyle(
                color: isDarkMode ? Colors.white : AppColors.textPrimary,
              ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select at least one available day'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
          SnackBar(
            content: Text('Error saving information: $e'),
            backgroundColor: ThemeUtils.getErrorColor(context),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeUtils.isDarkMode(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ThemeUtils.getSuccessColor(context).withOpacity(0.05),
            ThemeUtils.getSuccessColor(context).withOpacity(0.02),
            ThemeUtils.getBackgroundColor(context),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animated Header
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildSectionHeader(
                      'Availability Schedule',
                      'Set your working hours and consultation duration',
                      Icons.schedule,
                      AppColors.success,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Consultation Duration Section
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildConsultationDurationSection(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Weekly Schedule Header
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(-30 * (1 - value), 0),
                  child: Opacity(
                    opacity: value,
                    child: _buildScheduleHeader(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Animated Days List
            ..._buildAnimatedDaysList(),

            const SizedBox(height: 32),

            // Summary Card
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1400),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildSummaryCard(),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Animated Buttons
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: _buildActionButtons(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationDurationSection() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getSuccessColor(context).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.timer, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultation Duration',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    Text(
                      'How long is each appointment?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: _durations.map((duration) {
              final isSelected = _consultationDuration == duration;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _consultationDuration = duration;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                                )
                              : null,
                          color: isSelected 
                              ? null 
                              : isDarkMode 
                                  ? AppColors.darkSurfaceVariant 
                                  : Colors.grey.shade50,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.success
                                : isDarkMode 
                                    ? AppColors.darkBorderLight 
                                    : AppColors.borderLight,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.success.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$duration',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isSelected 
                                    ? Colors.white 
                                    : ThemeUtils.getTextPrimaryColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'minutes',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected 
                                    ? Colors.white.withOpacity(0.8) 
                                    : ThemeUtils.getTextSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.calendar_today, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  'Select your working days and set hours',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Required',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAnimatedDaysList() {
    return _weekDays.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;
      return TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400 + (index * 100)),
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(30 * (1 - value), 0),
            child: Opacity(
              opacity: value,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDayCard(day),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildDayCard(String day) {
    final dayData = _availability[day]!;
    final isAvailable = dayData['isAvailable'] as bool;
    final isWeekend = day == 'saturday' || day == 'sunday';
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: isAvailable
            ? LinearGradient(
                colors: [
                  AppColors.success.withOpacity(0.1),
                  AppColors.success.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isAvailable 
            ? null 
            : isDarkMode 
                ? AppColors.darkSurface 
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? AppColors.success.withOpacity(0.3)
              : isDarkMode 
                  ? AppColors.darkBorderLight 
                  : AppColors.borderLight,
          width: isAvailable ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAvailable
                ? AppColors.success.withOpacity(0.1)
                : isDarkMode 
                    ? AppColors.darkShadowLight 
                    : Colors.black.withOpacity(0.05),
            blurRadius: isAvailable ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isAvailable
                        ? LinearGradient(
                            colors: [AppColors.success, AppColors.success.withOpacity(0.8)],
                          )
                        : null,
                    color: isAvailable 
                        ? null 
                        : isDarkMode 
                            ? AppColors.darkSurfaceVariant 
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isAvailable
                        ? [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    _dayIcons[day],
                    color: isAvailable 
                        ? Colors.white 
                        : isDarkMode 
                            ? AppColors.darkTextSecondary 
                            : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dayNames[day]!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                      Text(
                        isWeekend ? 'Weekend' : 'Weekday',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  child: Switch(
                    value: isAvailable,
                    onChanged: (value) => _toggleDay(day),
                    activeColor: AppColors.success,
                    activeTrackColor: AppColors.success.withOpacity(0.3),
                    inactiveThumbColor: isDarkMode 
                        ? AppColors.darkTextSecondary 
                        : Colors.grey.shade400,
                    inactiveTrackColor: isDarkMode 
                        ? AppColors.darkBorderLight 
                        : Colors.grey.shade200,
                  ),
                ),
              ],
            ),
            if (isAvailable) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkSurfaceVariant : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTimeSelector(
                        day,
                        'startTime',
                        'Start Time',
                        Icons.access_time,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Expanded(
                      child: _buildTimeSelector(
                        day,
                        'endTime',
                        'End Time',
                        Icons.access_time_filled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector(String day, String timeType, String label, IconData icon) {
    final time = _availability[day]![timeType] as String;
    
    return InkWell(
      onTap: () => _selectTime(day, timeType),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.success, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ThemeUtils.getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final availableDays = _availability.values.where((day) => day['isAvailable'] == true).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withOpacity(0.1),
            AppColors.info.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.info, AppColors.info.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.info.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.summarize, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Schedule Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$availableDays days available • $_consultationDuration min consultations',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: TextButton(
              onPressed: widget.onBack,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Back',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ThemeUtils.getTextPrimaryColor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ThemeUtils.getSuccessColor(context), ThemeUtils.getSuccessColor(context).withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: ThemeUtils.getSuccessColor(context).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Continue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}