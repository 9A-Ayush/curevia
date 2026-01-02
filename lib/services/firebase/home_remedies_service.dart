import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../models/home_remedy_model.dart';
import '../../constants/app_constants.dart';

/// Service for home remedies-related operations
class HomeRemediesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _remediesCollection = 'home_remedies';
  static const String _remedyCategoriesCollection = 'home_remedy_categories';

  /// Seed home remedies data from JSON file to Firestore
  static Future<void> seedHomeRemediesData() async {
    try {
      print('=== SEEDING HOME REMEDIES DATA ===');
      
      // Load JSON data from assets
      print('Loading home_remedies.json from assets...');
      final String jsonString = await rootBundle.loadString('assets/home_remedies.json');
      print('JSON loaded, length: ${jsonString.length} characters');
      
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> categories = jsonData['categories'] ?? [];
      print('Found ${categories.length} categories in JSON');
      
      if (categories.isEmpty) {
        throw Exception('No categories found in home_remedies.json');
      }
      
      // Clear existing data
      print('Clearing existing remedies data...');
      await _clearExistingRemediesData();
      print('Existing data cleared');
      
      int totalRemedies = 0;
      
      // Add categories and remedies
      for (int i = 0; i < categories.length; i++) {
        final categoryJson = categories[i];
        print('Processing category ${i + 1}/${categories.length}: ${categoryJson['name']}');
        
        final category = HomeRemedyCategoryModel.fromJson(categoryJson);
        
        // Add category document
        await _firestore
            .collection(_remedyCategoriesCollection)
            .doc(category.id.toString())
            .set({
          'id': category.id,
          'name': category.name,
          'remedyCount': category.remedies.length,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Category "${category.name}" added with ${category.remedies.length} remedies');
        
        // Add remedies
        for (int j = 0; j < category.remedies.length; j++) {
          final remedy = category.remedies[j];
          await _firestore
              .collection(_remediesCollection)
              .doc(remedy.id.toString())
              .set(remedy.toMap());
          totalRemedies++;
          
          if (j % 3 == 0) { // Log every 3rd remedy
            print('Added remedy ${j + 1}/${category.remedies.length}: ${remedy.title}');
          }
        }
      }
      
      print('=== HOME REMEDIES SEEDING COMPLETED ===');
      print('Successfully seeded ${categories.length} categories and $totalRemedies remedies');
    } catch (e, stackTrace) {
      print('=== ERROR SEEDING HOME REMEDIES DATA ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to seed home remedies data: $e');
    }
  }

  /// Clear existing remedies data
  static Future<void> _clearExistingRemediesData() async {
    try {
      // Delete all remedies
      final remediesSnapshot = await _firestore.collection(_remediesCollection).get();
      for (final doc in remediesSnapshot.docs) {
        await doc.reference.delete();
      }
      
      // Delete all categories
      final categoriesSnapshot = await _firestore.collection(_remedyCategoriesCollection).get();
      for (final doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing existing remedies data: $e');
    }
  }

  /// Get all remedy categories
  static Future<List<HomeRemedyCategoryModel>> getRemedyCategories() async {
    try {
      // First check if we have data, if not seed it
      final hasData = await hasRemediesData();
      if (!hasData) {
        print('No remedies data found, seeding...');
        await seedHomeRemediesData();
      }

      final querySnapshot = await _firestore
          .collection(_remedyCategoriesCollection)
          .orderBy('id')
          .get();
      
      final categories = <HomeRemedyCategoryModel>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final categoryName = data['name'] as String;
        final categoryId = data['id'] as int;
        
        // Get remedies for this category
        final remedies = await getRemediesByCategory(categoryName);
        
        categories.add(HomeRemedyCategoryModel(
          id: categoryId,
          name: categoryName,
          remedies: remedies,
        ));
      }
      
      print('Retrieved ${categories.length} remedy categories from Firestore');
      return categories;
    } catch (e) {
      print('Error getting remedy categories: $e');
      // Return empty list instead of throwing exception
      return [];
    }
  }

  /// Get remedies by category
  static Future<List<HomeRemedyModel>> getRemediesByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_remediesCollection)
          .where('categoryName', isEqualTo: category)
          .orderBy('id')
          .get();
      
      return querySnapshot.docs
          .map((doc) => HomeRemedyModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting remedies by category: $e');
      // Return empty list instead of throwing exception
      return [];
    }
  }

  /// Search remedies by title, description, or tags
  static Future<List<HomeRemedyModel>> searchRemedies(String query) async {
    try {
      if (query.isEmpty) return [];
      
      final querySnapshot = await _firestore
          .collection(_remediesCollection)
          .orderBy('title')
          .get();
      
      final allRemedies = querySnapshot.docs
          .map((doc) => HomeRemedyModel.fromMap(doc.data()))
          .toList();
      
      // Client-side filtering for better search
      final searchQuery = query.toLowerCase();
      return allRemedies.where((remedy) {
        return remedy.title.toLowerCase().contains(searchQuery) ||
               remedy.description.toLowerCase().contains(searchQuery) ||
               remedy.tags.any((tag) => tag.toLowerCase().contains(searchQuery)) ||
               remedy.ingredients.any((ingredient) => ingredient.toLowerCase().contains(searchQuery));
      }).toList();
    } catch (e) {
      print('Error searching remedies: $e');
      // Return empty list instead of throwing exception
      return [];
    }
  }

  /// Get remedy by ID
  static Future<HomeRemedyModel?> getRemedyById(int id) async {
    try {
      final doc = await _firestore
          .collection(_remediesCollection)
          .doc(id.toString())
          .get();
      
      if (doc.exists) {
        return HomeRemedyModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get remedy by ID: $e');
    }
  }

  /// Get all remedies
  static Future<List<HomeRemedyModel>> getAllRemedies({int limit = 50}) async {
    try {
      // First check if we have data, if not seed it
      final hasData = await hasRemediesData();
      if (!hasData) {
        print('No remedies data found, seeding...');
        await seedHomeRemediesData();
      }

      final querySnapshot = await _firestore
          .collection(_remediesCollection)
          .orderBy('title')
          .limit(limit)
          .get();
      
      final remedies = querySnapshot.docs
          .map((doc) => HomeRemedyModel.fromMap(doc.data()))
          .toList();
      
      print('Retrieved ${remedies.length} remedies from Firestore');
      return remedies;
    } catch (e) {
      print('Error getting all remedies: $e');
      // Return empty list instead of throwing exception
      return [];
    }
  }

  /// Get remedies by difficulty level
  static Future<List<HomeRemedyModel>> getRemediesByDifficulty(String difficulty) async {
    try {
      final querySnapshot = await _firestore
          .collection(_remediesCollection)
          .where('difficulty', isEqualTo: difficulty)
          .orderBy('title')
          .get();
      
      return querySnapshot.docs
          .map((doc) => HomeRemedyModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get remedies by difficulty: $e');
    }
  }

  /// Get remedies by tags
  static Future<List<HomeRemedyModel>> getRemediesByTag(String tag) async {
    try {
      final querySnapshot = await _firestore
          .collection(_remediesCollection)
          .where('tags', arrayContains: tag)
          .orderBy('title')
          .get();
      
      return querySnapshot.docs
          .map((doc) => HomeRemedyModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get remedies by tag: $e');
    }
  }

  /// Get popular tags
  static Future<List<String>> getPopularTags({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_remediesCollection)
          .get();
      
      final tagCounts = <String, int>{};
      
      for (final doc in querySnapshot.docs) {
        final remedy = HomeRemedyModel.fromMap(doc.data());
        for (final tag in remedy.tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
      
      // Sort by count and return top tags
      final sortedTags = tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedTags
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      throw Exception('Failed to get popular tags: $e');
    }
  }

  /// Check if remedies data exists
  static Future<bool> hasRemediesData() async {
    try {
      final querySnapshot = await _firestore
          .collection(_remediesCollection)
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
      final hasData = await hasRemediesData();
      if (!hasData) {
        await seedHomeRemediesData();
      }
    } catch (e) {
      print('Error checking/seeding remedies data: $e');
    }
  }
}