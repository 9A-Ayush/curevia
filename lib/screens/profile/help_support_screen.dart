import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      appBar: AppBar(
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeUtils.getTextOnPrimaryColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: TextStyle(
            color: ThemeUtils.getTextOnPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ThemeUtils.getTextOnPrimaryColor(context),
          labelColor: ThemeUtils.getTextOnPrimaryColor(context),
          unselectedLabelColor: ThemeUtils.getTextOnPrimaryColor(
            context,
          ).withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'FAQs'),
            Tab(text: 'Contact'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ThemeUtils.getBackgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [_buildFAQsTab(), _buildContactTab(), _buildFeedbackTab()],
        ),
      ),
    );
  }

  Widget _buildFAQsTab() {
    final faqs = [
      {
        'question': 'How do I book an appointment?',
        'answer':
            'You can book an appointment by going to the "Find Doctors" section, selecting a doctor, and choosing an available time slot. You can also use the quick booking feature from the home screen.',
      },
      {
        'question': 'Can I cancel or reschedule my appointment?',
        'answer':
            'Yes, you can cancel or reschedule your appointment up to 2 hours before the scheduled time. Go to "My Appointments" and select the appointment you want to modify.',
      },
      {
        'question': 'How do I add family members?',
        'answer':
            'Go to your Profile > Family Members and tap the "+" button. Fill in their details and you can book appointments for them too.',
      },
      {
        'question': 'Is my medical data secure?',
        'answer':
            'Yes, we use industry-standard encryption to protect your medical data. Your information is stored securely and only shared with healthcare providers you choose.',
      },
      {
        'question': 'How do video consultations work?',
        'answer':
            'Video consultations allow you to consult with doctors remotely. You\'ll receive a link to join the video call at your appointment time. Make sure you have a stable internet connection.',
      },
      {
        'question': 'What payment methods are accepted?',
        'answer':
            'We accept all major credit/debit cards, UPI, net banking, and digital wallets. Payment is processed securely through our payment partners.',
      },
      {
        'question': 'How do I access my medical records?',
        'answer':
            'Go to Profile > Medical Records to view your complete medical history, prescriptions, lab reports, and uploaded documents.',
      },
      {
        'question': 'Can I get a prescription refill?',
        'answer':
            'Yes, you can request prescription refills through the app. Go to Medical Records > Prescriptions and select the medication you need to refill.',
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 20),
          ...faqs.map((faq) => _buildFAQItem(faq['question']!, faq['answer']!)),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get in Touch',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 20),
          _buildContactCard(
            icon: Icons.phone,
            title: 'Call Us',
            subtitle: '+1 (555) 123-4567',
            description:
                'Available 24/7 for emergencies\nMon-Fri 9AM-6PM for general support',
            onTap: () => _makePhoneCall('+15551234567'),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.email,
            title: 'Email Support',
            subtitle: 'support@curevia.com',
            description: 'We typically respond within 24 hours',
            onTap: () => _sendEmail('support@curevia.com'),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.chat,
            title: 'Live Chat',
            subtitle: 'Chat with our support team',
            description: 'Available Mon-Fri 9AM-6PM',
            onTap: () => _startLiveChat(),
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            icon: Icons.location_on,
            title: 'Visit Us',
            subtitle: '123 Healthcare Street',
            description: 'Medical District, City 12345\nMon-Fri 9AM-5PM',
            onTap: () => _openMaps(),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.emergency, color: Colors.red, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Emergency Support',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'For medical emergencies, please call 911 or go to your nearest emergency room. This app is not intended for emergency medical situations.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Call Emergency Services',
                    onPressed: () => _makePhoneCall('911'),
                    backgroundColor: Colors.red,
                    icon: Icons.emergency,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Feedback',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve Curevia by sharing your thoughts and suggestions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 24),
          _FeedbackForm(),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rate Our App',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ThemeUtils.getTextPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enjoying Curevia? Please take a moment to rate us on the app store.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Rate on App Store',
                          onPressed: _rateOnAppStore,
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Rate on Play Store',
                          onPressed: _rateOnPlayStore,
                          isOutlined: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ThemeUtils.getPrimaryColorWithOpacity(context, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: ThemeUtils.getPrimaryColor(context)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: ThemeUtils.getTextPrimaryColor(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: ThemeUtils.getPrimaryColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone app')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Curevia Support Request',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch email app')),
        );
      }
    }
  }

  void _startLiveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live chat feature coming soon!')),
    );
  }

  void _openMaps() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening maps...')));
  }

  void _rateOnAppStore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to App Store...')),
    );
  }

  void _rateOnPlayStore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to Play Store...')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _FeedbackForm extends StatefulWidget {
  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General';
  int _rating = 5;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Bug Report',
    'Feature Request',
    'App Performance',
    'User Experience',
    'Medical Records',
    'Appointments',
    'Billing',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rate your experience',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => setState(() => _rating = index + 1),
                child: Icon(
                  Icons.star,
                  size: 32,
                  color: index < _rating
                      ? Colors.amber
                      : ThemeUtils.getBorderLightColor(context),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: InputDecoration(
              labelText: 'Category',
              filled: true,
              fillColor: ThemeUtils.getSurfaceVariantColor(context),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: ThemeUtils.getPrimaryColor(context),
                  width: 2,
                ),
              ),
              labelStyle: TextStyle(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
            dropdownColor: ThemeUtils.getSurfaceColor(context),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            items: _categories
                .map(
                  (category) =>
                      DropdownMenuItem(value: category, child: Text(category)),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedCategory = value!),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _subjectController,
            label: 'Subject',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter a subject';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _messageController,
            label: 'Message',
            maxLines: 5,
            hintText: 'Please describe your feedback in detail...',
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter your message';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: 'Submit Feedback',
              onPressed: _isSubmitting ? null : _submitFeedback,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isSubmitting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback! We\'ll review it soon.'),
          backgroundColor: AppColors.success,
        ),
      );

      // Clear form
      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _selectedCategory = 'General';
        _rating = 5;
      });
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
