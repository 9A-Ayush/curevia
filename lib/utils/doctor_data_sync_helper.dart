import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Helper class for syncing and fixing doctor data issues
class DoctorDataSyncHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Sync missing name and email data for all doctors
  static Future<void> syncAllDoctorData() async {
    try {
      print('🔍 Starting doctor data sync...');
      
      final doctorsSnapshot = await _firestore.collection('doctors').get();
      int fixedCount = 0;
      int totalDoctors = doctorsSnapshot.docs.length;
      
      for (final doctorDoc in doctorsSnapshot.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;
        
        // Check if doctor is missing name or email
        final missingName = doctorData['fullName'] == null || doctorData['fullName'] == '';
        final missingEmail = doctorData['email'] == null || doctorData['email'] == '';
        
        if (missingName || missingEmail) {
          try {
            // Get data from user document
            final userDoc = await _firestore.collection('users').doc(doctorId).get();
            
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              final updateData = <String, dynamic>{};
              
              if (missingName && userData['fullName'] != null) {
                updateData['fullName'] = userData['fullName'];
                print('📝 Syncing name for doctor $doctorId: ${userData['fullName']}');
              }
              
              if (missingEmail && userData['email'] != null) {
                updateData['email'] = userData['email'];
                print('📧 Syncing email for doctor $doctorId: ${userData['email']}');
              }
              
              if (updateData.isNotEmpty) {
                updateData['updatedAt'] = FieldValue.serverTimestamp();
                
                await _firestore.collection('doctors').doc(doctorId).update(updateData);
                fixedCount++;
                print('✅ Fixed doctor data for $doctorId');
              }
            } else {
              print('⚠️ User document not found for doctor $doctorId');
            }
          } catch (e) {
            print('❌ Error syncing data for doctor $doctorId: $e');
          }
        }
      }
      
      print('📊 Doctor data sync complete:');
      print('   Total doctors: $totalDoctors');
      print('   Fixed doctors: $fixedCount');
      
    } catch (e) {
      print('❌ Error during doctor data sync: $e');
    }
  }

  /// Fix data for a specific doctor
  static Future<bool> syncDoctorData(String doctorId) async {
    try {
      print('🔍 Syncing data for doctor $doctorId...');
      
      // Get both documents
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      final userDoc = await _firestore.collection('users').doc(doctorId).get();
      
      if (!doctorDoc.exists) {
        print('❌ Doctor document not found for $doctorId');
        return false;
      }
      
      if (!userDoc.exists) {
        print('❌ User document not found for $doctorId');
        return false;
      }
      
      final doctorData = doctorDoc.data()!;
      final userData = userDoc.data()!;
      final updateData = <String, dynamic>{};
      
      // Check and sync name
      if (doctorData['fullName'] == null || doctorData['fullName'] == '') {
        if (userData['fullName'] != null) {
          updateData['fullName'] = userData['fullName'];
          print('📝 Syncing name: ${userData['fullName']}');
        }
      }
      
      // Check and sync email
      if (doctorData['email'] == null || doctorData['email'] == '') {
        if (userData['email'] != null) {
          updateData['email'] = userData['email'];
          print('📧 Syncing email: ${userData['email']}');
        }
      }
      
      // Check and sync phone number
      if (doctorData['phoneNumber'] == null || doctorData['phoneNumber'] == '') {
        if (userData['phoneNumber'] != null) {
          updateData['phoneNumber'] = userData['phoneNumber'];
          print('📱 Syncing phone: ${userData['phoneNumber']}');
        }
      }
      
      if (updateData.isNotEmpty) {
        updateData['updatedAt'] = FieldValue.serverTimestamp();
        
        await _firestore.collection('doctors').doc(doctorId).update(updateData);
        print('✅ Successfully synced data for doctor $doctorId');
        return true;
      } else {
        print('ℹ️ No data sync needed for doctor $doctorId');
        return true;
      }
      
    } catch (e) {
      print('❌ Error syncing doctor data: $e');
      return false;
    }
  }

  /// Validate doctor data integrity
  static Future<Map<String, dynamic>> validateDoctorData(String doctorId) async {
    try {
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      final userDoc = await _firestore.collection('users').doc(doctorId).get();
      
      final validation = <String, dynamic>{
        'doctorExists': doctorDoc.exists,
        'userExists': userDoc.exists,
        'issues': <String>[],
        'data': <String, dynamic>{},
      };
      
      if (!doctorDoc.exists) {
        validation['issues'].add('Doctor document missing');
        return validation;
      }
      
      if (!userDoc.exists) {
        validation['issues'].add('User document missing');
        return validation;
      }
      
      final doctorData = doctorDoc.data()!;
      final userData = userDoc.data()!;
      
      validation['data'] = {
        'doctor': doctorData,
        'user': userData,
      };
      
      // Check for missing required fields
      if (doctorData['fullName'] == null || doctorData['fullName'] == '') {
        validation['issues'].add('Missing fullName in doctor document');
      }
      
      if (doctorData['email'] == null || doctorData['email'] == '') {
        validation['issues'].add('Missing email in doctor document');
      }
      
      if (doctorData['phoneNumber'] == null || doctorData['phoneNumber'] == '') {
        validation['issues'].add('Missing phoneNumber in doctor document');
      }
      
      // Check for data consistency
      if (doctorData['fullName'] != userData['fullName']) {
        validation['issues'].add('Name mismatch between user and doctor documents');
      }
      
      if (doctorData['email'] != userData['email']) {
        validation['issues'].add('Email mismatch between user and doctor documents');
      }
      
      validation['isValid'] = (validation['issues'] as List).isEmpty;
      
      return validation;
      
    } catch (e) {
      return {
        'error': e.toString(),
        'isValid': false,
      };
    }
  }

  /// Get summary of all doctor data issues
  static Future<Map<String, dynamic>> getDoctorDataSummary() async {
    try {
      final doctorsSnapshot = await _firestore.collection('doctors').get();
      
      final summary = <String, dynamic>{
        'totalDoctors': doctorsSnapshot.docs.length,
        'missingName': 0,
        'missingEmail': 0,
        'missingPhone': 0,
        'complete': 0,
        'issues': <Map<String, dynamic>>[],
      };
      
      for (final doctorDoc in doctorsSnapshot.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;
        
        final hasName = doctorData['fullName'] != null && doctorData['fullName'] != '';
        final hasEmail = doctorData['email'] != null && doctorData['email'] != '';
        final hasPhone = doctorData['phoneNumber'] != null && doctorData['phoneNumber'] != '';
        
        if (!hasName) summary['missingName']++;
        if (!hasEmail) summary['missingEmail']++;
        if (!hasPhone) summary['missingPhone']++;
        
        if (hasName && hasEmail && hasPhone) {
          summary['complete']++;
        } else {
          final issues = <String>[];
          if (!hasName) issues.add('name');
          if (!hasEmail) issues.add('email');
          if (!hasPhone) issues.add('phone');
          
          summary['issues'].add({
            'doctorId': doctorId,
            'missing': issues,
          });
        }
      }
      
      return summary;
      
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }

  /// Initialize missing doctor documents for users with doctor role
  static Future<void> initializeMissingDoctorDocuments() async {
    try {
      print('🔍 Checking for users with doctor role but no doctor document...');
      
      // Get all users with doctor role
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();
      
      int createdCount = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userData = userDoc.data();
        
        // Check if doctor document exists
        final doctorDoc = await _firestore.collection('doctors').doc(userId).get();
        
        if (!doctorDoc.exists) {
          // Create doctor document
          await _firestore.collection('doctors').doc(userId).set({
            'uid': userId,
            'email': userData['email'],
            'fullName': userData['fullName'],
            'phoneNumber': userData['phoneNumber'],
            'role': 'doctor',
            'profileComplete': false,
            'onboardingCompleted': false,
            'onboardingStep': 0,
            'isActive': true,
            'isVerified': false,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          createdCount++;
          print('✅ Created doctor document for user $userId');
        }
      }
      
      print('📊 Missing doctor documents initialization complete:');
      print('   Total doctor users: ${usersSnapshot.docs.length}');
      print('   Created doctor documents: $createdCount');
      
    } catch (e) {
      print('❌ Error initializing missing doctor documents: $e');
    }
  }
}