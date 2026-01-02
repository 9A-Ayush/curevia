import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/home_remedy_model.dart';
import '../services/firebase/home_remedies_service.dart';

/// Home remedy categories provider
final remedyCategoriesProvider = FutureProvider<List<HomeRemedyCategoryModel>>((ref) async {
  try {
    return await HomeRemediesService.getRemedyCategories();
  } catch (e) {
    print('Error in remedyCategoriesProvider: $e');
    return [];
  }
});

/// Remedies by category provider
final remediesByCategoryProvider = FutureProvider.family<List<HomeRemedyModel>, String>((ref, category) async {
  try {
    return await HomeRemediesService.getRemediesByCategory(category);
  } catch (e) {
    print('Error in remediesByCategoryProvider: $e');
    return [];
  }
});

/// Search remedies provider
final searchRemediesProvider = FutureProvider.family<List<HomeRemedyModel>, String>((ref, query) async {
  try {
    return await HomeRemediesService.searchRemedies(query);
  } catch (e) {
    print('Error in searchRemediesProvider: $e');
    return [];
  }
});

/// Remedy by ID provider
final remedyByIdProvider = FutureProvider.family<HomeRemedyModel?, int>((ref, id) async {
  try {
    return await HomeRemediesService.getRemedyById(id);
  } catch (e) {
    print('Error in remedyByIdProvider: $e');
    return null;
  }
});

/// All remedies provider
final allRemediesProvider = FutureProvider<List<HomeRemedyModel>>((ref) async {
  try {
    return await HomeRemediesService.getAllRemedies();
  } catch (e) {
    print('Error in allRemediesProvider: $e');
    return [];
  }
});

/// Remedies by difficulty provider
final remediesByDifficultyProvider = FutureProvider.family<List<HomeRemedyModel>, String>((ref, difficulty) async {
  try {
    return await HomeRemediesService.getRemediesByDifficulty(difficulty);
  } catch (e) {
    print('Error in remediesByDifficultyProvider: $e');
    return [];
  }
});

/// Remedies by tag provider
final remediesByTagProvider = FutureProvider.family<List<HomeRemedyModel>, String>((ref, tag) async {
  try {
    return await HomeRemediesService.getRemediesByTag(tag);
  } catch (e) {
    print('Error in remediesByTagProvider: $e');
    return [];
  }
});

/// Popular tags provider
final popularTagsProvider = FutureProvider<List<String>>((ref) async {
  try {
    return await HomeRemediesService.getPopularTags();
  } catch (e) {
    print('Error in popularTagsProvider: $e');
    return [];
  }
});

/// Home remedies data seeding provider
final seedRemediesDataProvider = FutureProvider<void>((ref) async {
  try {
    await HomeRemediesService.seedIfEmpty();
  } catch (e) {
    print('Error in seedRemediesDataProvider: $e');
    // Don't throw, just log the error
  }
});

/// Check if remedies data exists provider
final hasRemediesDataProvider = FutureProvider<bool>((ref) async {
  try {
    return await HomeRemediesService.hasRemediesData();
  } catch (e) {
    print('Error in hasRemediesDataProvider: $e');
    return false;
  }
});