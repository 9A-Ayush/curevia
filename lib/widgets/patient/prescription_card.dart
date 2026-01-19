import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/prescription_model.dart';
import '../../utils/theme_utils.dart';

/// Reusable prescription card widget
class PrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback? onTap;
  final bool showStatus;

  const PrescriptionCard({
    super.key,
    required this.prescription,
    this.onTap,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = _isActive();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${prescription.doctorName}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.doctorSpecialty,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          prescription.formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ThemeUtils.getTextSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showStatus)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive 
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.textSecondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Completed',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isActive ? AppColors.success : AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${prescription.medicineCount} medicines',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              if (prescription.diagnosis != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.medical_information_outlined,
                      size: 16,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Diagnosis: ${prescription.diagnosis!}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Medicines preview
              if (prescription.medicines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 16,
                      color: ThemeUtils.getTextSecondaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Medicines: ${prescription.medicines.take(2).map((m) => m.medicineName).join(', ')}${prescription.medicines.length > 2 ? '...' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              // Follow-up indicator
              if (prescription.hasFollowUp) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Follow-up: ${prescription.formattedFollowUpDate ?? 'As advised'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isActive() {
    final now = DateTime.now();
    return prescription.medicines.any((medicine) {
      final endDate = prescription.prescriptionDate.add(Duration(days: medicine.duration));
      return endDate.isAfter(now);
    });
  }
}

/// Compact prescription card for lists
class CompactPrescriptionCard extends StatelessWidget {
  final PrescriptionModel prescription;
  final VoidCallback? onTap;

  const CompactPrescriptionCard({
    super.key,
    required this.prescription,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${prescription.doctorName}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${prescription.medicineCount} medicines • ${prescription.formattedDate}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ThemeUtils.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: ThemeUtils.getTextSecondaryColor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Medicine item widget for prescription details
class MedicineItem extends StatelessWidget {
  final PrescribedMedicine medicine;
  final bool showStatus;

  const MedicineItem({
    super.key,
    required this.medicine,
    this.showStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startDate = DateTime.now(); // Assuming prescription date as start
    final endDate = startDate.add(Duration(days: medicine.duration));
    final isActive = endDate.isAfter(now);
    final daysRemaining = endDate.difference(now).inDays;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeUtils.getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: showStatus && isActive 
              ? AppColors.success.withValues(alpha: 0.3)
              : ThemeUtils.getTextSecondaryColor(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  medicine.fullName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (showStatus)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Completed',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive ? AppColors.success : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            medicine.completeInstruction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (showStatus && isActive && daysRemaining > 0) ...[
            const SizedBox(height: 4),
            Text(
              '$daysRemaining days remaining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (medicine.instructions != null) ...[
            const SizedBox(height: 4),
            Text(
              medicine.instructions!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ThemeUtils.getTextSecondaryColor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}