import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permission_request_screen.dart';

/// Provider to track if permissions have been requested
final permissionsRequestedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('permissions_requested') ?? false;
});

/// Wrapper that shows permission request screen if needed
class PermissionWrapper extends ConsumerWidget {
  final Widget child;
  final String userRole;

  const PermissionWrapper({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionsRequested = ref.watch(permissionsRequestedProvider);

    return permissionsRequested.when(
      data: (requested) {
        if (requested) {
          return child;
        }
        return PermissionRequestScreen(
          userRole: userRole,
          onPermissionsGranted: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('permissions_requested', true);
            ref.invalidate(permissionsRequestedProvider);
          },
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => child, // On error, skip permission screen
    );
  }
}
