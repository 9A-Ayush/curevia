import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Service for handling Google Maps integration and directions
class MapsService {
  
  /// Open Google Maps with directions to a specific address
  static Future<bool> openDirections({
    required String destinationAddress,
    String? destinationName,
  }) async {
    try {
      // Clean and encode the address
      final encodedAddress = Uri.encodeComponent(destinationAddress);
      final encodedName = destinationName != null ? Uri.encodeComponent(destinationName) : null;
      
      // Create the destination query
      final destination = encodedName != null ? '$encodedName, $encodedAddress' : encodedAddress;
      
      // Try Google Maps app first (more reliable)
      final googleMapsUrl = 'google.navigation:q=$destination';
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        return await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      // Fallback to Google Maps web
      final webMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destination';
      if (await canLaunchUrl(Uri.parse(webMapsUrl))) {
        return await launchUrl(
          Uri.parse(webMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      // Last fallback - generic maps URL
      final genericMapsUrl = 'https://maps.google.com/?q=$destination';
      return await launchUrl(
        Uri.parse(genericMapsUrl),
        mode: LaunchMode.externalApplication,
      );
      
    } catch (e) {
      print('Error opening directions: $e');
      return false;
    }
  }
  
  /// Open Google Maps with directions from current location to destination
  static Future<bool> openDirectionsFromCurrentLocation({
    required String destinationAddress,
    String? destinationName,
    double? destinationLat,
    double? destinationLng,
  }) async {
    try {
      String destination;
      
      // Use coordinates if available (more accurate)
      if (destinationLat != null && destinationLng != null) {
        destination = '$destinationLat,$destinationLng';
      } else {
        // Use address
        final encodedAddress = Uri.encodeComponent(destinationAddress);
        final encodedName = destinationName != null ? Uri.encodeComponent(destinationName) : null;
        destination = encodedName != null ? '$encodedName, $encodedAddress' : encodedAddress;
      }
      
      // Try Google Maps app with directions
      final googleMapsUrl = 'google.navigation:q=$destination&mode=d';
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        return await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      // Fallback to web version with directions
      final webMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';
      if (await canLaunchUrl(Uri.parse(webMapsUrl))) {
        return await launchUrl(
          Uri.parse(webMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      return false;
      
    } catch (e) {
      print('Error opening directions from current location: $e');
      return false;
    }
  }
  
  /// Open Google Maps to show a specific location
  static Future<bool> openLocation({
    required String address,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      String query;
      
      // Use coordinates if available
      if (latitude != null && longitude != null) {
        query = '$latitude,$longitude';
        if (locationName != null) {
          query = '${Uri.encodeComponent(locationName)}@$latitude,$longitude';
        }
      } else {
        // Use address
        final encodedAddress = Uri.encodeComponent(address);
        query = locationName != null ? '${Uri.encodeComponent(locationName)}, $encodedAddress' : encodedAddress;
      }
      
      // Try Google Maps app
      final googleMapsUrl = 'geo:0,0?q=$query';
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        return await launchUrl(
          Uri.parse(googleMapsUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      // Fallback to web
      final webMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
      return await launchUrl(
        Uri.parse(webMapsUrl),
        mode: LaunchMode.externalApplication,
      );
      
    } catch (e) {
      print('Error opening location: $e');
      return false;
    }
  }
  
  /// Get Google Maps static image URL for a location
  static String getStaticMapUrl({
    required String address,
    int width = 400,
    int height = 300,
    int zoom = 15,
    String mapType = 'roadmap',
  }) {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('Warning: Google Maps API key not found');
      return '';
    }
    
    final encodedAddress = Uri.encodeComponent(address);
    return 'https://maps.googleapis.com/maps/api/staticmap?'
        'center=$encodedAddress'
        '&zoom=$zoom'
        '&size=${width}x$height'
        '&maptype=$mapType'
        '&markers=color:red%7C$encodedAddress'
        '&key=$apiKey';
  }
  
  /// Calculate estimated travel time (requires Google Maps API)
  static Future<String?> getEstimatedTravelTime({
    required String origin,
    required String destination,
    String mode = 'driving', // driving, walking, transit, bicycling
  }) async {
    try {
      final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('Warning: Google Maps API key not found');
        return null;
      }
      
      // This would require implementing the Distance Matrix API
      // For now, return a placeholder
      return 'Calculating...';
      
    } catch (e) {
      print('Error calculating travel time: $e');
      return null;
    }
  }
  
  /// Copy address to clipboard
  static Future<void> copyAddressToClipboard(String address) async {
    try {
      await Clipboard.setData(ClipboardData(text: address));
    } catch (e) {
      print('Error copying address to clipboard: $e');
    }
  }
  
  /// Validate if an address string looks valid
  static bool isValidAddress(String address) {
    if (address.trim().isEmpty) return false;
    
    // Basic validation - should contain some common address components
    final addressLower = address.toLowerCase();
    final hasStreetIndicators = addressLower.contains(RegExp(r'\b(street|st|road|rd|avenue|ave|lane|ln|drive|dr|place|pl|way|circle|cir|court|ct|boulevard|blvd)\b'));
    final hasNumbers = address.contains(RegExp(r'\d'));
    
    return hasStreetIndicators || hasNumbers || address.length > 10;
  }
  
  /// Format address for display
  static String formatAddressForDisplay(String address) {
    if (address.trim().isEmpty) return 'Address not available';
    
    // Clean up the address
    return address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(', ');
  }
}