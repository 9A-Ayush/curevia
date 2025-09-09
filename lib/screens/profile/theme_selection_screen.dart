import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/theme_provider.dart';

class ThemeSelectionScreen extends ConsumerWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.primary,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Theme Settings',
          style: TextStyle(
            color: isDarkMode ? AppColors.darkTextPrimary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Your Theme',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select how you want the app to appear',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Theme options
              ...AppThemeMode.values.map((mode) => _buildThemeOption(
                context,
                ref,
                mode,
                themeState.themeMode == mode,
                themeNotifier,
                isDarkMode,
              )),
              
              const SizedBox(height: 32),
              
              // Preview section
              _buildPreviewSection(context, isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode mode,
    bool isSelected,
    ThemeNotifier themeNotifier,
    bool isDarkMode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => themeNotifier.setThemeMode(mode),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? (isDarkMode ? AppColors.darkPrimary : AppColors.primary)
                    : (isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDarkMode ? AppColors.darkShadowLight : AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDarkMode ? AppColors.darkPrimary : AppColors.primary)
                        : (isDarkMode ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    themeNotifier.getThemeModeIcon(mode),
                    color: isSelected
                        ? (isDarkMode ? AppColors.darkTextOnPrimary : AppColors.textOnPrimary)
                        : (isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        themeNotifier.getThemeModeDisplayName(mode),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        themeNotifier.getThemeModeDescription(mode),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: isDarkMode ? AppColors.darkShadowLight : AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview app bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.medical_services,
                      color: isDarkMode ? AppColors.darkTextOnPrimary : AppColors.textOnPrimary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Curevia',
                      style: TextStyle(
                        color: isDarkMode ? AppColors.darkTextOnPrimary : AppColors.textOnPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Preview content
              Text(
                'Sample Content',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is how your app will look with the selected theme. Text and icons are optimized for readability.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Preview button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sample Button',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDarkMode ? AppColors.darkTextOnPrimary : AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Preview card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDarkMode ? AppColors.darkBorderLight : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDarkMode ? AppColors.darkPrimary : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.favorite,
                        color: isDarkMode ? AppColors.darkTextOnPrimary : AppColors.textOnPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample Card',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Card description',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // Theme info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? AppColors.darkInfo.withOpacity(0.1) 
                : AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDarkMode ? AppColors.darkInfo : AppColors.info,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: isDarkMode ? AppColors.darkInfo : AppColors.info,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Theme changes will be applied immediately and saved for future app launches.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? AppColors.darkInfo : AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
