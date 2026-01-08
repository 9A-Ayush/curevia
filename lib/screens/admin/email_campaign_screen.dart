import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/email_service.dart';
import '../../utils/theme_utils.dart';

class EmailCampaignScreen extends StatefulWidget {
  const EmailCampaignScreen({super.key});

  @override
  State<EmailCampaignScreen> createState() => _EmailCampaignScreenState();
}

class _EmailCampaignScreenState extends State<EmailCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _contentController = TextEditingController();
  final _ctaTextController = TextEditingController();
  final _ctaLinkController = TextEditingController();
  
  bool _isSending = false;
  Map<String, dynamic>? _emailStats;
  
  @override
  void initState() {
    super.initState();
    _loadEmailStats();
    
    // Set default values
    _ctaTextController.text = 'Learn More';
    _ctaLinkController.text = 'https://curevia.com';
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _contentController.dispose();
    _ctaTextController.dispose();
    _ctaLinkController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEmailStats() async {
    try {
      final stats = await EmailService.getEmailStats();
      if (mounted && stats != null) {
        setState(() {
          _emailStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Failed to load email stats: $e');
    }
  }
  
  Future<void> _sendCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      final success = await EmailService.sendPromotionalCampaign(
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        content: _contentController.text.trim(),
        ctaText: _ctaTextController.text.trim(),
        ctaLink: _ctaLinkController.text.trim(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Campaign sent successfully!'
              : 'Failed to send campaign'
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        
        if (success) {
          // Clear form after successful send
          _titleController.clear();
          _subtitleController.clear();
          _contentController.clear();
          _ctaTextController.text = 'Learn More';
          _ctaLinkController.text = 'https://curevia.com';
          
          // Reload stats
          _loadEmailStats();
        }
      }
    } catch (e) {
      debugPrint('Failed to send campaign: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send campaign'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
  
  Future<void> _sendTestEmail() async {
    // Show dialog to enter test email
    final testEmail = await showDialog<String>(
      context: context,
      builder: (context) {
        final emailController = TextEditingController();
        return AlertDialog(
          title: const Text('Send Test Email'),
          content: TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'test@example.com',
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(emailController.text.trim()),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
    
    if (testEmail == null || testEmail.isEmpty) return;
    
    try {
      final success = await EmailService.sendTestEmail(testEmail);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Test email sent to $testEmail'
              : 'Failed to send test email'
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Failed to send test email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send test email'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Campaign'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _sendTestEmail,
            icon: const Icon(Icons.send_outlined),
            tooltip: 'Send Test Email',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email stats card
              if (_emailStats != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email Service Status',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Emails sent today: ${_emailStats!['stats']?['emailsSentToday'] ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Remaining: ${_emailStats!['stats']?['remaining'] ?? 0}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Campaign form
              Text(
                'Create Email Campaign',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Send promotional emails to users who have opted in for marketing communications.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Email Title *',
                  hintText: 'New Features Available in Curevia!',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle field
              TextFormField(
                controller: _subtitleController,
                decoration: const InputDecoration(
                  labelText: 'Email Subtitle',
                  hintText: 'Discover the latest updates and improvements',
                  border: OutlineInputBorder(),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Content field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Email Content *',
                  hintText: 'Write your email content here...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter email content';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // CTA section
              Text(
                'Call to Action',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add a button to encourage user action.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // CTA text field
              TextFormField(
                controller: _ctaTextController,
                decoration: const InputDecoration(
                  labelText: 'Button Text',
                  hintText: 'Learn More',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter button text';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // CTA link field
              TextFormField(
                controller: _ctaLinkController,
                decoration: const InputDecoration(
                  labelText: 'Button Link',
                  hintText: 'https://curevia.com',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter button link';
                  }
                  if (!Uri.tryParse(value.trim())?.hasAbsolutePath == true) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSending
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sending Campaign...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('Send Campaign'),
                        ],
                      ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Info note
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
                        'This campaign will be sent to all users who have opted in for promotional emails. '
                        'Make sure to test your email before sending to all users.',
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
      ),
    );
  }
}