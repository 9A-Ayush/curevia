import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../providers/location_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/common/custom_button.dart';

/// Widget for handling location permission requests
class LocationPermissionWidget extends ConsumerWidget {
  final String title;
  final String description;
  final VoidCallback? onPermissionGranted;
  final Widget? child;

  const LocationPermissionWidget({
    super.key,
    this.title = 'Location Permission Required',
    this.description =
        'We need access to your location to provide location-based services.',
    this.onPermissionGranted,
    this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);

    // If permission is granted and we have location, show child
    if (locationState.hasPermission && locationState.hasLocation) {
      return child ?? const SizedBox.shrink();
    }

    // If loading, show loading indicator
    if (locationState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    // Show appropriate permission request based on status
    return _buildPermissionRequest(context, ref, locationState);
  }

  Widget _buildPermissionRequest(
    BuildContext context,
    WidgetRef ref,
    LocationState locationState,
  ) {
    switch (locationState.permissionStatus) {
      case LocationPermissionStatus.denied:
        return _buildPermissionDenied(context, ref);
      case LocationPermissionStatus.deniedForever:
        return _buildPermissionDeniedForever(context, ref);
      case LocationPermissionStatus.serviceDisabled:
        return _buildServiceDisabled(context, ref);
      case LocationPermissionStatus.granted:
        if (locationState.error != null) {
          return _buildLocationError(context, ref, locationState.error!);
        }
        return _buildLocationLoading(context, ref);
    }
  }

  Widget _buildPermissionDenied(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Grant Permission',
              onPressed: () async {
                final granted = await ref
                    .read(locationProvider.notifier)
                    .requestLocationPermission();
                if (granted) {
                  await ref
                      .read(locationProvider.notifier)
                      .getCurrentLocation();
                  onPermissionGranted?.call();
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Use manual location entry
                _showManualLocationEntry(context, ref);
              },
              child: const Text('Enter Location Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedForever(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'Location Permission Denied',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Location permission has been permanently denied. Please enable it in app settings to use location-based features.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Open Settings',
              onPressed: () =>
                  ref.read(locationProvider.notifier).openAppSettings(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _showManualLocationEntry(context, ref);
              },
              child: const Text('Enter Location Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDisabled(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_disabled, size: 80, color: AppColors.warning),
            const SizedBox(height: 24),
            Text(
              'Location Services Disabled',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Location services are turned off. Please enable them in your device settings to use location-based features.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Enable Location Services',
              onPressed: () =>
                  ref.read(locationProvider.notifier).openLocationSettings(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _showManualLocationEntry(context, ref);
              },
              child: const Text('Enter Location Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationError(
    BuildContext context,
    WidgetRef ref,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            const SizedBox(height: 24),
            Text(
              'Location Error',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Retry',
              onPressed: () async {
                await ref.read(locationProvider.notifier).getCurrentLocation();
                onPermissionGranted?.call();
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                _showManualLocationEntry(context, ref);
              },
              child: const Text('Enter Location Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationLoading(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Getting your location...',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              _showManualLocationEntry(context, ref);
            },
            child: const Text('Enter Location Manually'),
          ),
        ],
      ),
    );
  }

  void _showManualLocationEntry(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Your Location'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter city, address, or landmark',
            prefixIcon: Icon(Icons.location_on),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              ref.read(locationProvider.notifier).setLocationFromAddress(value);
              onPermissionGranted?.call();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final address = controller.text.trim();
              if (address.isNotEmpty) {
                Navigator.pop(context);
                ref
                    .read(locationProvider.notifier)
                    .setLocationFromAddress(address);
                onPermissionGranted?.call();
              }
            },
            child: const Text('Set Location'),
          ),
        ],
      ),
    );
  }
}
