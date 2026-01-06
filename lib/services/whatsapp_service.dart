import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

/// Service for handling WhatsApp integration and messaging
class WhatsAppService {
  
  /// Open WhatsApp chat with a specific phone number and pre-filled message
  static Future<bool> openChat({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      final cleanedNumber = _cleanPhoneNumber(phoneNumber);
      
      if (!_isValidPhoneNumber(cleanedNumber)) {
        print('Invalid phone number: $phoneNumber');
        return false;
      }
      
      // Encode message if provided
      final encodedMessage = message != null ? Uri.encodeComponent(message) : '';
      
      // Try WhatsApp app first
      final whatsappUrl = 'whatsapp://send?phone=$cleanedNumber${message != null ? '&text=$encodedMessage' : ''}';
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        return await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      // Fallback to WhatsApp Web
      final webWhatsappUrl = 'https://wa.me/$cleanedNumber${message != null ? '?text=$encodedMessage' : ''}';
      if (await canLaunchUrl(Uri.parse(webWhatsappUrl))) {
        return await launchUrl(
          Uri.parse(webWhatsappUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      
      return false;
      
    } catch (e) {
      print('Error opening WhatsApp chat: $e');
      return false;
    }
  }
  
  /// Open WhatsApp chat with doctor using appointment template
  static Future<bool> openDoctorChat({
    required String doctorName,
    required String doctorPhone,
    required String patientName,
    required String appointmentDate,
    required String appointmentTime,
    String? clinicName,
  }) async {
    final message = _generateAppointmentMessage(
      doctorName: doctorName,
      patientName: patientName,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      clinicName: clinicName,
    );
    
    return await openChat(
      phoneNumber: doctorPhone,
      message: message,
    );
  }
  
  /// Open WhatsApp chat for appointment confirmation
  static Future<bool> openAppointmentConfirmationChat({
    required String doctorName,
    required String doctorPhone,
    required String patientName,
    required String appointmentDate,
    required String appointmentTime,
    String? clinicName,
  }) async {
    final message = _generateConfirmationMessage(
      doctorName: doctorName,
      patientName: patientName,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      clinicName: clinicName,
    );
    
    return await openChat(
      phoneNumber: doctorPhone,
      message: message,
    );
  }
  
  /// Open WhatsApp chat for appointment rescheduling
  static Future<bool> openRescheduleChat({
    required String doctorName,
    required String doctorPhone,
    required String patientName,
    required String currentAppointmentDate,
    required String currentAppointmentTime,
    String? clinicName,
  }) async {
    final message = _generateRescheduleMessage(
      doctorName: doctorName,
      patientName: patientName,
      currentAppointmentDate: currentAppointmentDate,
      currentAppointmentTime: currentAppointmentTime,
      clinicName: clinicName,
    );
    
    return await openChat(
      phoneNumber: doctorPhone,
      message: message,
    );
  }
  
  /// Open WhatsApp chat for appointment cancellation
  static Future<bool> openCancellationChat({
    required String doctorName,
    required String doctorPhone,
    required String patientName,
    required String appointmentDate,
    required String appointmentTime,
    String? clinicName,
    String? reason,
  }) async {
    final message = _generateCancellationMessage(
      doctorName: doctorName,
      patientName: patientName,
      appointmentDate: appointmentDate,
      appointmentTime: appointmentTime,
      clinicName: clinicName,
      reason: reason,
    );
    
    return await openChat(
      phoneNumber: doctorPhone,
      message: message,
    );
  }
  
  /// Open WhatsApp chat for general inquiry
  static Future<bool> openGeneralInquiry({
    required String doctorName,
    required String doctorPhone,
    required String patientName,
    String? inquiry,
  }) async {
    final message = _generateInquiryMessage(
      doctorName: doctorName,
      patientName: patientName,
      inquiry: inquiry,
    );
    
    return await openChat(
      phoneNumber: doctorPhone,
      message: message,
    );
  }
  
  /// Copy phone number to clipboard
  static Future<void> copyPhoneToClipboard(String phoneNumber) async {
    try {
      await Clipboard.setData(ClipboardData(text: phoneNumber));
    } catch (e) {
      print('Error copying phone number to clipboard: $e');
    }
  }
  
  /// Generate appointment message template
  static String _generateAppointmentMessage({
    required String doctorName,
    required String patientName,
    required String appointmentDate,
    required String appointmentTime,
    String? clinicName,
  }) {
    final clinic = clinicName != null ? ' at $clinicName' : '';
    return '''Hello Dr. $doctorName,

I am $patientName and I have an appointment scheduled with you on $appointmentDate at $appointmentTime$clinic.

I wanted to reach out regarding my upcoming appointment. Please let me know if you need any additional information from my side.

Thank you!

*Sent via Curevia App*''';
  }
  
  /// Generate confirmation message template
  static String _generateConfirmationMessage({
    required String doctorName,
    required String patientName,
    required String appointmentDate,
    required String appointmentTime,
    String? clinicName,
  }) {
    final clinic = clinicName != null ? ' at $clinicName' : '';
    return '''Hello Dr. $doctorName,

I am $patientName. I would like to confirm my appointment scheduled for $appointmentDate at $appointmentTime$clinic.

Please confirm if the appointment is still on schedule.

Thank you!

*Sent via Curevia App*''';
  }
  
  /// Generate reschedule message template
  static String _generateRescheduleMessage({
    required String doctorName,
    required String patientName,
    required String currentAppointmentDate,
    required String currentAppointmentTime,
    String? clinicName,
  }) {
    final clinic = clinicName != null ? ' at $clinicName' : '';
    return '''Hello Dr. $doctorName,

I am $patientName. I need to reschedule my appointment currently scheduled for $currentAppointmentDate at $currentAppointmentTime$clinic.

Could you please let me know your available slots for rescheduling?

Thank you for your understanding!

*Sent via Curevia App*''';
  }
  
  /// Generate cancellation message template
  static String _generateCancellationMessage({
    required String doctorName,
    required String patientName,
    required String appointmentDate,
    required String appointmentTime,
    String? clinicName,
    String? reason,
  }) {
    final clinic = clinicName != null ? ' at $clinicName' : '';
    final reasonText = reason != null ? '\n\nReason: $reason' : '';
    return '''Hello Dr. $doctorName,

I am $patientName. I need to cancel my appointment scheduled for $appointmentDate at $appointmentTime$clinic.$reasonText

I apologize for any inconvenience caused.

Thank you!

*Sent via Curevia App*''';
  }
  
  /// Generate general inquiry message template
  static String _generateInquiryMessage({
    required String doctorName,
    required String patientName,
    String? inquiry,
  }) {
    final inquiryText = inquiry ?? 'I have a general inquiry regarding my health.';
    return '''Hello Dr. $doctorName,

I am $patientName. $inquiryText

Could you please provide some guidance?

Thank you!

*Sent via Curevia App*''';
  }
  
  /// Clean phone number by removing non-digit characters except +
  static String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If number starts with +91, keep it
    if (cleaned.startsWith('+91')) {
      return cleaned;
    }
    
    // If number starts with 91 and is 12 digits, add +
    if (cleaned.startsWith('91') && cleaned.length == 12) {
      return '+$cleaned';
    }
    
    // If number is 10 digits, add +91
    if (cleaned.length == 10 && !cleaned.startsWith('0')) {
      return '+91$cleaned';
    }
    
    // If number starts with 0 and is 11 digits, remove 0 and add +91
    if (cleaned.startsWith('0') && cleaned.length == 11) {
      return '+91${cleaned.substring(1)}';
    }
    
    return cleaned;
  }
  
  /// Validate phone number format
  static bool _isValidPhoneNumber(String phoneNumber) {
    // Check if it's a valid Indian mobile number format
    final indianMobileRegex = RegExp(r'^\+91[6-9]\d{9}$');
    
    // Check if it's a valid international format
    final internationalRegex = RegExp(r'^\+\d{10,15}$');
    
    return indianMobileRegex.hasMatch(phoneNumber) || 
           internationalRegex.hasMatch(phoneNumber);
  }
  
  /// Format phone number for display
  static String formatPhoneForDisplay(String phoneNumber) {
    final cleaned = _cleanPhoneNumber(phoneNumber);
    
    if (cleaned.startsWith('+91') && cleaned.length == 13) {
      // Format Indian number: +91 98765 43210
      return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 8)} ${cleaned.substring(8)}';
    }
    
    return cleaned;
  }
  
  /// Check if WhatsApp is installed
  static Future<bool> isWhatsAppInstalled() async {
    try {
      return await canLaunchUrl(Uri.parse('whatsapp://'));
    } catch (e) {
      return false;
    }
  }
}