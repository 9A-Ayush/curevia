import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/app_colors.dart';
import '../../services/email_service.dart';
import '../../utils/theme_utils.dart';

class EmailPreferencesScreen extends StatefulWidget {
  const EmailPreferencesScreen({super.key});

  @override
  State<EmailPreferencesScreen> createState() => _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState extends State<EmailPreferencesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Email preferences
  bool _promotional = false;
  bool _healthTips = true;
  bool _doctorUpdates = true;
  bool _appointmentReminders = true;
  
  @override
  void initState() {
    super.initState();
    _loadEmailPreferences();
  }
  
  Future<void> _loadEmailPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      final preferences = await EmailService.getUserEmailPreferences(user.uid);
      
      if (preferences != null && mounted) {
        setState(() {
          _promotional = preferences['promotional'] ?? false;
          _healthTips = preferences['healthTips'] ?? true;
          _doctorUpdates = preferences['doctorUpdates'] ?? true;
          _appointmentReminders = preferences['appointmentReminders'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load email preferences: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _saveEmailPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final preferences = {
        'promotional': _promotional,
        'healthTips': _healthTips,
        'doctorUpdates': _doctorUpdates,
        'appointmentReminders': _appointmentReminders,
      };
      
      final success = await EmailService.updateUserEmailPreferences(
        user.uid,
        preferences,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Email preferences updated successfully'
              : 'Failed to update email preferences'
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to save email preferences: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update email preferences'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  Future<void> _unsubscribeFromAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsubscribe from All Emails'),
        content: const Text(
          'Are you sure you want to unsubscribe from all email communications? '
          'You will no longer receive any emails from Curevia, including important '
          'appointment reminders and health updates.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
            ),
            child: const Text('Unsubscribe'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final success = await EmailService.unsubscribeUser(user.uid);
      
      if (success && mounted) {
        setState(() {
          _promotional = false;
          _healthTips = false;
          _doctorUpdates = false;
          _appointmentReminders = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully unsubscribed from all emails'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to unsubscribe: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to unsubscribe'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Preferences'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveEmailPreferences,
              child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
        ],
      ),
      body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Notifications',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Choose which emails you\'d like to receive from Curevia',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Email preferences
                _buildPreferenceCard(
                  title: 'Appointment Reminders',
                  subtitle: 'Important reminders about your upcoming appointments',
                  icon: Icons.event_note,
                  value: _appointmentReminders,
                  onChanged: (value) => setState(() => _appointmentReminders = value),
                  isRecommended: true,
                ),
                
                const SizedBox(height: 16),
                
                _buildPreferenceCard(
                  title: 'Doctor Updates',
                  subtitle: 'Notifications about your doctor verification and profile updates',
                  icon: Icons.local_hospital,
                  value: _doctorUpdates,
                  onChanged: (value) => setState(() => _doctorUpdates = value),
                  isRecommended: true,
                ),
                
                const SizedBox(height: 16),
                
                _buildPreferenceCard(
                  title: 'Health Tips',
                  subtitle: 'Weekly health tips and wellness advice from our experts',
                  icon: Icons.favorite,
                  value: _healthTips,
                  onChanged: (value) => setState(() => _healthTips = value),
                ),
                
                const SizedBox(height: 16),
                
                _buildPreferenceCard(
                  title: 'Promotional Emails',
                  subtitle: 'Updates about new features, offers, and Curevia news',
                  icon: Icons.campaign,
                  value: _promotional,
                  onChanged: (value) => setState(() => _promotional = value),
                ),
                
                const SizedBox(height: 32),
                
                // Unsubscribe section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.unsubscribe,
                            color: AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Unsubscribe from All',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you no longer want to receive any emails from Curevia, '
                        'you can unsubscribe from all communications.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : _unsubscribeFromAll,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Unsubscribe from All Emails'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Footer note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getCardColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Changes will be saved automatically when you tap Save. '
                          'You can update these preferences anytime.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
  
  Widget _buildPreferenceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isRecommended = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: ThemeUtils.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeUtils.getBorderColor(context),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRecommended) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Recommended',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}