import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/doctor_provider.dart';
import '../../utils/theme_utils.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

/// Doctor filters bottom sheet
class DoctorFilters extends ConsumerStatefulWidget {
  final DoctorSearchFilters currentFilters;
  final Function(DoctorSearchFilters) onApplyFilters;

  const DoctorFilters({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  ConsumerState<DoctorFilters> createState() => _DoctorFiltersState();
}

class _DoctorFiltersState extends ConsumerState<DoctorFilters> {
  late DoctorSearchFilters _filters;
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _maxFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _cityController.text = _filters.city ?? '';
    _maxFeeController.text = _filters.maxFee?.toString() ?? '';
  }

  @override
  void dispose() {
    _cityController.dispose();
    _maxFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: ThemeUtils.getBorderMediumColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: ThemeUtils.getTextPrimaryColor(context),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          // Filters Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Specialty Filter
                  _buildSectionTitle('Specialty'),
                  _buildSpecialtyFilter(),

                  const SizedBox(height: 24),

                  // Consultation Type Filter
                  _buildSectionTitle('Consultation Type'),
                  _buildConsultationTypeFilter(),

                  const SizedBox(height: 24),

                  // Rating Filter
                  _buildSectionTitle('Minimum Rating'),
                  _buildRatingFilter(),

                  const SizedBox(height: 24),

                  // Location Filter
                  _buildSectionTitle('Location'),
                  CustomTextField(
                    controller: _cityController,
                    label: 'City',
                    hintText: 'Enter city name',
                    prefixIcon: Icons.location_city,
                    onChanged: (value) {
                      _filters = _filters.copyWith(
                        city: value.isEmpty ? null : value,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Fee Filter
                  _buildSectionTitle('Maximum Fee'),
                  CustomTextField(
                    controller: _maxFeeController,
                    label: 'Maximum Consultation Fee',
                    hintText: 'Enter maximum fee',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      final fee = double.tryParse(value);
                      _filters = _filters.copyWith(maxFee: fee);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Availability Filter
                  _buildSectionTitle('Availability'),
                  CheckboxListTile(
                    title: const Text('Available Now'),
                    value: _filters.isAvailable ?? false,
                    onChanged: (value) {
                      setState(() {
                        _filters = _filters.copyWith(isAvailable: value);
                      });
                    },
                    activeColor: ThemeUtils.getPrimaryColor(context),
                    contentPadding: EdgeInsets.zero,
                  ),

                  const SizedBox(height: 100), // Space for bottom buttons
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeUtils.getSurfaceColor(context),
              boxShadow: [
                BoxShadow(
                  color: ThemeUtils.getShadowLightColor(context),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reset',
                    onPressed: _clearFilters,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Apply Filters',
                    onPressed: () => widget.onApplyFilters(_filters),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: ThemeUtils.getTextPrimaryColor(context),
        ),
      ),
    );
  }

  Widget _buildSpecialtyFilter() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.doctorSpecialties.map((specialty) {
        final isSelected = _filters.specialty == specialty;
        return FilterChip(
          label: Text(specialty),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(
                specialty: selected ? specialty : null,
              );
            });
          },
          selectedColor: ThemeUtils.getPrimaryColor(
            context,
          ).withValues(alpha: 0.2),
          checkmarkColor: ThemeUtils.getPrimaryColor(context),
        );
      }).toList(),
    );
  }

  Widget _buildConsultationTypeFilter() {
    return Column(
      children: [
        RadioListTile<String?>(
          title: const Text('All'),
          value: null,
          groupValue: _filters.consultationType,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(consultationType: value);
            });
          },
          activeColor: ThemeUtils.getPrimaryColor(context),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('Online Consultation'),
          value: 'online',
          groupValue: _filters.consultationType,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(consultationType: value);
            });
          },
          activeColor: ThemeUtils.getPrimaryColor(context),
          contentPadding: EdgeInsets.zero,
        ),
        RadioListTile<String>(
          title: const Text('In-Person Visit'),
          value: 'offline',
          groupValue: _filters.consultationType,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(consultationType: value);
            });
          },
          activeColor: ThemeUtils.getPrimaryColor(context),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildRatingFilter() {
    final ratings = [4.0, 4.5, 5.0];
    return Wrap(
      spacing: 8,
      children: ratings.map((rating) {
        final isSelected = _filters.minRating == rating;
        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.star,
                size: 16,
                color: AppColors
                    .ratingFilled, // Rating color stays the same in both themes
              ),
              const SizedBox(width: 4),
              Text('${rating.toStringAsFixed(1)}+'),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _filters = _filters.copyWith(minRating: selected ? rating : null);
            });
          },
          selectedColor: ThemeUtils.getPrimaryColor(
            context,
          ).withValues(alpha: 0.2),
          checkmarkColor: ThemeUtils.getPrimaryColor(context),
        );
      }).toList(),
    );
  }

  void _clearFilters() {
    setState(() {
      _filters = const DoctorSearchFilters();
      _cityController.clear();
      _maxFeeController.clear();
    });
  }
}
