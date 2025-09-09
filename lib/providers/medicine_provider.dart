import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../services/medicine/medicine_service.dart';

/// Medicine search state
class MedicineSearchState {
  final bool isLoading;
  final String? error;
  final List<MedicineModel> medicines;
  final List<String> categories;
  final String? selectedCategory;
  final String searchQuery;

  const MedicineSearchState({
    this.isLoading = false,
    this.error,
    this.medicines = const [],
    this.categories = const [],
    this.selectedCategory,
    this.searchQuery = '',
  });

  MedicineSearchState copyWith({
    bool? isLoading,
    String? error,
    List<MedicineModel>? medicines,
    List<String>? categories,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return MedicineSearchState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      medicines: medicines ?? this.medicines,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Medicine search provider notifier
class MedicineSearchNotifier extends StateNotifier<MedicineSearchState> {
  MedicineSearchNotifier() : super(const MedicineSearchState());

  /// Load initial data
  Future<void> loadInitialData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final [medicines, categories] = await Future.wait([
        MedicineService.getPopularMedicines(limit: 20),
        MedicineService.getMedicineCategories(),
      ]);

      state = state.copyWith(
        isLoading: false,
        medicines: medicines as List<MedicineModel>,
        categories: categories as List<String>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Search medicines
  Future<void> searchMedicines(String query) async {
    if (query == state.searchQuery) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      searchQuery: query,
    );

    try {
      List<MedicineModel> medicines;
      if (query.isEmpty) {
        medicines = await MedicineService.getPopularMedicines(limit: 20);
      } else {
        medicines = await MedicineService.searchMedicines(
          query: query,
          limit: 50,
        );
      }

      state = state.copyWith(
        isLoading: false,
        medicines: medicines,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Filter by category
  Future<void> filterByCategory(String? category) async {
    if (category == state.selectedCategory) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedCategory: category,
    );

    try {
      List<MedicineModel> medicines;
      if (category == null) {
        medicines = await MedicineService.getPopularMedicines(limit: 20);
      } else {
        medicines = await MedicineService.getMedicinesByCategory(
          category: category,
          limit: 50,
        );
      }

      state = state.copyWith(
        isLoading: false,
        medicines: medicines,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear search and filters
  void clearSearch() {
    state = state.copyWith(
      searchQuery: '',
      selectedCategory: null,
    );
    loadInitialData();
  }
}

/// Medicine search provider
final medicineSearchProvider = StateNotifierProvider<MedicineSearchNotifier, MedicineSearchState>((ref) {
  return MedicineSearchNotifier();
});

/// Individual medicine provider
final medicineProvider = FutureProvider.family<MedicineModel?, String>((ref, medicineId) async {
  return await MedicineService.getMedicineById(medicineId);
});

/// Medicine alternatives provider
final medicineAlternativesProvider = FutureProvider.family<List<MedicineModel>, String>((ref, medicineId) async {
  return await MedicineService.getMedicineAlternatives(medicineId);
});

/// Popular medicines provider
final popularMedicinesProvider = FutureProvider<List<MedicineModel>>((ref) async {
  return await MedicineService.getPopularMedicines(limit: 10);
});

/// Medicine categories provider
final medicineCategoriesProvider = FutureProvider<List<String>>((ref) async {
  return await MedicineService.getMedicineCategories();
});

/// Prescription medicines provider
final prescriptionMedicinesProvider = FutureProvider<List<MedicineModel>>((ref) async {
  return await MedicineService.getPrescriptionMedicines(limit: 20);
});

/// OTC medicines provider
final otcMedicinesProvider = FutureProvider<List<MedicineModel>>((ref) async {
  return await MedicineService.getOTCMedicines(limit: 20);
});

/// Drug interactions checker provider
final drugInteractionsProvider = FutureProvider.family<List<String>, List<String>>((ref, medicineIds) async {
  return await MedicineService.checkDrugInteractions(medicineIds);
});

/// Sample data provider for testing
final sampleMedicinesProvider = Provider<List<MedicineModel>>((ref) {
  final now = DateTime.now();
  
  return [
    MedicineModel(
      id: 'paracetamol_500',
      name: 'Paracetamol',
      genericName: 'Acetaminophen',
      brandName: 'Crocin',
      manufacturer: 'GSK',
      category: 'Analgesics',
      therapeuticClass: 'Non-narcotic analgesic',
      composition: 'Paracetamol 500mg',
      strength: '500mg',
      dosageForm: 'Tablet',
      description: 'Pain reliever and fever reducer commonly used for headaches, muscle aches, and fever.',
      uses: 'Treatment of mild to moderate pain and fever. Effective for headaches, toothaches, muscle pain, and reducing fever.',
      dosage: 'Adults: 1-2 tablets every 4-6 hours as needed. Do not exceed 8 tablets in 24 hours. Children: Consult pediatrician for appropriate dosing.',
      administration: 'Take with or without food. Swallow whole with water. Do not crush or chew.',
      sideEffects: ['Nausea', 'Stomach upset', 'Allergic reactions (rare)', 'Liver damage (with overdose)'],
      contraindications: ['Severe liver disease', 'Known allergy to paracetamol', 'Chronic alcohol use'],
      precautions: ['Do not exceed recommended dose', 'Avoid alcohol while taking', 'Consult doctor if symptoms persist'],
      interactions: ['Warfarin (blood thinner)', 'Phenytoin (seizure medication)', 'Alcohol'],
      storage: 'Store below 30°C in a dry place. Keep away from children.',
      pregnancyCategory: 'B',
      isOTC: true,
      isPrescriptionRequired: false,
      price: 25.50,
      alternatives: ['ibuprofen_400', 'aspirin_500'],
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    ),
    MedicineModel(
      id: 'ibuprofen_400',
      name: 'Ibuprofen',
      genericName: 'Ibuprofen',
      brandName: 'Brufen',
      manufacturer: 'Abbott',
      category: 'NSAIDs',
      therapeuticClass: 'Non-steroidal anti-inflammatory drug',
      composition: 'Ibuprofen 400mg',
      strength: '400mg',
      dosageForm: 'Tablet',
      description: 'Anti-inflammatory pain reliever that reduces pain, fever, and inflammation.',
      uses: 'Treatment of pain, fever, and inflammation. Effective for arthritis, muscle pain, dental pain, and menstrual cramps.',
      dosage: 'Adults: 1 tablet every 6-8 hours as needed. Maximum 3 tablets per day. Take with food to reduce stomach irritation.',
      administration: 'Take with food or milk to minimize stomach upset. Swallow whole with plenty of water.',
      sideEffects: ['Stomach upset', 'Nausea', 'Heartburn', 'Dizziness', 'Headache'],
      contraindications: ['Peptic ulcer', 'Severe heart failure', 'Kidney disease', 'Allergy to NSAIDs'],
      precautions: ['Take with food', 'Monitor for stomach problems', 'Use lowest effective dose'],
      interactions: ['Blood thinners', 'ACE inhibitors', 'Lithium', 'Methotrexate'],
      storage: 'Store at room temperature. Protect from moisture.',
      pregnancyCategory: 'C',
      isOTC: true,
      isPrescriptionRequired: false,
      price: 45.00,
      alternatives: ['paracetamol_500', 'diclofenac_50'],
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    ),
    MedicineModel(
      id: 'amoxicillin_500',
      name: 'Amoxicillin',
      genericName: 'Amoxicillin',
      brandName: 'Amoxil',
      manufacturer: 'Cipla',
      category: 'Antibiotics',
      therapeuticClass: 'Penicillin antibiotic',
      composition: 'Amoxicillin 500mg',
      strength: '500mg',
      dosageForm: 'Capsule',
      description: 'Broad-spectrum antibiotic used to treat various bacterial infections.',
      uses: 'Treatment of bacterial infections including respiratory tract infections, urinary tract infections, and skin infections.',
      dosage: 'Adults: 1 capsule every 8 hours for 7-10 days. Complete the full course even if feeling better.',
      administration: 'Take with or without food. Space doses evenly throughout the day.',
      sideEffects: ['Diarrhea', 'Nausea', 'Vomiting', 'Skin rash', 'Allergic reactions'],
      contraindications: ['Allergy to penicillin', 'Severe kidney disease', 'Mononucleosis'],
      precautions: ['Complete full course', 'Report any allergic reactions', 'May reduce effectiveness of birth control'],
      interactions: ['Oral contraceptives', 'Warfarin', 'Methotrexate'],
      storage: 'Store in a cool, dry place. Keep refrigerated if liquid form.',
      pregnancyCategory: 'B',
      isOTC: false,
      isPrescriptionRequired: true,
      price: 120.00,
      alternatives: ['azithromycin_500', 'cephalexin_500'],
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    ),
    MedicineModel(
      id: 'omeprazole_20',
      name: 'Omeprazole',
      genericName: 'Omeprazole',
      brandName: 'Prilosec',
      manufacturer: 'Dr. Reddy\'s',
      category: 'Gastric',
      therapeuticClass: 'Proton pump inhibitor',
      composition: 'Omeprazole 20mg',
      strength: '20mg',
      dosageForm: 'Capsule',
      description: 'Reduces stomach acid production to treat acid-related disorders.',
      uses: 'Treatment of gastroesophageal reflux disease (GERD), peptic ulcers, and Zollinger-Ellison syndrome.',
      dosage: 'Adults: 1 capsule daily before breakfast. May be increased to 2 capsules daily if needed.',
      administration: 'Take before meals, preferably in the morning. Swallow whole, do not crush or chew.',
      sideEffects: ['Headache', 'Nausea', 'Diarrhea', 'Stomach pain', 'Dizziness'],
      contraindications: ['Allergy to omeprazole', 'Severe liver disease'],
      precautions: ['Long-term use may affect bone density', 'May mask symptoms of stomach cancer'],
      interactions: ['Clopidogrel', 'Warfarin', 'Digoxin', 'Iron supplements'],
      storage: 'Store at room temperature in original container.',
      pregnancyCategory: 'C',
      isOTC: false,
      isPrescriptionRequired: true,
      price: 85.00,
      alternatives: ['pantoprazole_40', 'lansoprazole_30'],
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    ),
    MedicineModel(
      id: 'cetirizine_10',
      name: 'Cetirizine',
      genericName: 'Cetirizine',
      brandName: 'Zyrtec',
      manufacturer: 'Sun Pharma',
      category: 'Antihistamines',
      therapeuticClass: 'H1 antihistamine',
      composition: 'Cetirizine 10mg',
      strength: '10mg',
      dosageForm: 'Tablet',
      description: 'Antihistamine used to treat allergic reactions and symptoms.',
      uses: 'Treatment of allergic rhinitis, urticaria (hives), and other allergic conditions.',
      dosage: 'Adults: 1 tablet daily, preferably in the evening. Children 6-12 years: Half tablet daily.',
      administration: 'Take with or without food. May cause drowsiness, avoid driving.',
      sideEffects: ['Drowsiness', 'Dry mouth', 'Fatigue', 'Headache', 'Nausea'],
      contraindications: ['Severe kidney disease', 'End-stage renal disease', 'Allergy to cetirizine'],
      precautions: ['May cause drowsiness', 'Avoid alcohol', 'Use caution when driving'],
      interactions: ['Alcohol', 'CNS depressants', 'Theophylline'],
      storage: 'Store at room temperature. Protect from moisture.',
      pregnancyCategory: 'B',
      isOTC: true,
      isPrescriptionRequired: false,
      price: 35.00,
      alternatives: ['loratadine_10', 'fexofenadine_120'],
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];
});
