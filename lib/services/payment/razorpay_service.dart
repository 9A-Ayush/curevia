import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../utils/env_config.dart';
import '../../models/appointment_model.dart';
import '../../models/doctor_model.dart';
import '../../models/user_model.dart';

/// Service for handling Razorpay payments
class RazorpayService {
  static Razorpay? _razorpay;
  static String? _currentOrderId;
  static Function(String)? _onPaymentSuccess;
  static Function(String)? _onPaymentError;

  /// Initialize Razorpay
  static void initialize() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Dispose Razorpay
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  /// Create payment for appointment booking
  static Future<void> createAppointmentPayment({
    required BuildContext context,
    required AppointmentModel appointment,
    required DoctorModel doctor,
    required UserModel patient,
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      print('=== CREATING APPOINTMENT PAYMENT ===');
      
      if (_razorpay == null) {
        print('Initializing Razorpay...');
        initialize();
      }

      // Validate required data
      if (!isConfigured()) {
        throw Exception('Razorpay is not properly configured');
      }

      if (appointment.consultationFee == null || appointment.consultationFee! <= 0) {
        throw Exception('Invalid consultation fee: ${appointment.consultationFee}');
      }

      if (patient.email.isEmpty) {
        throw Exception('Patient email is required');
      }

      _onPaymentSuccess = onSuccess;
      _onPaymentError = onError;

      final consultationFee = appointment.consultationFee!;
      final platformFee = consultationFee * 0.02; // 2% platform fee
      final gst = (consultationFee + platformFee) * 0.18; // 18% GST
      final totalAmount = consultationFee + platformFee + gst;
      final amountInPaise = (totalAmount * 100).round();
      
      print('Payment details:');
      print('- Consultation Fee: ₹$consultationFee');
      print('- Platform Fee: ₹${platformFee.toStringAsFixed(2)}');
      print('- GST: ₹${gst.toStringAsFixed(2)}');
      print('- Total Amount: ₹${totalAmount.toStringAsFixed(2)}');
      print('- Amount in Paise: $amountInPaise');
      
      final options = {
        'key': EnvConfig.razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'Curevia',
        'description': 'Consultation with Dr. ${doctor.fullName}',
        'prefill': {
          'contact': patient.phoneNumber ?? '',
          'email': patient.email,
          'name': patient.fullName,
        },
        'theme': {
          'color': '#2E7D32', // App primary color
        },
        'notes': {
          'appointment_id': appointment.id,
          'doctor_id': doctor.uid,
          'patient_id': patient.uid,
          'consultation_type': appointment.consultationType,
          'consultation_fee': consultationFee.toString(),
          'total_amount': totalAmount.toStringAsFixed(2),
        },
        'modal': {
          'ondismiss': () {
            print('Payment modal dismissed by user');
            onError('Payment cancelled by user');
          },
        },
        'timeout': 300, // 5 minutes timeout
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
      };

      print('Opening Razorpay with options: ${options.keys.join(', ')}');
      _razorpay!.open(options);
      print('Razorpay payment modal opened successfully');
    } catch (e, stackTrace) {
      print('=== PAYMENT CREATION ERROR ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      onError('Failed to initialize payment: $e');
    }
  }

  /// Create payment for consultation fee
  static Future<void> createConsultationPayment({
    required BuildContext context,
    required double amount,
    required String doctorName,
    required String patientName,
    required String patientEmail,
    required String patientPhone,
    required Map<String, dynamic> metadata,
    required Function(String paymentId) onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      if (_razorpay == null) {
        initialize();
      }

      _onPaymentSuccess = onSuccess;
      _onPaymentError = onError;

      final amountInPaise = (amount * 100).toInt();
      
      final options = {
        'key': EnvConfig.razorpayKeyId,
        'amount': amountInPaise,
        'currency': 'INR',
        'name': 'Curevia',
        'description': 'Consultation with Dr. $doctorName',
        'prefill': {
          'contact': patientPhone,
          'email': patientEmail,
          'name': patientName,
        },
        'theme': {
          'color': '#2E7D32',
        },
        'notes': metadata,
        'modal': {
          'ondismiss': () {
            onError('Payment cancelled by user');
          },
        },
      };

      _razorpay!.open(options);
    } catch (e) {
      onError('Failed to initialize payment: $e');
    }
  }

  /// Handle payment success
  static void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('=== PAYMENT SUCCESS ===');
    print('Payment ID: ${response.paymentId}');
    print('Order ID: ${response.orderId}');
    print('Signature: ${response.signature}');
    
    if (_onPaymentSuccess != null) {
      _onPaymentSuccess!(response.paymentId ?? '');
    } else {
      print('Warning: No payment success callback set');
    }
  }

