import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/email_service.dart';
import '../../utils/theme_utils.dart';

class HealthTipsAdminScreen extends StatefulWidget {
  const HealthTipsAdminScreen({super.key});

  @override
  State<HealthTipsAdminScreen> createState() => _HealthTipsAdminScreenState();
}

class _HealthTipsAdminScreenState extends State<HealthTipsAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<TextEditingController> _actionItemControllers = [TextEditingController()];
  
  bool _isSending = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    for (final controller in _actionItemControllers) {
      controller.dispose();
    }
    super.dispose();
  }
  
  void _addActionItem() {
    setState(() {
      _actionItemControllers.add(TextEditingController());
    });
  }
  
  void _removeActionItem(int index) {
    if (_actionItemControllers.length > 1) {
      setState(() {
        _actionItemControllers[index].dispose();
        _actionItemControllers.removeAt(index);
      });
    }
  }
  
  Future<void> _sendHealthTip() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isSending = true;
    });
    
    try {
      // Get action items
      final actionItems = _actionItemControllers
          .map((controller) => controller.text.trim())
          .where((item) => item.isNotEmpty)
          .toList();
      
      final success = await EmailService.sendHealthTip(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        actionItems: actionItems.isNotEmpty ? actionItems : null,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? 'Health tip sent successfully!'
              : 'Failed to send health tip'
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
        
        if (success) {
          // Clear form after successful send
          _titleController.clear();
          _contentController.clear();
          for (final controller in _actionItemControllers) {
            controller.clear();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to send health tip: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send health tip'),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tips Newsletter'),
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: AppColors.success,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Tips Newsletter',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Send wellness tips and health advice to subscribed users',
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
              
              // Title field
              Text(
                'Health Tip Title',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Stay Hydrated for Better Health',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a health tip title';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Content field
              Text(
                'Health Tip Content',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  hintText: 'Drinking adequate water is essential for maintaining good health...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter health tip content';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              
              // Action items section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Action Items (Optional)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addActionItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Practical steps users can take to implement this health tip.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action items list
              ...List.generate(_actionItemControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _actionItemControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Action Item ${index + 1}',
                            hintText: 'Drink a glass of water every hour',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.check_circle_outline),
                          ),
                        ),
                      ),
                      if (_actionItemControllers.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _removeActionItem(index),
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.error,
                        ),
                      ],
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 32),
              
              // Send button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _sendHealthTip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThemeUtils.getSuccessColor(context),
                    foregroundColor: ThemeUtils.getTextOnPrimaryColor(context),
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
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ThemeUtils.getTextOnPrimaryColor(context),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Sending Health Tip...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send),
                          SizedBox(width: 8),
                          Text('Send Health Tip'),
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
                        'This health tip will be sent to all users who have subscribed to health tips. '
                        'Make sure the content is accurate and helpful.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Sample health tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sample Health Tips',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• The Importance of Regular Exercise\n'
                      '• Healthy Eating Habits for Busy Professionals\n'
                      '• Managing Stress Through Mindfulness\n'
                      '• Getting Quality Sleep: Tips and Tricks\n'
                      '• Staying Hydrated Throughout the Day',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.5,
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