import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../models/medicine_model.dart';
import '../../constants/app_constants.dart';

/// Service for medicine-related operations
class MedicineService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _medicinesCollection = 'medicines';
  static const String _medicineCategoriesCollection = 'medicine_categories';

  /// Seed medicine data from JSON file to Firestore
  static Future<void> seedMedicineData() async {
    try {
      print('=== SEEDING MEDICINE DATA ===');
      
      // Load JSON data from assets
      print('Loading medicine.json from assets...');
      final String jsonString = await rootBundle.loadString('assets/medicine.json');
      print('JSON loaded, length: ${jsonString.length} characters');
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> categories = jsonData['categories'] ?? [];
      print('Found ${categories.length} categories in JSON');
      
      if (categories.isEmpty) {
        throw Exception('No categories found in medicine.json');
      }
      
      // Clear existing data
      print('Clearing existing medicine data...');
      await _clearExistingMedicineData();
      print('Existing data cleared');
      
      int totalMedicines = 0;
      
      // Add categories and medicines
      for (int i = 0; i < categories.length; i++) {
        final categoryJson = categories[i];
        print('Processing category ${i + 1}/${categories.length}: ${categoryJson['name']}');
        
        final category = MedicineCategoryModel.fromJson(categoryJson);
        
        // Add category document
        await _firestore
            .collection(_medicineCategoriesCollection)
            .doc(category.name.toLowerCase().replaceAll(' ', '_'))
            .set({
          'name': category.name,
          'medicineCount': category.medicines.length,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Category "${category.name}" added with ${category.medicines.length} medicines');
        
        // Add medicines
        for (int j = 0; j < category.medicines.length; j++) {
          final medicine = category.medicines[j];
          await _firestore
              .collection(_medicinesCollection)
              .doc(medicine.id)
              .set(medicine.toMap());
          totalMedicines++;
          
          if (j % 5 == 0) { // Log every 5th medicine
            print('Added medicine ${j + 1}/${category.medicines.length}: ${medicine.name}');
          }
        }
      }
      
      print('=== MEDICINE SEEDING COMPLETED ===');
      print('Successfully seeded ${categories.length} categories and $totalMedicines medicines');
    } catch (e, stackTrace) {
      print('=== ERROR SEEDING MEDICINE DATA ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to seed medicine data: $e');
    }
  }

  /// Clear existing medicine data
  static Future<void> _clearExistingMedicineData() async {
    try {
      // Delete all medicines
      final medicinesSnapshot = await _firestore.collection(_medicinesCollection).get();
      for (final doc in medicinesSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete all categories
      final categoriesSnapshot = await _firestore.collection(_medicineCategoriesCollection).get();
      for (final doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing existing medicine data: $e');
    }
  }

  /// Get all medicine categories
  static Future<List<String>> getMedicineCategories() async {
    try {
      // First ensure data is seeded if user is authenticated
      await seedIfEmpty();
      
      final querySnapshot = await _firestore
          .collection(_medicineCategoriesCollection)
          .orderBy('name')
          .get();
      
      final categories = querySnapshot.docs
          .map((doc) => doc.data()['name'] as String)
          .toList();
      
      print('Retrieved ${categories.length} medicine categories from Firestore');
      
      // If no categories found, return default ones
      if (categories.isEmpty) {
        print('No medicine categories found in Firestore, returning defaults');
        return ['Pain Relief', 'Antibiotics', 'Common Cold & Flu', 'Digestive Health', 'Vitamins & Supplements'];
      }
      
      return categories;
    } catch (e) {
      print('Error getting medicine categories: $e');
      // Return default categories instead of throwing exception
      return ['Pain Relief', 'Antibiotics', 'Common Cold & Flu', 'Digestive Health', 'Vitamins & Supplements'];
    }
  }

  /// Get medicines by category
  static Future<List<MedicineModel>> getMedicinesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_medicinesCollection)
          .where('categoryName', isEqualTo: category)
          .orderBy('name')
          .get();
      
      return querySnapshot.docs
          .map((doc) => MedicineModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting medicines by category: $e');
      // Return empty list instead of throwing exception
      return [];
    }
  }

  /// Search medicines by name or chemical
  static Future<List<MedicineModel>> searchMedicines(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final querySnapshot = await _firestore
          .collection(_medicinesCollection)
          .orderBy('name')
          .get();
      
      final allMedicines = querySnapshot.docs
          .map((doc) => MedicineModel.fromMap(doc.data()))
          .toList();
      
      // Client-side filtering for better search
      final searchQuery = query.toLowerCase();
      return allMedicines.where((medicine) {
        return medicine.name.toLowerCase().contains(searchQuery) ||
               medicine.chemical.toLowerCase().contains(searchQuery) ||
               medicine.uses.toLowerCase().contains(searchQuery) ||
               medicine.brands.any((brand) => brand.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      print('Error searching medicines: $e');
      // Return empty list instead of throwing exception
      return [];
    }
  }

  /// Get medicine by ID
  static Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final doc = await _firestore
          .collection(_medicinesCollection)
          .doc(id)
          .get();
      
      if (doc.exists) {
        return MedicineModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get medicine by ID: $e');
    }
  }

  /// Get all medicines
  static Future<List<MedicineModel>> getAllMedicines({int limit = 100}) async {
    try {
      // First ensure data is seeded
      await seedIfEmpty();

      final querySnapshot = await _firestore
          .collection(_medicinesCollection)
          .orderBy('name')
          .limit(limit)
          .get();
      
      final medicines = querySnapshot.docs
          .map((doc) => MedicineModel.fromMap(doc.data()))
          .toList();
      
      print('Retrieved ${medicines.length} medicines from Firestore');
      
      // If we got fewer medicines than expected, try to seed again
      if (medicines.length < 10) {
        print('Low medicine count (${medicines.length}), attempting to reseed...');
        await seedMedicineData();
        
        // Try again after seeding
        final retrySnapshot = await _firestore
            .collection(_medicinesCollection)
            .orderBy('name')
            .limit(limit)
            .get();
        
        final retriedMedicines = retrySnapshot.docs
            .map((doc) => MedicineModel.fromMap(doc.data()))
            .toList();
        
        print('After reseeding: ${retriedMedicines.length} medicines');
        return retriedMedicines;
      }
      
      return medicines;
    } catch (e) {
      print('Error getting all medicines: $e');
      // Try to seed and return empty list
      try {
        await seedMedicineData();
      } catch (seedError) {
        print('Failed to seed medicines: $seedError');
      }
      return [];
    }
  }

  /// Get medicines by brand
  static Future<List<MedicineModel>> getMedicinesByBrand(String brand) async {
    try {
      final querySnapshot = await _firestore
          .collection(_medicinesCollection)
          .where('brands', arrayContains: brand)
          .orderBy('name')
          .get();
      
      return querySnapshot.docs
          .map((doc) => MedicineModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get medicines by brand: $e');
    }
  }

  /// Check if medicine data exists
  static Future<bool> hasMedicineData() async {
    try {
      final querySnapshot = await _firestore
          .collection(_medicinesCollection)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Seed data if not already present
  static Future<void> seedIfEmpty() async {
    try {
      final hasData = await hasMedicineData();
      if (!hasData) {
        await seedMedicineData();
      }
    } catch (e) {
      print('Error checking/seeding medicine data: $e');
    }
  }
}