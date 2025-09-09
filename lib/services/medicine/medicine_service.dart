import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/medicine_model.dart';

/// Service for medicine-related operations
class MedicineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'medicines';

  /// Search medicines by name or generic name
  static Future<List<MedicineModel>> searchMedicines({
    required String query,
    int limit = 20,
  }) async {
    try {
      if (query.isEmpty) {
        return await getAllMedicines(limit: limit);
      }

      // Search by name (case-insensitive)
      final nameQuery = await _firestore
          .collection(_collection)
          .where('name', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(limit)
          .get();

      // Search by generic name
      final genericQuery = await _firestore
          .collection(_collection)
          .where('genericName', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('genericName', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .limit(limit)
          .get();

      // Combine results and remove duplicates
      final Set<String> seenIds = {};
      final List<MedicineModel> medicines = [];

      for (final doc in [...nameQuery.docs, ...genericQuery.docs]) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          medicines.add(MedicineModel.fromMap({
            'id': doc.id,
            ...doc.data(),
          }));
        }
      }

      return medicines;
    } catch (e) {
      throw Exception('Failed to search medicines: $e');
    }
  }

  /// Get all medicines with pagination
  static Future<List<MedicineModel>> getAllMedicines({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('name')
          .limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        return MedicineModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get medicines: $e');
    }
  }

  /// Get medicines by category
  static Future<List<MedicineModel>> getMedicinesByCategory({
    required String category,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return MedicineModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get medicines by category: $e');
    }
  }

  /// Get medicine by ID
  static Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (!doc.exists) return null;
      
      return MedicineModel.fromMap({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Failed to get medicine: $e');
    }
  }

  /// Get medicine categories
  static Future<List<String>> getMedicineCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .get();

      final Set<String> categories = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['category'] != null) {
          categories.add(data['category'] as String);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Get popular medicines (mock implementation)
  static Future<List<MedicineModel>> getPopularMedicines({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return MedicineModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get popular medicines: $e');
    }
  }

  /// Get medicine alternatives
  static Future<List<MedicineModel>> getMedicineAlternatives(String medicineId) async {
    try {
      final medicine = await getMedicineById(medicineId);
      if (medicine == null || medicine.alternatives == null) {
        return [];
      }

      final List<MedicineModel> alternatives = [];
      for (final altId in medicine.alternatives!) {
        final alt = await getMedicineById(altId);
        if (alt != null) {
          alternatives.add(alt);
        }
      }

      return alternatives;
    } catch (e) {
      throw Exception('Failed to get alternatives: $e');
    }
  }

  /// Check drug interactions
  static Future<List<String>> checkDrugInteractions(List<String> medicineIds) async {
    try {
      final List<String> allInteractions = [];
      
      for (final id in medicineIds) {
        final medicine = await getMedicineById(id);
        if (medicine?.interactions != null) {
          allInteractions.addAll(medicine!.interactions!);
        }
      }

      // Remove duplicates and return
      return allInteractions.toSet().toList();
    } catch (e) {
      throw Exception('Failed to check interactions: $e');
    }
  }

  /// Get medicines by therapeutic class
  static Future<List<MedicineModel>> getMedicinesByTherapeuticClass({
    required String therapeuticClass,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('therapeuticClass', isEqualTo: therapeuticClass)
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return MedicineModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get medicines by therapeutic class: $e');
    }
  }

  /// Get medicines by manufacturer
  static Future<List<MedicineModel>> getMedicinesByManufacturer({
    required String manufacturer,
    int limit = 20,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('manufacturer', isEqualTo: manufacturer)
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return MedicineModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get medicines by manufacturer: $e');
    }
  }

  /// Get prescription medicines
  static Future<List<MedicineModel>> getPrescriptionMedicines({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isPrescriptionRequired', isEqualTo: true)
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return MedicineModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get prescription medicines: $e');
    }
  }

  /// Get OTC medicines
  static Future<List<MedicineModel>> getOTCMedicines({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isOTC', isEqualTo: true)
          .orderBy('name')
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        return MedicineModel.fromMap({
          'id': doc.id,
          ...doc.data(),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get OTC medicines: $e');
    }
  }

  /// Add sample medicines for testing
  static Future<void> addSampleMedicines() async {
    final sampleMedicines = _getSampleMedicines();
    
    for (final medicine in sampleMedicines) {
      await _firestore.collection(_collection).add(medicine.toMap());
    }
  }

  /// Get sample medicines data
  static List<MedicineModel> _getSampleMedicines() {
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
        description: 'Pain reliever and fever reducer',
        uses: 'Treatment of mild to moderate pain and fever',
        dosage: 'Adults: 1-2 tablets every 4-6 hours. Maximum 8 tablets in 24 hours.',
        administration: 'Take with or without food',
        sideEffects: ['Nausea', 'Stomach upset', 'Allergic reactions'],
        contraindications: ['Severe liver disease', 'Allergy to paracetamol'],
        precautions: ['Do not exceed recommended dose', 'Avoid alcohol'],
        interactions: ['Warfarin', 'Phenytoin'],
        storage: 'Store below 30°C in a dry place',
        pregnancyCategory: 'B',
        isOTC: true,
        isPrescriptionRequired: false,
        price: 25.50,
        alternatives: ['ibuprofen_400'],
        isAvailable: true,
        createdAt: now,
        updatedAt: now,
      ),
      // Add more sample medicines...
    ];
  }
}
