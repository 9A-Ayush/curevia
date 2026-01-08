import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/app_colors.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/admin/expandable_verification_card.dart';
import '../../services/email_service.dart';
import 'doctor_verification_details_screen.dart';

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
          decoration: BoxDecoration(
            color: ThemeUtils.getSurfaceColor(context),
            border: Border(
              bottom: BorderSide(
                color: ThemeUtils.getBorderLightColor(context),
              ),
            ),
          ),
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
                        'Error: ${snapshot.error}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ThemeUtils.getTextPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: ThemeUtils.getPrimaryColor(context),
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No $_filter verifications',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: ThemeUtils.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return ExpandableVerificationCard(
                    verificationId: docs[index].id,
                    verificationData: data,
                    onApprove: () => _approveVerification(docs[index].id, data['doctorId']),
                    onReject: () => _rejectVerification(docs[index].id, data['doctorId']),
                    onViewDetails: () => _viewDoctorDetails(docs[index].id, data['doctorId']),
                  );
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
      
      // Send approval email
      try {
        await EmailService.sendDoctorVerificationEmail(
          doctorId: doctorId,
          status: 'approved',
          adminId: 'admin', // Replace with actual admin ID
        );
        debugPrint('✅ Doctor approval email sent successfully');
      } catch (emailError) {
        debugPrint('⚠️ Failed to send approval email: $emailError');
        // Don't fail the verification process if email fails
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Doctor verified successfully'),
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

  Future<void> _rejectVerification(String verificationId, String doctorId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          backgroundColor: ThemeUtils.getSurfaceColor(context),
          title: Text(
            'Reject Verification',
            style: TextStyle(color: ThemeUtils.getTextPrimaryColor(context)),
          ),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
      
      // Send rejection email
      try {
        await EmailService.sendDoctorVerificationEmail(
          doctorId: doctorId,
          status: 'rejected',
          adminId: 'admin', // Replace with actual admin ID
        );
        debugPrint('✅ Doctor rejection email sent successfully');
      } catch (emailError) {
        debugPrint('⚠️ Failed to send rejection email: $emailError');
        // Don't fail the verification process if email fails
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verification rejected'),
            backgroundColor: AppColors.error,
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

  void _viewDoctorDetails(String verificationId, String doctorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DoctorVerificationDetailsScreen(
          verificationId: verificationId,
          doctorId: doctorId,
        ),
      ),
    );
  }
}
