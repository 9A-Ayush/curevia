import 'package:flutter/foundation.dart';

/// Helper class for managing Firestore indexes and providing helpful error messages
class FirestoreIndexHelper {
  /// Map of common Firestore index errors and their solutions
  static const Map<String, String> _indexSolutions = {
    'medical_documents': '''
Medical Documents Index Required:
- Collection: medical_documents
- Fields: patientId (ASC), status (ASC), uploadedAt (DESC)
- Use: Querying patient documents by status and date
''',
    'patient_allergies': '''
Patient Allergies Index Required:
- Collection: patient_allergies  
- Fields: patientId (ASC), isActive (ASC), severity (DESC), createdAt (DESC)
- Use: Querying active allergies by severity
''',
    'patient_medications': '''
Patient Medications Index Required:
- Collection: patient_medications
- Fields: patientId (ASC), isActive (ASC), startDate (DESC)
- Use: Querying active medications by start date
''',
    'patient_vitals': '''
Patient Vitals Index Required:
- Collection: patient_vitals
- Fields: patientId (ASC), recordedAt (DESC)
- Use: Querying patient vitals by date
''',
    'doctor_access_logs': '''
Doctor Access Logs Index Required:
- Collection: doctor_access_logs
- Fields: doctorId (ASC), patientId (ASC), accessTime (DESC)
- Use: Querying doctor access history
''',
  };

  /// Extract collection name from Firestore error message
  static String? _extractCollectionFromError(String errorMessage) {
    final regex = RegExp(r'collectionGroups/([^/]+)/');
    final match = regex.firstMatch(errorMessage);
    return match?.group(1);
  }

  /// Get helpful solution for index error
  static String getIndexSolution(String errorMessage) {
    final collection = _extractCollectionFromError(errorMessage);
    
    if (collection != null && _indexSolutions.containsKey(collection)) {
      return _indexSolutions[collection]!;
    }
    
    return '''
Firestore Index Required:
1. Copy the index creation URL from the error message
2. Open the URL in your browser
3. Click "Create Index" in Firebase Console
4. Wait for index to build (usually 1-5 minutes)
5. Retry your query

Collection: ${collection ?? 'Unknown'}
''';
  }

  /// Log index error with helpful information
  static void logIndexError(String errorMessage, {String? context}) {
    if (kDebugMode) {
      print('🔥 FIRESTORE INDEX ERROR 🔥');
      if (context != null) {
        print('Context: $context');
      }
      print('Error: $errorMessage');
      print('');
      print('SOLUTION:');
      print(getIndexSolution(errorMessage));
      print('');
      print('📋 Quick Fix:');
      print('1. Copy the URL from the error above');
      print('2. Open it in your browser');
      print('3. Click "Create Index"');
      print('4. Wait for completion');
      print('');
    }
  }

  /// Check if error is a Firestore index error
  static bool isIndexError(dynamic error) {
    if (error == null) return false;
    final errorString = error.toString().toLowerCase();
    return errorString.contains('failed-precondition') && 
           errorString.contains('requires an index');
  }

  /// Handle Firestore query with automatic index error logging
  static Future<T> handleQuery<T>(
    Future<T> Function() queryFunction, {
    String? context,
    T? fallbackValue,
  }) async {
    try {
      return await queryFunction();
    } catch (error) {
      if (isIndexError(error)) {
        logIndexError(error.toString(), context: context);
      }
      
      if (fallbackValue != null) {
        return fallbackValue;
      }
      
      rethrow;
    }
  }

  /// Handle Firestore stream with automatic index error logging
  static Stream<T> handleStream<T>(
    Stream<T> Function() streamFunction, {
    String? context,
    T? fallbackValue,
  }) {
    try {
      return streamFunction().handleError((error) {
        if (isIndexError(error)) {
          logIndexError(error.toString(), context: context);
        }
        
        if (fallbackValue != null) {
          // Return fallback value as single item stream
          return Stream.value(fallbackValue);
        }
        
        throw error;
      });
    } catch (error) {
      if (isIndexError(error)) {
        logIndexError(error.toString(), context: context);
      }
      
      if (fallbackValue != null) {
        return Stream.value(fallbackValue);
      }
      
      rethrow;
    }
  }

