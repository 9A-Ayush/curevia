import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';

class DoctorVerificationScreen extends StatefulWidget {
  const DoctorVerificationScreen({super.key});

  @override
  State<DoctorVerificationScreen> createState() => _DoctorVerificationScreenState();
}

class _DoctorVerificationScreenState extends State<DoctorVerificationScreen> {
  String _filter = 'pending';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter tabs
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildFilterChip('Pending', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Verified', 'verified'),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', 'rejected'),
            ],
          ),
        ),
        
        // List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('doctor_verifications')
                .where('status', isEqualTo: _filter)
                .orderBy('submittedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Text('No $_filter verifications'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildVerificationCard(docs[index].id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
      selectedColor: AppColors.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildVerificationCard(String id, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text('Doctor ID: ${data['doctorId']}'),
        subtitle: Text('Submitted: ${(data['submittedAt'] as Timestamp).toDate()}'),
        trailing: _filter == 'pending'
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => _approveVerification(id, data['doctorId']),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => _rejectVerification(id, data['doctorId']),
                  ),
                ],
              )
            : null,
        onTap: () => _viewDoctorDetails(data['doctorId']),
      ),
    );
  }

  Future<void> _approveVerification(String verificationId, String doctorId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      batch.update(
        FirebaseFirestore.instance.collection('doctor_verifications').doc(verificationId),
        {
          'status': 'verified',
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );
      
      batch.update(
        FirebaseFirestore.instance.collection('doctors').doc(doctorId),
        {
          'verificationStatus': 'verified',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor verified successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _rejectVerification(String verificationId, String doctorId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Verification'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Enter reason...',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      batch.update(
        FirebaseFirestore.instance.collection('doctor_verifications').doc(verificationId),
        {
          'status': 'rejected',
          'reason': reason,
          'reviewedAt': FieldValue.serverTimestamp(),
        },
      );
      
      batch.update(
        FirebaseFirestore.instance.collection('doctors').doc(doctorId),
        {
          'verificationStatus': 'rejected',
          'verificationReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _viewDoctorDetails(String doctorId) {
    // TODO: Navigate to doctor details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View doctor: $doctorId')),
    );
  }
}
