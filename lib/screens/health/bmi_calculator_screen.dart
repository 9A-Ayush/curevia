import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../services/health/bmi_service.dart';
import '../../providers/home_provider.dart';

/// BMI Calculator Screen for calculating Body Mass Index
class BmiCalculatorScreen extends ConsumerStatefulWidget {
  const BmiCalculatorScreen({super.key});

  @override
  ConsumerState<BmiCalculatorScreen> createState() => _BmiCalculatorScreenState();
}

class _BmiCalculatorScreenState extends ConsumerState<BmiCalculatorScreen>
    with SingleTickerProviderStateMixin {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  double? _bmi;
  String _bmiCategory = '';
  String _bmiDescription = '';
  Color _categoryColor = AppColors.primary;
  
  bool _isMetric = true; // true for metric (cm/kg), false for imperial (ft/lbs)
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));
    
    // Load saved data
    _loadSavedData();
  }

  /// Load previously saved BMI data
  void _loadSavedData() async {
    final height = await BmiService.getCurrentHeight();
    final weight = await BmiService.getCurrentWeight();
    final isMetric = await BmiService.getIsMetric();
    final currentBmi = await BmiService.getCurrentBMI();
    
    if (mounted) {
      setState(() {
        if (height != null) _heightController.text = height.toString();
        if (weight != null) _weightController.text = weight.toString();
        _isMetric = isMetric;
        if (currentBmi != null) {
          _bmi = currentBmi;
          _setBMICategory(currentBmi);
          _animationController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateBMI() async {
    if (!_formKey.currentState!.validate()) return;

    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);

    if (height == null || weight == null) return;

    final bmi = BmiService.calculateBMI(
      height: height,
      weight: weight,
      isMetric: _isMetric,
    );

    // Save the BMI result
    await BmiService.saveBMIResult(
      height: height,
      weight: weight,
      isMetric: _isMetric,
      bmi: bmi,
    );

    setState(() {
      _bmi = bmi;
      _setBMICategory(bmi);
    });

    _animationController.forward();

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('BMI calculated and saved: ${bmi.toStringAsFixed(1)}'),
          backgroundColor: AppColors.success,
        ),
      );
      
      // Refresh home provider to update health metrics
      ref.invalidate(homeProvider);
    }
  }

  void _setBMICategory(double bmi) {
    final category = BmiService.getBMICategory(bmi);
    _bmiCategory = category.category;
    _bmiDescription = category.description;
    
    switch (category.color) {
      case 'info':
        _categoryColor = AppColors.info;
        break;
      case 'success':
        _categoryColor = AppColors.success;
        break;
      case 'warning':
        _categoryColor = AppColors.warning;
        break;
      case 'error':
        _categoryColor = AppColors.error;
        break;
      default:
        _categoryColor = AppColors.primary;
    }
  }

  void _reset() {
    setState(() {
      _heightController.clear();
      _weightController.clear();
      _bmi = null;
      _bmiCategory = '';
      _bmiDescription = '';
    });
    _animationController.reset();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('BMI Calculator'),
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeUtils.getTextPrimaryColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: ThemeUtils.getTextPrimaryColor(context),
            ),
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         MediaQuery.of(context).padding.bottom - 
                         kToolbarHeight - 40, // Account for padding and app bar
            ),
            child: IntrinsicHeight(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit Toggle
                    _buildUnitToggle(),
                    const SizedBox(height: 24),
                    
                    // Input Fields
                    _buildInputFields(),
                    const SizedBox(height: 32),
                    
                    // Calculate Button
                    CustomButton(
                      text: 'Calculate BMI',
                      onPressed: _calculateBMI,
                      backgroundColor: AppColors.primary,
                      textColor: Colors.white,
                      icon: Icons.calculate,
                    ),
                    const SizedBox(height: 32),
                    
                    // Results
                    if (_bmi != null) ...[
                      _buildResults(),
                      const SizedBox(height: 24),
                    ],
                    
                    // BMI History
                    _buildBMIHistory(),
                    const SizedBox(height: 24),
                    
                    // BMI Information
                    _buildBMIInfo(),
                    
                    // Bottom spacing for safe area
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnitToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMetric = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isMetric 
                    ? AppColors.primary 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Metric (cm/kg)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _isMetric 
                      ? Colors.white 
                      : ThemeUtils.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isMetric = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isMetric 
                    ? AppColors.primary 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Imperial (ft/lbs)',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: !_isMetric 
                      ? Colors.white 
                      : ThemeUtils.getTextPrimaryColor(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _heightController,
          label: _isMetric ? 'Height (cm)' : 'Height (inches)',
          hintText: _isMetric ? 'Enter height in centimeters' : 'Enter height in inches',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          prefixIcon: Icons.height,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your height';
            }
            final height = double.tryParse(value);
            if (height == null || height <= 0) {
              return 'Please enter a valid height';
            }
            if (_isMetric && (height < 50 || height > 300)) {
              return 'Height should be between 50-300 cm';
            }
            if (!_isMetric && (height < 20 || height > 120)) {
              return 'Height should be between 20-120 inches';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _weightController,
          label: _isMetric ? 'Weight (kg)' : 'Weight (lbs)',
          hintText: _isMetric ? 'Enter weight in kilograms' : 'Enter weight in pounds',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          prefixIcon: Icons.monitor_weight,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your weight';
            }
            final weight = double.tryParse(value);
            if (weight == null || weight <= 0) {
              return 'Please enter a valid weight';
            }
            if (_isMetric && (weight < 20 || weight > 500)) {
              return 'Weight should be between 20-500 kg';
            }
            if (!_isMetric && (weight < 44 || weight > 1100)) {
              return 'Weight should be between 44-1100 lbs';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildResults() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ThemeUtils.getShadowLightColor(context),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Your BMI',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _bmi!.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _categoryColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _bmiCategory,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _categoryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _bmiDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMIHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BMI History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _showFullHistory(),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<BmiHistoryEntry>>(
            future: BmiService.getBMITrend(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getSurfaceVariantColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'No BMI history available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              final history = snapshot.data!.take(3).toList();
              return Column(
                children: history.map((entry) => _buildHistoryItem(entry)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BmiHistoryEntry entry) {
    final category = BmiService.getBMICategory(entry.bmi);
    Color categoryColor;
    
    switch (category.color) {
      case 'info':
        categoryColor = AppColors.info;
        break;
      case 'success':
        categoryColor = AppColors.success;
        break;
      case 'warning':
        categoryColor = AppColors.warning;
        break;
      case 'error':
        categoryColor = AppColors.error;
        break;
      default:
        categoryColor = AppColors.primary;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceVariantColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.bmi.toStringAsFixed(1)} - ${category.category}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${entry.height.toStringAsFixed(1)}${entry.isMetric ? 'cm' : 'in'}, ${entry.weight.toStringAsFixed(1)}${entry.isMetric ? 'kg' : 'lbs'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(entry.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showFullHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: ThemeUtils.getSurfaceColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: ThemeUtils.getBorderMediumColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'BMI History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<BmiHistoryEntry>>(
                future: BmiService.getBMIHistory(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No BMI history available',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: ThemeUtils.getTextSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(snapshot.data![index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BMI Categories',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBMICategory('Underweight', '< 18.5', AppColors.info),
          _buildBMICategory('Normal Weight', '18.5 - 24.9', AppColors.success),
          _buildBMICategory('Overweight', '25.0 - 29.9', AppColors.warning),
          _buildBMICategory('Obese', '≥ 30.0', AppColors.error),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BMI is a screening tool and not a diagnostic tool. Consult a healthcare provider for personalized advice.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICategory(String category, String range, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            range,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ThemeUtils.getTextSecondaryColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}