  /// Get all required indexes for the medical app
  static List<Map<String, dynamic>> getRequiredIndexes() {
    return [
      {
        'collection': 'medical_documents',
        'fields': [
          {'field': 'patientId', 'order': 'ASC'},
          {'field': 'status', 'order': 'ASC'},
          {'field': 'uploadedAt', 'order': 'DESC'},
        ],
        'description': 'Query patient medical documents by status and date'
      },
      {
        'collection': 'patient_allergies',
        'fields': [
          {'field': 'patientId', 'order': 'ASC'},
          {'field': 'isActive', 'order': 'ASC'},
          {'field': 'severity', 'order': 'DESC'},
          {'field': 'createdAt', 'order': 'DESC'},
        ],
        'description': 'Query active patient allergies by severity'
      },
      {
        'collection': 'patient_medications',
        'fields': [
          {'field': 'patientId', 'order': 'ASC'},
          {'field': 'isActive', 'order': 'ASC'},
          {'field': 'startDate', 'order': 'DESC'},
        ],
        'description': 'Query active patient medications by start date'
      },
      {
        'collection': 'patient_vitals',
        'fields': [
          {'field': 'patientId', 'order': 'ASC'},
          {'field': 'recordedAt', 'order': 'DESC'},
        ],
        'description': 'Query patient vital signs by date'
      },
      {
        'collection': 'doctor_access_logs',
        'fields': [
          {'field': 'doctorId', 'order': 'ASC'},
          {'field': 'patientId', 'order': 'ASC'},
          {'field': 'accessTime', 'order': 'DESC'},
        ],
        'description': 'Query doctor access logs for audit trail'
      },
    ];
  }

  /// Generate firestore.indexes.json content
  static String generateIndexesJson() {
    final indexes = getRequiredIndexes();
    final indexesJson = indexes.map((index) => {
      'collectionGroup': index['collection'],
      'queryScope': 'COLLECTION',
      'fields': (index['fields'] as List).map((field) => {
        'fieldPath': field['field'],
        'order': field['order'] == 'ASC' ? 'ASCENDING' : 'DESCENDING',
      }).toList(),
    }).toList();

    return '''
{
  "indexes": ${_prettyPrintJson(indexesJson)},
  "fieldOverrides": []
}
''';
  }

  /// Pretty print JSON for better readability
  static String _prettyPrintJson(dynamic json) {
    // Simple JSON formatting - in production you might want to use a proper JSON formatter
    return json.toString().replaceAll('{', '{\n    ').replaceAll('}', '\n  }');
  }

  /// Validate that all required indexes exist (for development)
  static Future<List<String>> validateIndexes() async {
    final missingIndexes = <String>[];
    
    // This would need to be implemented with actual Firestore admin SDK
    // For now, just return empty list
    
    return missingIndexes;
  }

  /// Create deployment script for indexes
  static String generateDeploymentScript() {
    return '''
#!/bin/bash
# Firestore Index Deployment Script

echo "🔥 Deploying Firestore Indexes..."

# Deploy indexes
firebase deploy --only firestore:indexes

echo "✅ Firestore indexes deployed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Wait for indexes to build (check Firebase Console)"
echo "2. Test your queries"
echo "3. Monitor index usage in Firebase Console"
''';
  }
}

/// Extension to add index error handling to common Firestore operations
extension FirestoreQueryExtension on Future {
  /// Add automatic index error handling to any Future
  Future<T> withIndexErrorHandling<T>({
    String? context,
    T? fallbackValue,
  }) {
    return FirestoreIndexHelper.handleQuery<T>(
      () => this as Future<T>,
      context: context,
      fallbackValue: fallbackValue,
    );
  }
}

/// Extension to add index error handling to Firestore streams
extension FirestoreStreamExtension<T> on Stream<T> {
  /// Add automatic index error handling to any Stream
  Stream<T> withIndexErrorHandling({
    String? context,
    T? fallbackValue,
  }) {
    return FirestoreIndexHelper.handleStream<T>(
      () => this,
      context: context,
      fallbackValue: fallbackValue,
    );
  }
}