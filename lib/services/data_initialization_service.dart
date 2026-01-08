import 'package:firebase_auth/firebase_auth.dart';
import 'firebase/medicine_service.dart';
import 'firebase/home_remedies_service.dart';

/// Service to handle data initialization after user authentication
class DataInitializationService {
  static bool _isInitialized = false;
  static bool _isInitializing = false;

  /// Initialize app data after user authentication
  static Future<void> initializeAfterAuth() async {
    if (_isInitialized || _isInitializing) {
      print('Data initialization already completed or in progress');
      return;
    }

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated, skipping data initialization');
      return;
    }

    _isInitializing = true;
    
    try {
      print('=== INITIALIZING DATA AFTER AUTHENTICATION ===');
      print('User authenticated: ${user.uid}');
      
      // Initialize medicine data
      await _initializeMedicineData();
      
      // Initialize home remedies data
      await _initializeRemediesData();
      
      _isInitialized = true;
      print('=== DATA INITIALIZATION COMPLETED ===');
    } catch (e) {
      print('=== ERROR IN DATA INITIALIZATION ===');
      print('Error: $e');
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize medicine data
  static Future<void> _initializeMedicineData() async {
    try {
      print('Checking medicine data...');
      final hasData = await MedicineService.hasMedicineData();
      print('Medicine data exists: $hasData');
      
      if (!hasData) {
        print('Seeding medicine data...');
        await MedicineService.seedMedicineData();
        print('Medicine data seeded successfully');
      } else {
        print('Medicine data already exists, skipping seeding');
      }
      
      // Verify by getting categories
      final categories = await MedicineService.getMedicineCategories();
      print('Medicine categories available: ${categories.length}');
      for (final category in categories) {
        print('  - $category');
      }
    } catch (e) {
      print('Error initializing medicine data: $e');
    }
  }

  /// Initialize home remedies data
  static Future<void> _initializeRemediesData() async {
    try {
      print('Checking remedies data...');
      final hasData = await HomeRemediesService.hasRemediesData();
      print('Remedies data exists: $hasData');
      
      if (!hasData) {
        print('Seeding remedies data...');
        await HomeRemediesService.seedHomeRemediesData();
        print('Remedies data seeded successfully');
      } else {
        print('Remedies data already exists, skipping seeding');
      }
      
      // Verify by getting categories
      final categories = await HomeRemediesService.getRemedyCategories();
      print('Remedy categories available: ${categories.length}');
      for (final category in categories) {
        print('  - ${category.name}');
      }
    } catch (e) {
      print('Error initializing remedies data: $e');
    }
  }

  /// Force re-initialization (useful for debugging)
  static Future<void> forceReinitialize() async {
    _isInitialized = false;
    _isInitializing = false;
    await initializeAfterAuth();
  }

  /// Check if data is initialized
  static bool get isInitialized => _isInitialized;

  /// Check if initialization is in progress
  static bool get isInitializing => _isInitializing;

  /// Manual seeding for debugging
  static Future<void> manualSeed() async {
    try {
      print('=== MANUAL SEEDING STARTED ===');
      
      // Force seed medicine data
      print('Force seeding medicine data...');
      await MedicineService.seedMedicineData();
      
      // Verify medicine data
      final medicineCount = await MedicineService.getAllMedicines();
      print('Medicine seeding result: ${medicineCount.length} medicines');
      
      // Force seed remedies data
      print('Force seeding remedies data...');
      await HomeRemediesService.seedHomeRemediesData();
      
      // Verify remedies data
      final remediesCount = await HomeRemediesService.getAllRemedies();
      print('Remedies seeding result: ${remediesCount.length} remedies');
      
      print('=== MANUAL SEEDING COMPLETED ===');
      print('Total: ${medicineCount.length} medicines, ${remediesCount.length} remedies');
    } catch (e) {
      print('=== MANUAL SEEDING FAILED ===');
      print('Error: $e');
      rethrow;
    }
  }
}