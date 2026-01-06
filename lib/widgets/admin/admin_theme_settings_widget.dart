import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import '../../utils/theme_utils.dart';
import '../../utils/responsive_utils.dart';

class AdminThemeSettingsWidget extends ConsumerWidget {
  const AdminThemeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: ResponsiveUtils.getResponsivePadding(context),
      decoration: BoxDecoration(
        color: ThemeUtils.getSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeUtils.getBorderLightColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                color: ThemeUtils.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Theme Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ThemeUtils.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Theme mode options
          if (isMobile) ...[
            // Mobile: Vertical layout
            _buildThemeOption(
              context,
              ref,
              AppThemeMode.light,
              'Light Mode',
              Icons.light_mode,
              themeState.themeMode == AppThemeMode.light,
              themeNotifier,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              ref,
              AppThemeMode.dark,
              'Dark Mode',
              Icons.dark_mode,
              themeState.themeMode == AppThemeMode.dark,
              themeNotifier,
            ),
            const SizedBox(height: 8),
            _buildThemeOption(
              context,
              ref,
              AppThemeMode.system,
              'System Default',
              Icons.settings_system_daydream,
              themeState.themeMode == AppThemeMode.system,
              themeNotifier,
            ),
          ] else ...[
            // Desktop: Horizontal layout
            Row(
              children: [
                Expanded(
                  child: _buildThemeOption(
                    context,
                    ref,
                    AppThemeMode.light,
                    'Light',
                    Icons.light_mode,
                    themeState.themeMode == AppThemeMode.light,
                    themeNotifier,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeOption(
                    context,
                    ref,
                    AppThemeMode.dark,
                    'Dark',
                    Icons.dark_mode,
                    themeState.themeMode == AppThemeMode.dark,
                    themeNotifier,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildThemeOption(
                    context,
                    ref,
                    AppThemeMode.system,
                    'System',
                    Icons.settings_system_daydream,
                    themeState.themeMode == AppThemeMode.system,
                    themeNotifier,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Current theme indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ThemeUtils.getSurfaceVariantColor(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  themeState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: ThemeUtils.getTextSecondaryColor(context),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Currently using ${themeState.isDarkMode ? 'dark' : 'light'} theme',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ThemeUtils.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode mode,
    String label,
    IconData icon,
    bool isSelected,
    ThemeNotifier themeNotifier,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => themeNotifier.setThemeMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? ThemeUtils.getPrimaryColor(context).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? ThemeUtils.getPrimaryColor(context)
                  : ThemeUtils.getBorderLightColor(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? ThemeUtils.getPrimaryColor(context)
                    : ThemeUtils.getTextSecondaryColor(context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected
                      ? ThemeUtils.getPrimaryColor(context)
                      : ThemeUtils.getTextPrimaryColor(context),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: ThemeUtils.getPrimaryColor(context),
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}