  /// Handle payment error
  static void _handlePaymentError(PaymentFailureResponse response) {
    print('=== PAYMENT ERROR ===');
    print('Error Code: ${response.code}');
    print('Error Message: ${response.message}');
    
    String errorMessage = 'Payment failed';
    
    // Provide more specific error messages based on error message content
    final message = response.message?.toLowerCase() ?? '';
    
    if (message.contains('network') || message.contains('internet')) {
      errorMessage = 'Network error. Please check your internet connection and try again.';
    } else if (message.contains('cancel') || message.contains('user')) {
      errorMessage = 'Payment was cancelled by user.';
    } else if (message.contains('invalid') || message.contains('credential')) {
      errorMessage = 'Payment service configuration error. Please contact support.';
    } else if (message.contains('timeout')) {
      errorMessage = 'Payment timeout. Please try again.';
    } else if (message.contains('insufficient')) {
      errorMessage = 'Insufficient balance. Please try a different payment method.';
    } else if (response.message != null && response.message!.isNotEmpty) {
      errorMessage = response.message!;
    } else {
      errorMessage = 'Payment failed. Please try again or contact support.';
    }
    
    if (_onPaymentError != null) {
      _onPaymentError!(errorMessage);
    } else {
      print('Warning: No payment error callback set');
    }
  }

  /// Handle external wallet
  static void _handleExternalWallet(ExternalWalletResponse response) {
    print('=== EXTERNAL WALLET SELECTED ===');
    print('Wallet Name: ${response.walletName}');
    
    // For external wallets, we should handle this as a success case
    // but since we don't get a payment ID, we need to handle it differently
    if (_onPaymentError != null) {
      _onPaymentError!('Payment completed via ${response.walletName}. Please contact support if payment was successful.');
    }
  }

  /// Verify payment (to be implemented with backend)
  static Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      // TODO: Implement payment verification with your backend
      // This should verify the payment signature with Razorpay
      
      // For now, return true (in production, implement proper verification)
      return true;
    } catch (e) {
      print('Payment verification failed: $e');
      return false;
    }
  }

  /// Get payment details
  static Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    try {
      // TODO: Implement with backend API to fetch payment details from Razorpay
      // This requires server-side implementation
      
      return {
        'payment_id': paymentId,
        'status': 'captured',
        'amount': 0,
        'currency': 'INR',
        'created_at': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Failed to get payment details: $e');
      return null;
    }
  }

  /// Refund payment (to be implemented with backend)
  static Future<bool> refundPayment({
    required String paymentId,
    required double amount,
    String? reason,
  }) async {
    try {
      // TODO: Implement refund with backend API
      // This requires server-side implementation with Razorpay API
      
      print('Refund initiated for payment: $paymentId, amount: $amount');
      return true;
    } catch (e) {
      print('Refund failed: $e');
      return false;
    }
  }

  /// Format amount for display
  static String formatAmount(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  /// Get supported payment methods
  static List<Map<String, dynamic>> getSupportedPaymentMethods() {
    return [
      {
        'id': 'card',
        'name': 'Credit/Debit Card',
        'icon': 'credit_card',
        'description': 'Visa, Mastercard, RuPay, American Express',
      },
      {
        'id': 'netbanking',
        'name': 'Net Banking',
        'icon': 'account_balance',
        'description': 'All major banks supported',
      },
      {
        'id': 'upi',
        'name': 'UPI',
        'icon': 'qr_code',
        'description': 'Google Pay, PhonePe, Paytm, BHIM',
      },
      {
        'id': 'wallet',
        'name': 'Wallets',
        'icon': 'account_balance_wallet',
        'description': 'Paytm, Mobikwik, Freecharge, Ola Money',
      },
      {
        'id': 'emi',
        'name': 'EMI',
        'icon': 'payment',
        'description': 'No cost EMI available',
      },
    ];
  }

  /// Check if Razorpay is configured
  static bool isConfigured() {
    final keyId = EnvConfig.razorpayKeyId;
    final keySecret = EnvConfig.razorpayKeySecret;
    
    return keyId.isNotEmpty && keySecret.isNotEmpty;
  }

  /// Check if Razorpay instance is initialized
  static bool isInitialized() {
    return _razorpay != null;
  }

  /// Get configuration status
  static Map<String, dynamic> getConfigurationStatus() {
    final keyId = EnvConfig.razorpayKeyId;
    final keySecret = EnvConfig.razorpayKeySecret;
    
    return {
      'configured': isConfigured(),
      'initialized': isInitialized(),
      'key_id_set': keyId.isNotEmpty,
      'key_secret_set': keySecret.isNotEmpty,
      'key_id_preview': keyId.isNotEmpty ? '${keyId.substring(0, 8)}...' : 'Not set',
    };
  }
}