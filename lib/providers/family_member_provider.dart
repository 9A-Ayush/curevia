import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_member_model.dart';
import '../services/firebase/family_member_service.dart';

/// Family member state
class FamilyMemberState {
  final List<FamilyMemberModel> familyMembers;
  final bool isLoading;
  final String? error;

  const FamilyMemberState({
    this.familyMembers = const [],
    this.isLoading = false,
    this.error,
  });

  FamilyMemberState copyWith({
    List<FamilyMemberModel>? familyMembers,
    bool? isLoading,
    String? error,
  }) {
    return FamilyMemberState(
      familyMembers: familyMembers ?? this.familyMembers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Family member provider notifier
class FamilyMemberNotifier extends StateNotifier<FamilyMemberState> {
  FamilyMemberNotifier() : super(const FamilyMemberState());

  /// Load family members for user
  Future<void> loadFamilyMembers(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final familyMembers = await FamilyMemberService.getFamilyMembers(userId);

      state = state.copyWith(
        isLoading: false,
        familyMembers: familyMembers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Add family member
  Future<String?> addFamilyMember({
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
      state = state.copyWith(isLoading: true, error: null);

      final memberId = await FamilyMemberService.addFamilyMember(
        userId: userId,
        name: name,
        relationship: relationship,
        phoneNumber: phoneNumber,
        email: email,
        dateOfBirth: dateOfBirth,
        bloodGroup: bloodGroup,
        gender: gender,
        allergies: allergies,
        medicalConditions: medicalConditions,
        emergencyContact: emergencyContact,
        notes: notes,
      );

      // Reload family members to get the updated list
      await loadFamilyMembers(userId);

      return memberId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update family member
  Future<bool> updateFamilyMember({
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
      state = state.copyWith(isLoading: true, error: null);

      await FamilyMemberService.updateFamilyMember(
        userId: userId,
        memberId: memberId,
        name: name,
        relationship: relationship,
        phoneNumber: phoneNumber,
        email: email,
        dateOfBirth: dateOfBirth,
        bloodGroup: bloodGroup,
        gender: gender,
        allergies: allergies,
        medicalConditions: medicalConditions,
        emergencyContact: emergencyContact,
        notes: notes,
      );

      // Reload family members to get the updated list
      await loadFamilyMembers(userId);

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Delete family member
  Future<bool> deleteFamilyMember(String userId, String memberId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await FamilyMemberService.deleteFamilyMember(userId, memberId);

      // Update local state by removing the deleted member
      final updatedMembers = state.familyMembers
          .where((member) => member.id != memberId)
          .toList();

      state = state.copyWith(
        isLoading: false,
        familyMembers: updatedMembers,
      );

      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Get family member by ID
  FamilyMemberModel? getFamilyMemberById(String memberId) {
    try {
      return state.familyMembers.firstWhere((member) => member.id == memberId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Add family member to local state (for real-time updates)
  void addFamilyMemberToState(FamilyMemberModel member) {
    final updatedMembers = [...state.familyMembers, member];
    state = state.copyWith(familyMembers: updatedMembers);
  }

  /// Update family member in local state (for real-time updates)
  void updateFamilyMemberInState(FamilyMemberModel updatedMember) {
    final updatedMembers = state.familyMembers.map((member) {
      return member.id == updatedMember.id ? updatedMember : member;
    }).toList();
    state = state.copyWith(familyMembers: updatedMembers);
  }
}

/// Family member provider
final familyMemberProvider = StateNotifierProvider<FamilyMemberNotifier, FamilyMemberState>((ref) {
  return FamilyMemberNotifier();
});

/// Family member count provider
final familyMemberCountProvider = Provider<int>((ref) {
  return ref.watch(familyMemberProvider).familyMembers.length;
});

/// Family members by relationship provider
final familyMembersByRelationshipProvider = Provider.family<List<FamilyMemberModel>, String>((ref, relationship) {
  final familyMembers = ref.watch(familyMemberProvider).familyMembers;
  return familyMembers.where((member) => member.relationship.toLowerCase() == relationship.toLowerCase()).toList();
});
