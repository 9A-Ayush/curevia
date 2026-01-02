import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/medicine_model.dart';
import '../services/firebase/medicine_service.dart';

/// Medicine categories provider
final medicineCategoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    return await MedicineService.getMedicineCategories();
  } catch (e) {
    print('Error in medicineCategoriesProvider: $e');
    // Return default categories as fallback
    return ['Pain Relief', 'Antibiotics', 'Common Cold & Flu', 'Digestive Health', 'Vitamins & Supplements'];
  }
});

/// Medicines by category provider
final medicinesByCategoryProvider = FutureProvider.family<List<MedicineModel>, String>((ref, category) async {
  try {
    return await MedicineService.getMedicinesByCategory(category);
  } catch (e) {
    print('Error in medicinesByCategoryProvider: $e');
    return [];
  }
});

/// Search medicines provider
final searchMedicinesProvider = FutureProvider.family<List<MedicineModel>, String>((ref, query) async {
  try {
    return await MedicineService.searchMedicines(query);
  } catch (e) {
    print('Error in searchMedicinesProvider: $e');
    return [];
  }
});

/// Medicine by ID provider
final medicineByIdProvider = FutureProvider.family<MedicineModel?, String>((ref, id) async {
  try {
    return await MedicineService.getMedicineById(id);
  } catch (e) {
    print('Error in medicineByIdProvider: $e');
    return null;
  }
});

/// All medicines provider
final allMedicinesProvider = FutureProvider<List<MedicineModel>>((ref) async {
  try {
    return await MedicineService.getAllMedicines();
  } catch (e) {
    print('Error in allMedicinesProvider: $e');
    return [];
  }
});

/// Medicines by brand provider
final medicinesByBrandProvider = FutureProvider.family<List<MedicineModel>, String>((ref, brand) async {
  try {
    return await MedicineService.getMedicinesByBrand(brand);
  } catch (e) {
    print('Error in medicinesByBrandProvider: $e');
    return [];
  }
});

/// Medicine data seeding provider
final seedMedicineDataProvider = FutureProvider<void>((ref) async {
  try {
    await MedicineService.seedIfEmpty();
  } catch (e) {
    print('Error in seedMedicineDataProvider: $e');
    // Don't throw, just log the error
  }
});

/// Check if medicine data exists provider
final hasMedicineDataProvider = FutureProvider<bool>((ref) async {
  try {
    return await MedicineService.hasMedicineData();
  } catch (e) {
    print('Error in hasMedicineDataProvider: $e');
    return false;
  }
});