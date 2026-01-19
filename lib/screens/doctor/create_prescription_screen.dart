import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../services/firebase/patient_search_service.dart';

/// Create new prescription screen
class CreatePrescriptionScreen extends ConsumerStatefulWidget {
  final AppointmentModel? appointment;
  
  const CreatePrescriptionScreen({
    super.key,
    this.appointment,
  });

  @override
  ConsumerState<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends ConsumerState<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _symptomsController = TextEditingController();
  final _notesController = TextEditingController();
  final _followUpInstructionsController = TextEditingController();
  
  UserModel? _selectedPatient;
  DateTime? _followUpDate;
  List<PrescribedMedicine> _medicines = [];
  List<String> _instructions = [];
  List<String> _precautions = [];
  List<String> _tests = [];
  bool _isLoading = false;
  List<UserModel> _recentPatients = [];
  List<UserModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // If appointment is provided, get the patient details
    if (widget.appointment != null) {
      final patient = await PatientSearchService.getPatientById(widget.appointment!.patientId);
      if (patient != null) {
        setState(() {
          _selectedPatient = patient;
        });
      }
    }
    
    // Load recent patients for this doctor
    final user = ref.read(authProvider).userModel;
    if (user != null) {
      final recentPatients = await PatientSearchService.getRecentPatients(
        doctorId: user.uid,
        limit: 10,
      );
      setState(() {
        _recentPatients = recentPatients;
      });
    }
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _symptomsController.dispose();
    _notesController.dispose();
    _followUpInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeUtils.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Create Prescription'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePrescription,
            child: Text(
              'Save',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Information
              _buildSection(
                'Patient Information',
                [
                  // Patient selector
                  InkWell(
                    onTap: _showPatientSelector,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: _selectedPatient != null ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedPatient != null ? 'Selected Patient' : 'Select Patient *',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedPatient?.fullName ?? 'Tap to select a registered patient',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedPatient != null ? Colors.black : Colors.grey,
                                    fontWeight: _selectedPatient != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                if (_selectedPatient != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedPatient!.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedPatient == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Please select a registered patient from the list',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              
              // Clinical Information
              _buildSection(
                'Clinical Information',
                [
                  TextFormField(
                    controller: _diagnosisController,
                    decoration: const InputDecoration(
                      labelText: 'Diagnosis',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _symptomsController,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              
              // Medicines
              _buildSection(
                'Prescribed Medicines',
                [
                  ..._medicines.asMap().entries.map((entry) {
                    final index = entry.key;
                    final medicine = entry.value;
                    return _buildMedicineCard(medicine, index);
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addMedicine,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Medicine'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              
              // Instructions
              _buildSection(
                'Instructions',
                [
                  ..._instructions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final instruction = entry.value;
                    return _buildListItem(
                      instruction,
                      () => _removeInstruction(index),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addInstruction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Instruction'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              
              // Precautions
              _buildSection(
                'Precautions',
                [
                  ..._precautions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final precaution = entry.value;
                    return _buildListItem(
                      precaution,
                      () => _removePrecaution(index),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addPrecaution,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Precaution'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              
              // Tests
              _buildSection(
                'Recommended Tests',
                [
                  ..._tests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final test = entry.value;
                    return _buildListItem(
                      test,
                      () => _removeTest(index),
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _addTest,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Test'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              
              // Follow-up
              _buildSection(
                'Follow-up',
                [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _followUpDate == null
                              ? 'No follow-up date set'
                              : 'Follow-up: ${_formatDate(_followUpDate!)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: _selectFollowUpDate,
                        child: Text(_followUpDate == null ? 'Set Date' : 'Change'),
                      ),
                      if (_followUpDate != null)
                        IconButton(
                          onPressed: () => setState(() => _followUpDate = null),
                          icon: const Icon(Icons.clear),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _followUpInstructionsController,
                    decoration: const InputDecoration(
                      labelText: 'Follow-up Instructions',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              
              // Additional Notes
              _buildSection(
                'Additional Notes',
                [
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Create Prescription',
                  onPressed: _isLoading ? null : _savePrescription,
                  isLoading: _isLoading,
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildMedicineCard(PrescribedMedicine medicine, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    medicine.fullName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeMedicine(index),
                  icon: const Icon(Icons.delete_outline),
                  color: AppColors.error,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              medicine.completeInstruction,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (medicine.instructions != null) ...[
              const SizedBox(height: 4),
              Text(
                medicine.instructions!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ThemeUtils.getTextSecondaryColor(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text, VoidCallback onRemove) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(text),
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline),
          color: AppColors.error,
        ),
      ),
    );
  }

  void _addMedicine() {
    showDialog(
      context: context,
      builder: (context) => _MedicineDialog(
        onSave: (medicine) {
          setState(() => _medicines.add(medicine));
        },
      ),
    );
  }

  void _removeMedicine(int index) {
    setState(() => _medicines.removeAt(index));
  }

  void _addInstruction() {
    _showTextInputDialog(
      'Add Instruction',
      'Enter instruction',
      (text) => setState(() => _instructions.add(text)),
    );
  }

  void _removeInstruction(int index) {
    setState(() => _instructions.removeAt(index));
  }

  void _addPrecaution() {
    _showTextInputDialog(
      'Add Precaution',
      'Enter precaution',
      (text) => setState(() => _precautions.add(text)),
    );
  }

  void _removePrecaution(int index) {
    setState(() => _precautions.removeAt(index));
  }

  void _addTest() {
    _showTextInputDialog(
      'Add Test',
      'Enter test name',
      (text) => setState(() => _tests.add(text)),
    );
  }

  void _removeTest(int index) {
    setState(() => _tests.removeAt(index));
  }

  void _showTextInputDialog(String title, String hint, Function(String) onSave) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSave(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectFollowUpDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _followUpDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() => _followUpDate = date);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a patient')),
      );
      return;
    }
    
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authProvider).userModel;
      if (user == null) throw Exception('User not found');

      final prescription = PrescriptionModel(
        id: '',
        appointmentId: widget.appointment?.id ?? '',
        patientId: _selectedPatient!.uid,
        doctorId: user.uid,
        patientName: _selectedPatient!.fullName,
        doctorName: user.fullName,
        doctorSpecialty: 'General Physician', // Default since UserModel doesn't have specialty
        prescriptionDate: DateTime.now(),
        diagnosis: _diagnosisController.text.trim().isEmpty ? null : _diagnosisController.text.trim(),
        symptoms: _symptomsController.text.trim().isEmpty ? null : _symptomsController.text.trim(),
        medicines: _medicines,
        instructions: _instructions.isEmpty ? null : _instructions,
        precautions: _precautions.isEmpty ? null : _precautions,
        followUpInstructions: _followUpInstructionsController.text.trim().isEmpty 
            ? null : _followUpInstructionsController.text.trim(),
        followUpDate: _followUpDate,
        tests: _tests.isEmpty ? null : _tests,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('prescriptions')
          .add(prescription.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription created successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating prescription: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show patient selector dialog
  void _showPatientSelector() {
    showDialog(
      context: context,
      builder: (context) => _PatientSelectorDialog(
        recentPatients: _recentPatients,
        onPatientSelected: (patient) {
          setState(() {
            _selectedPatient = patient;
          });
        },
      ),
    );
  }
}

/// Medicine input dialog
class _MedicineDialog extends StatefulWidget {
  final Function(PrescribedMedicine) onSave;

  const _MedicineDialog({required this.onSave});

  @override
  State<_MedicineDialog> createState() => _MedicineDialogState();
}

class _MedicineDialogState extends State<_MedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _durationController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedTiming = 'After meals';
  String _selectedForm = 'Tablet';

  final List<String> _timingOptions = [
    'Before meals',
    'After meals',
    'With meals',
    'Empty stomach',
    'As needed',
  ];

  final List<String> _formOptions = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Drops',
    'Cream',
    'Ointment',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medicine'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _strengthController,
                      decoration: const InputDecoration(
                        labelText: 'Strength',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 500mg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedForm,
                      decoration: const InputDecoration(
                        labelText: 'Form',
                        border: OutlineInputBorder(),
                      ),
                      items: _formOptions.map((form) => 
                        DropdownMenuItem(value: form, child: Text(form))
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedForm = value!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dosageController,
                      decoration: const InputDecoration(
                        labelText: 'Dosage *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 1 tablet',
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _frequencyController,
                      decoration: const InputDecoration(
                        labelText: 'Frequency *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., twice daily',
                      ),
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedTiming,
                      decoration: const InputDecoration(
                        labelText: 'Timing',
                        border: OutlineInputBorder(),
                      ),
                      items: _timingOptions.map((timing) => 
                        DropdownMenuItem(value: timing, child: Text(timing))
                      ).toList(),
                      onChanged: (value) => setState(() => _selectedTiming = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: 'Duration (days) *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Required';
                        if (int.tryParse(value!) == null) return 'Invalid number';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saveMedicine,
          child: const Text('Add'),
        ),
      ],
    );
  }

  void _saveMedicine() {
    if (!_formKey.currentState!.validate()) return;

    final medicine = PrescribedMedicine(
      medicineId: DateTime.now().millisecondsSinceEpoch.toString(),
      medicineName: _nameController.text.trim(),
      strength: _strengthController.text.trim().isEmpty ? null : _strengthController.text.trim(),
      dosageForm: _selectedForm,
      dosage: _dosageController.text.trim(),
      frequency: _frequencyController.text.trim(),
      timing: _selectedTiming,
      duration: int.parse(_durationController.text.trim()),
      instructions: _instructionsController.text.trim().isEmpty 
          ? null : _instructionsController.text.trim(),
    );

    widget.onSave(medicine);
    Navigator.pop(context);
  }
}

/// Patient selector dialog
class _PatientSelectorDialog extends StatefulWidget {
  final List<UserModel> recentPatients;
  final Function(UserModel) onPatientSelected;

  const _PatientSelectorDialog({
    required this.recentPatients,
    required this.onPatientSelected,
  });

  @override
  State<_PatientSelectorDialog> createState() => _PatientSelectorDialogState();
}

class _PatientSelectorDialogState extends State<_PatientSelectorDialog> {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.recentPatients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Select Patient',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            
            // Results
            Expanded(
              child: _searchResults.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final patient = _searchResults[index];
                        return _buildPatientTile(patient);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No recent patients found'
                : 'No patients found matching your search',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Start typing to search for patients'
                : 'Try a different search term',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientTile(UserModel patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            patient.fullName
                .split(' ')
                .map((e) => e[0])
                .take(2)
                .join()
                .toUpperCase(),
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(patient.email),
            if (patient.phoneNumber != null)
              Text(patient.phoneNumber!),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          widget.onPatientSelected(patient);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = widget.recentPatients;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await PatientSearchService.searchPatients(
        searchQuery: query,
        limit: 20,
      );
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    }
  }
}