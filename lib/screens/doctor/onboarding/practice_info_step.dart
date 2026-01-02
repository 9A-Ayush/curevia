import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_colors.dart';
import '../../../utils/theme_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/doctor/doctor_onboarding_service.dart';
import '../../../widgets/common/custom_button.dart';

/// Practice information step in doctor onboarding
class PracticeInfoStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onBack;
  final Function(Map<String, dynamic>) onDataUpdate;
  final Map<String, dynamic> initialData;

  const PracticeInfoStep({
    super.key,
    required this.onContinue,
    required this.onBack,
    required this.onDataUpdate,
    required this.initialData,
  });

  @override
  ConsumerState<PracticeInfoStep> createState() => _PracticeInfoStepState();
}

class _PracticeInfoStepState extends ConsumerState<PracticeInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _clinicNameController = TextEditingController();
  final _clinicAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _onlineFeeController = TextEditingController();
  final _offlineFeeController = TextEditingController();

  List<String> _selectedLanguages = [];
  bool _isAvailableOnline = true;
  bool _isAvailableOffline = true;
  bool _isLoading = false;

  final List<String> _commonLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Gujarati',
    'Urdu',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Odia',
  ];

  final List<String> _indianStates = [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    _clinicNameController.text = widget.initialData['clinicName'] ?? '';
    _clinicAddressController.text = widget.initialData['clinicAddress'] ?? '';
    _cityController.text = widget.initialData['city'] ?? '';
    _stateController.text = widget.initialData['state'] ?? '';
    _pincodeController.text = widget.initialData['pincode'] ?? '';
    _onlineFeeController.text =
        widget.initialData['consultationFee']?.toString() ?? '';
    _offlineFeeController.text =
        widget.initialData['offlineConsultationFee']?.toString() ?? '';
    _selectedLanguages =
        List<String>.from(widget.initialData['languages'] ?? []);
    _isAvailableOnline = widget.initialData['isAvailableOnline'] ?? true;
    _isAvailableOffline = widget.initialData['isAvailableOffline'] ?? true;
  }

  @override
  void dispose() {
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _onlineFeeController.dispose();
    _offlineFeeController.dispose();
    super.dispose();
  }

  void _showStateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeUtils.getSurfaceColor(context),
        title: Text(
          'Select State',
          style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _indianStates.length,
            itemBuilder: (context, index) {
              final state = _indianStates[index];
              return ListTile(
                title: Text(
                  state,
                  style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
                ),
                onTap: () {
                  setState(() {
                    _stateController.text = state;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLanguagesDialog() {
    final tempLanguages = List<String>.from(_selectedLanguages);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: ThemeUtils.getSurfaceColor(context),
          title: Text(
            'Select Languages',
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _commonLanguages.map((language) {
                    final isSelected = tempLanguages.contains(language);
                    return FilterChip(
                      label: Text(language),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            tempLanguages.add(language);
                          } else {
                            tempLanguages.remove(language);
                          }
                        });
                      },
                      selectedColor: AppColors.primary.withOpacity(0.3),
                      backgroundColor: ThemeUtils.getSurfaceColor(context),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : ThemeUtils.getTextPrimaryColor(context),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: ThemeUtils.getTextSecondaryColor(context)),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLanguages = tempLanguages;
                });
                Navigator.pop(context);
              },
              child: Text(
                'Done',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one language')),
      );
      return;
    }

    if (!_isAvailableOnline && !_isAvailableOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one consultation mode'),
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
        'clinicName': _clinicNameController.text.trim(),
        'clinicAddress': _clinicAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'consultationFee': double.parse(_onlineFeeController.text.trim()),
        'offlineConsultationFee':
            double.parse(_offlineFeeController.text.trim()),
        'languages': _selectedLanguages,
        'isAvailableOnline': _isAvailableOnline,
        'isAvailableOffline': _isAvailableOffline,
      };

      // Save to Firestore
      await DoctorOnboardingService.savePracticeInfo(user.uid, data);

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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Clinic/Hospital Name
          Text(
            'Clinic/Hospital Name *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _clinicNameController,
            decoration: InputDecoration(
              hintText: 'Enter clinic or hospital name',
              prefixIcon: const Icon(Icons.local_hospital),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter clinic/hospital name';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Clinic Address
          Text(
            'Clinic Address *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _clinicAddressController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter complete address',
              prefixIcon: const Icon(Icons.location_on),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter clinic address';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // City
          Text(
            'City *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cityController,
            decoration: InputDecoration(
              hintText: 'Enter city',
              prefixIcon: const Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter city';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // State
          Text(
            'State *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showStateDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.map,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _stateController.text.isEmpty
                          ? 'Select state'
                          : _stateController.text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: _stateController.text.isNotEmpty
                                ? ThemeUtils.getTextPrimaryColor(context)
                                : ThemeUtils.getTextSecondaryColor(context),
                          ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Pincode
          Text(
            'Pincode *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pincodeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'Enter pincode',
              prefixIcon: const Icon(Icons.pin_drop),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter pincode';
              }
              if (value.length != 6) {
                return 'Please enter valid 6-digit pincode';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Consultation Mode
          Text(
            'Consultation Mode *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Online'),
                  value: _isAvailableOnline,
                  onChanged: (value) {
                    setState(() {
                      _isAvailableOnline = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: ThemeUtils.getBorderLightColor(context),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Offline'),
                  value: _isAvailableOffline,
                  onChanged: (value) {
                    setState(() {
                      _isAvailableOffline = value ?? false;
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: ThemeUtils.getBorderLightColor(context),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Online Consultation Fee
          if (_isAvailableOnline) ...[
            Text(
              'Online Consultation Fee (₹) *',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _onlineFeeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter online consultation fee',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (_isAvailableOnline &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter online consultation fee';
                }
                if (value != null && value.isNotEmpty) {
                  final fee = double.tryParse(value);
                  if (fee == null || fee <= 0) {
                    return 'Please enter a valid fee';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Offline Consultation Fee
          if (_isAvailableOffline) ...[
            Text(
              'Offline Consultation Fee (₹) *',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _offlineFeeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter offline consultation fee',
                prefixIcon: const Icon(Icons.currency_rupee),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (_isAvailableOffline &&
                    (value == null || value.trim().isEmpty)) {
                  return 'Please enter offline consultation fee';
                }
                if (value != null && value.isNotEmpty) {
                  final fee = double.tryParse(value);
                  if (fee == null || fee <= 0) {
                    return 'Please enter a valid fee';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
          ],

          // Languages
          Text(
            'Languages Spoken *',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showLanguagesDialog,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: ThemeUtils.getBorderLightColor(context),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language,
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _selectedLanguages.isEmpty
                        ? Text(
                            'Select languages',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                          )
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedLanguages
                                .map(
                                  (lang) => Chip(
                                    label: Text(lang),
                                    backgroundColor: AppColors.primary
                                        .withOpacity(0.1),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedLanguages.remove(lang);
                                      });
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),

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
    ),
    );
  }
}
