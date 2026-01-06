import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';

class AppointmentsManagementScreen extends StatefulWidget {
  const AppointmentsManagementScreen({super.key});

  @override
  State<AppointmentsManagementScreen> createState() => _AppointmentsManagementScreenState();
}

class _AppointmentsManagementScreenState extends State<AppointmentsManagementScreen> {
  String _selectedStatus = 'all';
  DateTime? _selectedDate;
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
                    hintText: 'Search patient or doctor...',
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
              
              // Horizontally scrollable filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending', 'pending'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Confirmed', 'confirmed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'completed'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Cancelled', 'cancelled'),
                    const SizedBox(width: 8),
                    
                    OutlinedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _selectedDate == null
                            ? 'Filter by Date'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    
                    if (_selectedDate != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => setState(() => _selectedDate = null),
                        icon: const Icon(Icons.clear, size: 18),
                        tooltip: 'Clear date filter',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _buildAppointmentsList(),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedStatus = value);
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildAppointmentsList() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('appointments')
        .orderBy('appointmentDate', descending: true);

    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading appointments', style: Theme.of(context).textTheme.titleMedium),
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

        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final patientName = (data['patientName'] ?? '').toString().toLowerCase();
            final doctorName = (data['doctorName'] ?? '').toString().toLowerCase();
            return patientName.contains(_searchQuery) || doctorName.contains(_searchQuery);
          }).toList();
        }

        if (_selectedDate != null) {
          docs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['appointmentDate'] == null) return false;
            final appointmentDate = (data['appointmentDate'] as Timestamp).toDate();
            return appointmentDate.year == _selectedDate!.year &&
                appointmentDate.month == _selectedDate!.month &&
                appointmentDate.day == _selectedDate!.day;
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 64,
                  color: ThemeUtils.getTextSecondaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'No appointments found',
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
            return _buildAppointmentCard(docs[index].id, data, isMobile);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(String appointmentId, Map<String, dynamic> data, bool isMobile) {
    final status = data['status'] ?? 'pending';
    final appointmentDate = data['appointmentDate'] != null
        ? (data['appointmentDate'] as Timestamp).toDate()
        : null;

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
        onTap: () => _showAppointmentDetails(appointmentId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isMobile
              ? _buildMobileAppointmentCard(appointmentId, data, status, appointmentDate)
              : _buildDesktopAppointmentCard(appointmentId, data, status, appointmentDate),
        ),
      ),
    );
  }

  Widget _buildMobileAppointmentCard(
    String appointmentId,
    Map<String, dynamic> data,
    String status,
    DateTime? appointmentDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_month,
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['patientName'] ?? 'Unknown Patient',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'Dr. ${data['doctorName'] ?? 'Unknown'}',
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
        
        if (appointmentDate != null) ...[
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 16,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMM dd, yyyy - hh:mm a').format(appointmentDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        
        Row(
          children: [
            Icon(
              Icons.medical_services,
              size: 16,
              color: ThemeUtils.getTextSecondaryColor(context),
            ),
            const SizedBox(width: 8),
            Text(
              data['consultationType'] ?? 'N/A',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            _buildStatusBadge(status),
          ],
        ),
        
        if (status == 'pending' || status == 'confirmed') ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showAppointmentDetails(appointmentId, data),
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View'),
              ),
              TextButton.icon(
                onPressed: () => _cancelAppointment(appointmentId),
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopAppointmentCard(
    String appointmentId,
    Map<String, dynamic> data,
    String status,
    DateTime? appointmentDate,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getStatusColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.calendar_month,
            color: _getStatusColor(status),
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['patientName'] ?? 'Unknown Patient',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dr. ${data['doctorName'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
              ),
            ],
          ),
        ),
        
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (appointmentDate != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(appointmentDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('hh:mm a').format(appointmentDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['consultationType'] ?? 'N/A',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(status),
            ],
          ),
        ),
        
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showAppointmentDetails(appointmentId, data),
              icon: const Icon(Icons.visibility),
              tooltip: 'View Details',
            ),
            if (status == 'pending' || status == 'confirmed')
              IconButton(
                onPressed: () => _cancelAppointment(appointmentId),
                icon: const Icon(Icons.cancel),
                tooltip: 'Cancel Appointment',
                color: AppColors.error,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _showAppointmentDetails(String appointmentId, Map<String, dynamic> data) async {
    final appointmentDate = data['appointmentDate'] != null
        ? (data['appointmentDate'] as Timestamp).toDate()
        : null;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appointment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Patient', data['patientName'] ?? 'N/A'),
              _buildDetailRow('Doctor', 'Dr. ${data['doctorName'] ?? 'N/A'}'),
              _buildDetailRow('Specialty', data['doctorSpecialty'] ?? 'N/A'),
              if (appointmentDate != null)
                _buildDetailRow(
                  'Date & Time',
                  DateFormat('MMM dd, yyyy - hh:mm a').format(appointmentDate),
                ),
              _buildDetailRow('Type', data['consultationType'] ?? 'N/A'),
              _buildDetailRow('Status', data['status'] ?? 'N/A'),
              _buildDetailRow('Fee', '₹${data['consultationFee'] ?? 0}'),
              if (data['symptoms'] != null)
                _buildDetailRow('Symptoms', data['symptoms']),
              if (data['notes'] != null)
                _buildDetailRow('Notes', data['notes']),
              _buildDetailRow('Appointment ID', appointmentId),
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

  Future<void> _cancelAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('appointments').doc(appointmentId).update({
        'status': 'cancelled',
        'cancelledBy': 'admin',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully'),
            backgroundColor: AppColors.success,
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
