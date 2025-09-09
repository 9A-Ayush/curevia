import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/family_member_provider.dart';
import '../../models/family_member_model.dart';
import '../../constants/app_colors.dart';
import 'add_family_member_screen.dart';

/// Family members management screen
class FamilyMembersScreen extends ConsumerStatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  ConsumerState<FamilyMembersScreen> createState() =>
      _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends ConsumerState<FamilyMembersScreen> {
  @override
  void initState() {
    super.initState();
    // Load family members after the widget is built to avoid provider modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFamilyMembers();
    });
  }

  void _loadFamilyMembers() {
    final user = ref.read(authProvider).userModel;
    if (user != null) {
      ref.read(familyMemberProvider.notifier).loadFamilyMembers(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyMemberState = ref.watch(familyMemberProvider);
    final familyMembers = familyMemberState.familyMembers;

    return Scaffold(
      backgroundColor: ThemeUtils.getPrimaryColor(context),
      appBar: AppBar(
        backgroundColor: ThemeUtils.getPrimaryColor(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ThemeUtils.getTextOnPrimaryColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Family Members',
          style: TextStyle(
            color: ThemeUtils.getTextOnPrimaryColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: ThemeUtils.getTextOnPrimaryColor(context),
            ),
            onPressed: _addFamilyMember,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: ThemeUtils.getBackgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: familyMemberState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : familyMemberState.error != null
            ? _buildErrorState(familyMemberState.error!)
            : familyMembers.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: () async => _loadFamilyMembers(),
                child: _buildFamilyList(familyMembers),
              ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error loading family members',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(text: 'Retry', onPressed: _loadFamilyMembers),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: ThemeUtils.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.family_restroom,
                size: 60,
                color: ThemeUtils.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Family Members Added',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add your family members to manage their health profiles and book appointments for them.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Add Family Member',
              onPressed: _addFamilyMember,
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyList(List<FamilyMemberModel> familyMembers) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: familyMembers.length,
            itemBuilder: (context, index) {
              final member = familyMembers[index];
              return _buildFamilyMemberCard(member);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: CustomButton(
            text: 'Add Family Member',
            onPressed: _addFamilyMember,
            icon: Icons.add,
            isOutlined: true,
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyMemberCard(FamilyMemberModel member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeUtils.getBorderLightColor(context)),
        boxShadow: [
          BoxShadow(
            color: ThemeUtils.getShadowLightColor(context),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _viewFamilyMember(member),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: ThemeUtils.getPrimaryColor(
                      context,
                    ).withValues(alpha: 0.1),
                    child: Icon(
                      _getFamilyMemberIcon(member.relationship),
                      size: 30,
                      color: ThemeUtils.getPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.relationship,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: ThemeUtils.getPrimaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        if (member.age != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            member.ageString,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ThemeUtils.getTextSecondaryColor(
                                    context,
                                  ),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value, member),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'medical',
                        child: Text('Medical Records'),
                      ),
                      const PopupMenuItem(
                        value: 'appointment',
                        child: Text('Book Appointment'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
              if (member.hasAllergies || member.hasMedicalConditions) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeUtils.getSurfaceVariantColor(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_information,
                        size: 16,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          member.medicalInfo,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ThemeUtils.getTextSecondaryColor(
                                  context,
                                ),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFamilyMemberIcon(String relationship) {
    switch (relationship.toLowerCase()) {
      case 'father':
      case 'dad':
        return Icons.man;
      case 'mother':
      case 'mom':
        return Icons.woman;
      case 'son':
        return Icons.boy;
      case 'daughter':
        return Icons.girl;
      case 'brother':
        return Icons.man;
      case 'sister':
        return Icons.woman;
      case 'husband':
        return Icons.man;
      case 'wife':
        return Icons.woman;
      case 'grandfather':
      case 'grandpa':
        return Icons.elderly;
      case 'grandmother':
      case 'grandma':
        return Icons.elderly;
      default:
        return Icons.person;
    }
  }

  void _addFamilyMember() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFamilyMemberScreen()),
    ).then((_) => _loadFamilyMembers());
  }

  void _viewFamilyMember(FamilyMemberModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFamilyMemberScreen(familyMember: member),
      ),
    ).then((_) => _loadFamilyMembers());
  }

  void _handleMenuAction(String action, FamilyMemberModel member) {
    switch (action) {
      case 'edit':
        _editFamilyMember(member);
        break;
      case 'medical':
        _viewMedicalRecords(member);
        break;
      case 'appointment':
        _bookAppointment(member);
        break;
      case 'delete':
        _deleteFamilyMember(member);
        break;
    }
  }

  void _editFamilyMember(FamilyMemberModel member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFamilyMemberScreen(familyMember: member),
      ),
    ).then((_) => _loadFamilyMembers());
  }

  void _viewMedicalRecords(FamilyMemberModel member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Medical records for ${member.name} - Coming soon!'),
      ),
    );
  }

  void _bookAppointment(FamilyMemberModel member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Book appointment for ${member.name} - Coming soon!'),
      ),
    );
  }

  void _deleteFamilyMember(FamilyMemberModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family Member'),
        content: Text(
          'Are you sure you want to remove ${member.name} from your family members?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final user = ref.read(authProvider).userModel;
              if (user != null) {
                ref
                    .read(familyMemberProvider.notifier)
                    .deleteFamilyMember(user.uid, member.id);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${member.name} removed from family members'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
