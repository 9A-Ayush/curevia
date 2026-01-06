import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing BMI calculations and history
class BmiService {
  static const String _bmiHistoryKey = 'bmi_history';
  static const String _currentBmiKey = 'current_bmi';
  static const String _heightKey = 'user_height';
  static const String _weightKey = 'user_weight';
  static const String _isMetricKey = 'is_metric_units';

  /// Calculate BMI from height and weight
  static double calculateBMI({
    required double height,
    required double weight,
    required bool isMetric,
  }) {
    if (isMetric) {
      // Height in cm, weight in kg
      final heightInMeters = height / 100;
      return weight / (heightInMeters * heightInMeters);
    } else {
      // Height in inches, weight in lbs
      return (weight / (height * height)) * 703;
    }
  }

  /// Get BMI category and description
  static BmiCategory getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return BmiCategory(
        category: 'Underweight',
        description: 'You may need to gain some weight. Consider consulting a healthcare provider.',
        color: 'info',
        range: '< 18.5',
      );
    } else if (bmi < 25) {
      return BmiCategory(
        category: 'Normal Weight',
        description: 'Great! You have a healthy weight. Keep maintaining your current lifestyle.',
        color: 'success',
        range: '18.5 - 24.9',
      );
    } else if (bmi < 30) {
      return BmiCategory(
        category: 'Overweight',
        description: 'Consider adopting a healthier diet and exercise routine.',
        color: 'warning',
        range: '25.0 - 29.9',
      );
    } else {
      return BmiCategory(
        category: 'Obese',
        description: 'It\'s recommended to consult with a healthcare provider for a weight management plan.',
        color: 'error',
        range: '≥ 30.0',
      );
    }
  }

  /// Save BMI calculation result
  static Future<void> saveBMIResult({
    required double height,
    required double weight,
    required bool isMetric,
    required double bmi,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save current BMI
    await prefs.setDouble(_currentBmiKey, bmi);
    await prefs.setDouble(_heightKey, height);
    await prefs.setDouble(_weightKey, weight);
    await prefs.setBool(_isMetricKey, isMetric);
    
    // Save to history
    final history = await getBMIHistory();
    final newEntry = BmiHistoryEntry(
      bmi: bmi,
      height: height,
      weight: weight,
      isMetric: isMetric,
      date: DateTime.now(),
    );
    
    history.insert(0, newEntry);
    
    // Keep only last 50 entries
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    
    final historyJson = history.map((e) => e.toJson()).toList();
    await prefs.setString(_bmiHistoryKey, json.encode(historyJson));
  }

  /// Get current BMI
  static Future<double?> getCurrentBMI() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_currentBmiKey);
  }

  /// Get current height
  static Future<double?> getCurrentHeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_heightKey);
  }

  /// Get current weight
  static Future<double?> getCurrentWeight() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_weightKey);
  }

  /// Get unit preference
  static Future<bool> getIsMetric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isMetricKey) ?? true;
  }

  /// Get BMI history
  static Future<List<BmiHistoryEntry>> getBMIHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_bmiHistoryKey);
    
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> historyList = json.decode(historyJson);
      return historyList.map((json) => BmiHistoryEntry.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear BMI history
  static Future<void> clearBMIHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bmiHistoryKey);
    await prefs.remove(_currentBmiKey);
    await prefs.remove(_heightKey);
    await prefs.remove(_weightKey);
    await prefs.remove(_isMetricKey);
  }

  /// Get BMI trend (last 7 entries)
  static Future<List<BmiHistoryEntry>> getBMITrend() async {
    final history = await getBMIHistory();
    return history.take(7).toList();
  }
}

/// BMI Category model
class BmiCategory {
  final String category;
  final String description;
  final String color;
  final String range;

  BmiCategory({
    required this.category,
    required this.description,
    required this.color,
    required this.range,
  });
}

/// BMI History Entry model
class BmiHistoryEntry {
  final double bmi;
  final double height;
  final double weight;
  final bool isMetric;
  final DateTime date;

  BmiHistoryEntry({
    required this.bmi,
    required this.height,
    required this.weight,
    required this.isMetric,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'bmi': bmi,
      'height': height,
      'weight': weight,
      'isMetric': isMetric,
      'date': date.toIso8601String(),
    };
  }

  factory BmiHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BmiHistoryEntry(
      bmi: json['bmi']?.toDouble() ?? 0.0,
      height: json['height']?.toDouble() ?? 0.0,
      weight: json['weight']?.toDouble() ?? 0.0,
      isMetric: json['isMetric'] ?? true,
      date: DateTime.parse(json['date']),
    );
  }
}