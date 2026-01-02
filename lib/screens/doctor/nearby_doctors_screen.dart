import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_colors.dart';
import '../../providers/location_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/doctor/doctor_card.dart';
import '../../widgets/common/custom_button.dart';

/// Nearby doctors screen with map view
class NearbyDoctorsScreen extends ConsumerStatefulWidget {
  const NearbyDoctorsScreen({super.key});

  @override
  ConsumerState<NearbyDoctorsScreen> createState() =>
      _NearbyDoctorsScreenState();
}

class _NearbyDoctorsScreenState extends ConsumerState<NearbyDoctorsScreen>
    with SingleTickerProviderStateMixin {
  GoogleMapController? _mapController;
  late TabController _tabController;
  Set<Marker> _markers = {};
  double _radiusKm = 10.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final locationNotifier = ref.read(locationProvider.notifier);
    final hasPermission = await locationNotifier.requestLocationPermission();

    if (hasPermission) {
      await locationNotifier.getCurrentLocation();
      _loadNearbyDoctors();
    }
  }

  void _loadNearbyDoctors() {
    // Use WidgetsBinding to ensure we're not in build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final position = ref.read(currentPositionProvider);
      if (position != null) {
        ref
            .read(doctorSearchProvider.notifier)
            .getNearbyDoctors(
              latitude: position.latitude,
              longitude: position.longitude,
              radiusKm: _radiusKm,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final doctorSearchState = ref.watch(doctorSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Doctors'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        actions: [
          IconButton(
            onPressed: _showRadiusSelector,
            icon: const Icon(Icons.tune),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withOpacity(0.7),
          indicatorColor: AppColors.textOnPrimary,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Map'),
            Tab(icon: Icon(Icons.list), text: 'List'),
          ],
        ),
      ),
      body: _buildBody(locationState, doctorSearchState),
    );
  }

  Widget _buildBody(
    LocationState locationState,
    DoctorSearchState doctorSearchState,
  ) {
    if (!locationState.hasPermission) {
      return _buildPermissionRequest();
    }

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

    if (locationState.error != null) {
      return _buildErrorView(locationState.error!);
    }

    if (!locationState.hasLocation) {
      return _buildLocationNotFound();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildMapView(locationState, doctorSearchState),
        _buildListView(doctorSearchState),
      ],
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 80, color: AppColors.textSecondary),
            const SizedBox(height: 24),
            Text(
              'Location Permission Required',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We need access to your location to show nearby doctors and provide accurate directions.',
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
                  _loadNearbyDoctors();
                }
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () =>
                  ref.read(locationProvider.notifier).openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
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
                _loadNearbyDoctors();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              'Location Not Found',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to determine your current location. Please try again or enter your location manually.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Try Again',
              onPressed: () async {
                await ref.read(locationProvider.notifier).getCurrentLocation();
                _loadNearbyDoctors();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView(
    LocationState locationState,
    DoctorSearchState doctorSearchState,
  ) {
    final position = locationState.currentPosition!;

    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            _updateMarkers(doctorSearchState.doctors, position);
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 14.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),

        // Radius indicator
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Within ${_radiusKm.toStringAsFixed(0)} km',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),

        // Loading indicator
        if (doctorSearchState.isLoading)
          const Positioned(
            top: 16,
            right: 16,
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildListView(DoctorSearchState doctorSearchState) {
    if (doctorSearchState.isLoading && doctorSearchState.doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (doctorSearchState.doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_searching,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No doctors found nearby',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing the search radius',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: doctorSearchState.doctors.length,
      itemBuilder: (context, index) {
        final doctor = doctorSearchState.doctors[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DoctorCard(doctor: doctor),
        );
      },
    );
  }

  void _updateMarkers(List doctors, position) {
    final markers = <Marker>{};

    // Add user location marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: const InfoWindow(title: 'Your Location'),
      ),
    );

    // Add doctor markers
    for (int i = 0; i < doctors.length; i++) {
      final doctor = doctors[i];
      if (doctor.location != null) {
        markers.add(
          Marker(
            markerId: MarkerId('doctor_$i'),
            position: LatLng(
              doctor.location!.latitude,
              doctor.location!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: doctor.fullName,
              snippet: doctor.specialty,
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showRadiusSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Search Radius',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _radiusKm,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              label: '${_radiusKm.toStringAsFixed(0)} km',
              onChanged: (value) {
                setState(() {
                  _radiusKm = value;
                });
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Apply',
              onPressed: () {
                Navigator.pop(context);
                _loadNearbyDoctors();
              },
            ),
          ],
        ),
      ),
    );
  }
}
