import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service for tracking doctor revenue
class RevenueService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add revenue when appointment is confirmed
  static Future<void> addRevenue({
    required String doctorId,
    required String appointmentId,
    required double amount,
    required String type, // 'online', 'offline', 'video'
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      
      // Create revenue record
      await _firestore.collection('doctor_revenue').add({
        'doctorId': doctorId,
        'appointmentId': appointmentId,
        'amount': amount,
        'type': type,
        'description': description ?? 'Consultation fee',
        'status': 'confirmed',
        'createdAt': Timestamp.fromDate(now),
        'month': now.month,
        'year': now.year,
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      });

      debugPrint('Revenue added: ₹$amount for doctor $doctorId');
    } catch (e) {
      debugPrint('Error adding revenue: $e');
      throw Exception('Failed to add revenue: $e');
    }
  }

  /// Reduce revenue when appointment is cancelled
  static Future<void> reduceRevenue({
    required String doctorId,
    required String appointmentId,
    required double amount,
    required String type,
    String? reason,
  }) async {
    try {
      final now = DateTime.now();
      
      // Create negative revenue record
      await _firestore.collection('doctor_revenue').add({
        'doctorId': doctorId,
        'appointmentId': appointmentId,
        'amount': -amount, // Negative amount for reduction
        'type': type,
        'description': reason ?? 'Appointment cancelled',
        'status': 'cancelled',
        'createdAt': Timestamp.fromDate(now),
        'month': now.month,
        'year': now.year,
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
      });

      debugPrint('Revenue reduced: ₹$amount for doctor $doctorId');
    } catch (e) {
      debugPrint('Error reducing revenue: $e');
      throw Exception('Failed to reduce revenue: $e');
    }
  }

  /// Get total revenue for a doctor in a specific period
  static Future<Map<String, dynamic>> getDoctorRevenue({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      startDate ??= DateTime(now.year, now.month, 1); // Default to current month
      endDate ??= DateTime(now.year, now.month + 1, 0); // End of current month

      Query query = _firestore
          .collection('doctor_revenue')
          .where('doctorId', isEqualTo: doctorId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final querySnapshot = await query.get();

      double totalRevenue = 0;
      double onlineRevenue = 0;
      double offlineRevenue = 0;
      double videoRevenue = 0;
      int confirmedCount = 0;
      int cancelledCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = data['type'] as String? ?? 'offline';
        final status = data['status'] as String? ?? 'confirmed';

        totalRevenue += amount;

        if (status == 'confirmed') {
          confirmedCount++;
        } else if (status == 'cancelled') {
          cancelledCount++;
        }

        switch (type.toLowerCase()) {
          case 'online':
          case 'video':
            if (amount > 0) videoRevenue += amount;
            break;
          case 'offline':
          default:
            if (amount > 0) offlineRevenue += amount;
            break;
        }
      }

      return {
        'totalRevenue': totalRevenue,
        'onlineRevenue': videoRevenue,
        'offlineRevenue': offlineRevenue,
        'confirmedAppointments': confirmedCount,
        'cancelledAppointments': cancelledCount,
        'netRevenue': totalRevenue, // Already includes cancellations as negative
      };
    } catch (e) {
      debugPrint('Error getting doctor revenue: $e');
      return {
        'totalRevenue': 0.0,
        'onlineRevenue': 0.0,
        'offlineRevenue': 0.0,
        'confirmedAppointments': 0,
        'cancelledAppointments': 0,
        'netRevenue': 0.0,
      };
    }
  }

  /// Get daily revenue breakdown for analytics
  static Future<List<Map<String, dynamic>>> getDailyRevenue({
    required String doctorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = await _firestore
          .collection('doctor_revenue')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date')
          .get();

      final dailyRevenue = <String, double>{};

      for (final doc in query.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final date = (data['date'] as Timestamp).toDate();
        final dateKey = '${date.day}/${date.month}';

        dailyRevenue[dateKey] = (dailyRevenue[dateKey] ?? 0) + amount;
      }

      return dailyRevenue.entries
          .map((entry) => {
                'date': entry.key,
                'revenue': entry.value,
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting daily revenue: $e');
      return [];
    }
  }

  /// Get revenue by consultation type
  static Future<Map<String, double>> getRevenueByType({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      startDate ??= DateTime(now.year, now.month, 1);
      endDate ??= DateTime(now.year, now.month + 1, 0);

      final query = await _firestore
          .collection('doctor_revenue')
          .where('doctorId', isEqualTo: doctorId)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .where('amount', isGreaterThan: 0) // Only positive amounts
          .get();

      final revenueByType = <String, double>{
        'online': 0,
        'offline': 0,
        'video': 0,
      };

      for (final doc in query.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0;
        final type = (data['type'] as String? ?? 'offline').toLowerCase();

        if (type == 'video' || type == 'online') {
          revenueByType['online'] = (revenueByType['online'] ?? 0) + amount;
        } else {
          revenueByType['offline'] = (revenueByType['offline'] ?? 0) + amount;
        }
      }

      return revenueByType;
    } catch (e) {
      debugPrint('Error getting revenue by type: $e');
      return {'online': 0, 'offline': 0, 'video': 0};
    }
  }

  /// Check if revenue record exists for appointment
  static Future<bool> hasRevenueRecord(String appointmentId) async {
    try {
      final query = await _firestore
          .collection('doctor_revenue')
          .where('appointmentId', isEqualTo: appointmentId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking revenue record: $e');
      return false;
    }
  }

  /// Update revenue record status
  static Future<void> updateRevenueStatus({
    required String appointmentId,
    required String status,
  }) async {
    try {
      final query = await _firestore
          .collection('doctor_revenue')
          .where('appointmentId', isEqualTo: appointmentId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.update({
          'status': status,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      debugPrint('Error updating revenue status: $e');
    }
  }

  /// Get revenue summary for display
  static Future<Map<String, dynamic>> getRevenueSummary({
    required String doctorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final revenueData = await getDoctorRevenue(
        doctorId: doctorId,
        startDate: startDate,
        endDate: endDate,
      );

      final totalRevenue = revenueData['totalRevenue'] as double;
      final confirmedCount = revenueData['confirmedAppointments'] as int;
      final cancelledCount = revenueData['cancelledAppointments'] as int;

      return {
        'totalRevenue': totalRevenue,
        'netRevenue': totalRevenue,
        'confirmedAppointments': confirmedCount,
        'cancelledAppointments': cancelledCount,
        'revenueFromConfirmed': confirmedCount > 0 ? totalRevenue / confirmedCount * confirmedCount : 0,
        'revenueLostFromCancellations': cancelledCount * (confirmedCount > 0 ? totalRevenue / confirmedCount : 0),
      };
    } catch (e) {
      debugPrint('Error getting revenue summary: $e');
      return {
        'totalRevenue': 0.0,
        'netRevenue': 0.0,
        'confirmedAppointments': 0,
        'cancelledAppointments': 0,
        'revenueFromConfirmed': 0.0,
        'revenueLostFromCancellations': 0.0,
      };
    }
  }
} 