import 'package:cloud_firestore/cloud_firestore.dart';
import 'validation_utils.dart';

/// Helper class for migrating and fixing phone number data
class PhoneNumberMigrationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and fix phone numbers in user documents
  static Future<void> checkAndFixUserPhoneNumbers() async {
    try {
      print('🔍 Checking user documents for phone number issues...');
      
      final usersSnapshot = await _firestore.collection('users').get();
      int fixedCount = 0;
      int totalUsers = usersSnapshot.docs.length;
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final phoneNumber = userData['phoneNumber'];
        
        if (phoneNumber != null && phoneNumber.toString().isNotEmpty) {
          final formattedPhone = ValidationUtils.formatPhoneNumber(phoneNumber.toString());
          
          // If the formatted phone is different from the original, update it
          if (formattedPhone != null && formattedPhone != phoneNumber.toString()) {
            await _firestore.collection('users').doc(userDoc.id).update({
              'phoneNumber': formattedPhone,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            print('✅ Fixed phone number for user ${userDoc.id}: $phoneNumber -> $formattedPhone');
            fixedCount++;
          }
        }
      }
      
      print('📊 Phone number check complete:');
      print('   Total users: $totalUsers');
      print('   Fixed phone numbers: $fixedCount');
    } catch (e) {
      print('❌ Error checking user phone numbers: $e');
    }
  }

  /// Check and fix phone numbers in doctor documents
  static Future<void> checkAndFixDoctorPhoneNumbers() async {
    try {
      print('🔍 Checking doctor documents for phone number issues...');
      
      final doctorsSnapshot = await _firestore.collection('doctors').get();
      int fixedCount = 0;
      int syncedCount = 0;
      int totalDoctors = doctorsSnapshot.docs.length;
      
      for (final doctorDoc in doctorsSnapshot.docs) {
        final doctorData = doctorDoc.data();
        final doctorId = doctorDoc.id;
        final phoneNumber = doctorData['phoneNumber'];
        
        // Check if doctor has phone number
        if (phoneNumber != null && phoneNumber.toString().isNotEmpty) {
          final formattedPhone = ValidationUtils.formatPhoneNumber(phoneNumber.toString());
          
          // If the formatted phone is different from the original, update it
          if (formattedPhone != null && formattedPhone != phoneNumber.toString()) {
            await _firestore.collection('doctors').doc(doctorId).update({
              'phoneNumber': formattedPhone,
              'updatedAt': FieldValue.serverTimestamp(),
            });
            
            print('✅ Fixed phone number for doctor $doctorId: $phoneNumber -> $formattedPhone');
            fixedCount++;
          }
        } else {
          // Doctor doesn't have phone number, try to sync from user document
          try {
            final userDoc = await _firestore.collection('users').doc(doctorId).get();
            if (userDoc.exists) {
              final userData = userDoc.data();
              final userPhoneNumber = userData?['phoneNumber'];
              
              if (userPhoneNumber != null && userPhoneNumber.toString().isNotEmpty) {
                final formattedPhone = ValidationUtils.formatPhoneNumber(userPhoneNumber.toString());
                
                if (formattedPhone != null) {
                  await _firestore.collection('doctors').doc(doctorId).update({
                    'phoneNumber': formattedPhone,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  print('🔄 Synced phone number for doctor $doctorId: $formattedPhone');
                  syncedCount++;
                }
              }
            }
          } catch (e) {
            print('⚠️ Error syncing phone number for doctor $doctorId: $e');
          }
        }
      }
      
      print('📊 Doctor phone number check complete:');
      print('   Total doctors: $totalDoctors');
      print('   Fixed phone numbers: $fixedCount');
      print('   Synced from user documents: $syncedCount');
    } catch (e) {
      print('❌ Error checking doctor phone numbers: $e');
    }
  }

  /// Run complete phone number migration
  static Future<void> runPhoneNumberMigration() async {
    print('🚀 Starting phone number migration...');
    
    await checkAndFixUserPhoneNumbers();
    await checkAndFixDoctorPhoneNumbers();
    
    print('✨ Phone number migration completed!');
  }

  /// Validate all phone numbers in the database
  static Future<void> validateAllPhoneNumbers() async {
    try {
      print('🔍 Validating all phone numbers in database...');
      
      // Check users
      final usersSnapshot = await _firestore.collection('users').get();
      int invalidUserPhones = 0;
      
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final phoneNumber = userData['phoneNumber'];
        
        if (phoneNumber != null && phoneNumber.toString().isNotEmpty) {
          final validationError = ValidationUtils.validatePhoneNumber(phoneNumber.toString());
          if (validationError != null) {
            print('❌ Invalid phone number in user ${userDoc.id}: $phoneNumber ($validationError)');
            invalidUserPhones++;
          }
        }
      }
      
      // Check doctors
      final doctorsSnapshot = await _firestore.collection('doctors').get();
      int invalidDoctorPhones = 0;
      
      for (final doctorDoc in doctorsSnapshot.docs) {
        final doctorData = doctorDoc.data();
        final phoneNumber = doctorData['phoneNumber'];
        
        if (phoneNumber != null && phoneNumber.toString().isNotEmpty) {
          final validationError = ValidationUtils.validatePhoneNumber(phoneNumber.toString());
          if (validationError != null) {
            print('❌ Invalid phone number in doctor ${doctorDoc.id}: $phoneNumber ($validationError)');
            invalidDoctorPhones++;
          }
        }
      }
      
      print('📊 Phone number validation complete:');
      print('   Invalid user phone numbers: $invalidUserPhones');
      print('   Invalid doctor phone numbers: $invalidDoctorPhones');
      
      if (invalidUserPhones == 0 && invalidDoctorPhones == 0) {
        print('🎉 All phone numbers are valid!');
      }
    } catch (e) {
      print('❌ Error validating phone numbers: $e');
    }
  }
}