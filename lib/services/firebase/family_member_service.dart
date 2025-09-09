import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_constants.dart';
import '../../models/family_member_model.dart';

/// Service for managing family members
class FamilyMemberService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get family members for a user
  static Future<List<FamilyMemberModel>> getFamilyMembers(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('family_members')
          .orderBy('createdAt', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => FamilyMemberModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family members: $e');
    }
  }

  /// Add family member
  static Future<String> addFamilyMember({
    required String userId,
    required String name,
    required String relationship,
    String? phoneNumber,
    String? email,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? gender,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? emergencyContact,
    String? notes,
  }) async {
    try {
      final docRef = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('family_members')
          .add({
        'name': name,
        'relationship': relationship,
        'phoneNumber': phoneNumber,
        'email': email,
        'dateOfBirth': dateOfBirth != null 
            ? Timestamp.fromDate(dateOfBirth) 
            : null,
        'bloodGroup': bloodGroup,
        'gender': gender,
        'allergies': allergies ?? [],
        'medicalConditions': medicalConditions ?? [],
        'emergencyContact': emergencyContact,
        'notes': notes,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add family member: $e');
    }
  }

  /// Update family member
  static Future<void> updateFamilyMember({
    required String userId,
    required String memberId,
    String? name,
    String? relationship,
    String? phoneNumber,
    String? email,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? gender,
    List<String>? allergies,
    List<String>? medicalConditions,
    String? emergencyContact,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (name != null) updateData['name'] = name;
      if (relationship != null) updateData['relationship'] = relationship;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (email != null) updateData['email'] = email;
      if (dateOfBirth != null) {
        updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }
      if (bloodGroup != null) updateData['bloodGroup'] = bloodGroup;
      if (gender != null) updateData['gender'] = gender;
      if (allergies != null) updateData['allergies'] = allergies;
      if (medicalConditions != null) {
        updateData['medicalConditions'] = medicalConditions;
      }
      if (emergencyContact != null) updateData['emergencyContact'] = emergencyContact;
      if (notes != null) updateData['notes'] = notes;

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('family_members')
          .doc(memberId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update family member: $e');
    }
  }

  /// Delete family member
  static Future<void> deleteFamilyMember(String userId, String memberId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('family_members')
          .doc(memberId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete family member: $e');
    }
  }

  /// Get family member by ID
  static Future<FamilyMemberModel?> getFamilyMemberById(
    String userId, 
    String memberId,
  ) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('family_members')
          .doc(memberId)
          .get();

      if (!doc.exists) return null;

      return FamilyMemberModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to get family member: $e');
    }
  }

  /// Get family members stream for real-time updates
  static Stream<List<FamilyMemberModel>> getFamilyMembersStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .collection('family_members')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FamilyMemberModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Get family member count
  static Future<int> getFamilyMemberCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('family_members')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get family member count: $e');
    }
  }
}
