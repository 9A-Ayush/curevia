import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _selectedRole = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with filters
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context),
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            border: Border(
              bottom: BorderSide(
                color: ThemeUtils.getBorderLightColor(context),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Horizontally scrollable role filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Patients', 'patient'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Doctors', 'doctor'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Admins', 'admin'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Users list
        Expanded(
          child: _buildUsersList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRole == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedRole = value);
      },
      selectedColor: ThemeUtils.getPrimaryColor(context).withOpacity(0.2),
      backgroundColor: ThemeUtils.getSurfaceVariantColor(context),
      labelStyle: TextStyle(
        color: isSelected 
            ? ThemeUtils.getPrimaryColor(context) 
            : ThemeUtils.getTextPrimaryColor(context),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? ThemeUtils.getPrimaryColor(context) 
            : ThemeUtils.getBorderLightColor(context),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _selectedRole == 'all'
          ? FirebaseFirestore.instance
              .collection('users')
              .orderBy('createdAt', descending: true)
              .snapshots()
          : FirebaseFirestore.instance
              .collection('users')
              .where('role', isEqualTo: _selectedRole)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading users',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data!.docs;

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['fullName'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || email.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'No users found'
                      : 'No ${_selectedRole == 'all' ? '' : _selectedRole} users',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final isMobile = MediaQuery.of(context).size.width < 600;

        return ListView.builder(
          padding: ResponsiveUtils.getResponsivePadding(context),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildUserCard(docs[index].id, data, isMobile);
          },
        );
      },
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> data, bool isMobile) {
    final role = data['role'] ?? 'patient';
    final isActive = data['isActive'] ?? true;
    final isVerified = data['isVerified'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: ThemeUtils.getSurfaceColor(context),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showUserDetails(userId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile
              ? _buildMobileUserCard(userId, data, role, isActive, isVerified)
              : _buildDesktopUserCard(userId, data, role, isActive, isVerified),
        ),
      ),
    );
  }

  Widget _buildMobileUserCard(
    String userId,
    Map<String, dynamic> data,
    String role,
    bool isActive,
    bool isVerified,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getRoleColor(role).withOpacity(0.2),
              child: Icon(
                _getRoleIcon(role),
                color: _getRoleColor(role),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['fullName'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    data['email'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildBadge(role.toUpperCase(), _getRoleColor(role)),
            if (isVerified) _buildBadge('VERIFIED', AppColors.success),
            _buildBadge(isActive ? 'ACTIVE' : 'INACTIVE', isActive ? AppColors.info : AppColors.error),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () => _showUserDetails(userId, data),
              icon: const Icon(Icons.visibility, size: 18),
              label: const Text('View'),
            ),
            TextButton.icon(
              onPressed: () => _toggleUserStatus(userId, isActive),
              icon: Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
              label: Text(isActive ? 'Deactivate' : 'Activate'),
              style: TextButton.styleFrom(
                foregroundColor: isActive ? AppColors.error : AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopUserCard(
    String userId,
    Map<String, dynamic> data,
    String role,
    bool isActive,
    bool isVerified,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _getRoleColor(role).withOpacity(0.2),
          child: Icon(
            _getRoleIcon(role),
            color: _getRoleColor(role),
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['fullName'] ?? 'Unknown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                data['email'] ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadge(role.toUpperCase(), _getRoleColor(role)),
              if (isVerified) _buildBadge('VERIFIED', AppColors.success),
              _buildBadge(isActive ? 'ACTIVE' : 'INACTIVE', isActive ? AppColors.info : AppColors.error),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showUserDetails(userId, data),
              icon: const Icon(Icons.visibility),
              tooltip: 'View Details',
            ),
            IconButton(
              onPressed: () => _toggleUserStatus(userId, isActive),
              icon: Icon(isActive ? Icons.block : Icons.check_circle),
              tooltip: isActive ? 'Deactivate' : 'Activate',
              color: isActive ? AppColors.error : AppColors.success,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'doctor':
        return AppColors.primary;
      case 'patient':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'doctor':
        return Icons.medical_services;
      case 'patient':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  Future<void> _showUserDetails(String userId, Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['fullName'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', data['email'] ?? 'N/A'),
              _buildDetailRow('Role', data['role'] ?? 'N/A'),
              _buildDetailRow('Phone', data['phoneNumber'] ?? 'N/A'),
              _buildDetailRow('Active', (data['isActive'] ?? true) ? 'Yes' : 'No'),
              _buildDetailRow('Verified', (data['isVerified'] ?? false) ? 'Yes' : 'No'),
              _buildDetailRow('User ID', userId),
              if (data['createdAt'] != null)
                _buildDetailRow(
                  'Joined',
                  (data['createdAt'] as Timestamp).toDate().toString().split('.')[0],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: ThemeUtils.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(String userId, bool currentStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? 'Deactivate User' : 'Activate User'),
        content: Text(
          currentStatus
              ? 'Are you sure you want to deactivate this user? They will not be able to login.'
              : 'Are you sure you want to activate this user?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: currentStatus ? AppColors.error : AppColors.success,
            ),
            child: Text(currentStatus ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentStatus ? 'User deactivated successfully' : 'User activated successfully',
            ),
            backgroundColor: currentStatus ? AppColors.error : AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
