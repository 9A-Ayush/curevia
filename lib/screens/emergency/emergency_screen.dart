import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../widgets/common/custom_button.dart';
import '../../utils/theme_utils.dart';

/// Emergency services screen
class EmergencyScreen extends ConsumerStatefulWidget {
  const EmergencyScreen({super.key});

  @override
  ConsumerState<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends ConsumerState<EmergencyScreen> {
  final List<EmergencyService> _emergencyServices = [
    EmergencyService(
      name: 'Ambulance',
      number: '108',
      description: 'Emergency medical services',
      icon: Icons.local_hospital,
      color: AppColors.error,
    ),
    EmergencyService(
      name: 'Police',
      number: '100',
      description: 'Police emergency services',
      icon: Icons.local_police,
      color: AppColors.info,
    ),
    EmergencyService(
      name: 'Fire Department',
      number: '101',
      description: 'Fire emergency services',
      icon: Icons.local_fire_department,
      color: AppColors.warning,
    ),
    EmergencyService(
      name: 'Disaster Management',
      number: '108',
      description: 'Natural disaster response',
      icon: Icons.warning,
      color: AppColors.secondary,
    ),
  ];

  final List<EmergencyContact> _emergencyContacts = [
    EmergencyContact(
      name: 'Poison Control',
      number: '1066',
      description: 'Poison control helpline',
      available: '24/7',
    ),
    EmergencyContact(
      name: 'Women Helpline',
      number: '1091',
      description: 'Women in distress helpline',
      available: '24/7',
    ),
    EmergencyContact(
      name: 'Child Helpline',
      number: '1098',
      description: 'Child protection services',
      available: '24/7',
    ),
    EmergencyContact(
      name: 'Mental Health',
      number: '9152987821',
      description: 'Mental health crisis support',
      available: '24/7',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Emergency Services'),
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Emergency header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.error,
                    AppColors.error.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.emergency,
                      color: AppColors.textOnPrimary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Emergency Services',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quick access to emergency contacts and services',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick emergency call
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Emergency Medical Services',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Call ${AppConstants.emergencyNumber} for immediate medical assistance',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Call ${AppConstants.emergencyNumber}',
                      onPressed: () =>
                          _makeEmergencyCall(AppConstants.emergencyNumber),
                      backgroundColor: AppColors.error,
                      icon: Icons.phone,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Emergency services
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Services',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: _emergencyServices.length,
                    itemBuilder: (context, index) {
                      final service = _emergencyServices[index];
                      return _buildEmergencyServiceCard(service);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Emergency contacts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Helplines',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final contact in _emergencyContacts)
                    _buildEmergencyContactCard(contact),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Safety tips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency Safety Tips',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSafetyTipsCard(),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyServiceCard(EmergencyService service) {
    return GestureDetector(
      onTap: () => _makeEmergencyCall(service.number),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: service.color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: ThemeUtils.getShadowLightColor(context),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: service.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(service.icon, color: service.color, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              service.name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            Text(
              service.number,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: service.color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              service.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(EmergencyContact contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.phone,
              color: ThemeUtils.getPrimaryColor(context),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  contact.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
                Text(
                  'Available: ${contact.available}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                contact.number,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ThemeUtils.getPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _makeEmergencyCall(contact.number),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone,
                    color: ThemeUtils.getPrimaryColor(context),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTipsCard() {
    final tips = [
      'Stay calm and assess the situation',
      'Call emergency services immediately if needed',
      'Provide clear location information',
      'Follow dispatcher instructions carefully',
      'Keep emergency contacts easily accessible',
      'Know basic first aid procedures',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Safety Tips',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 6, right: 12),
                    decoration: const BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _makeEmergencyCall(String number) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: number);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch phone dialer for $number'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class EmergencyService {
  final String name;
  final String number;
  final String description;
  final IconData icon;
  final Color color;

  EmergencyService({
    required this.name,
    required this.number,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class EmergencyContact {
  final String name;
  final String number;
  final String description;
  final String available;

  EmergencyContact({
    required this.name,
    required this.number,
    required this.description,
    required this.available,
  });
}
