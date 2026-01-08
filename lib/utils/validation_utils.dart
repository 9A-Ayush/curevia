/// Utility class for common validation functions
class ValidationUtils {
  /// Validates Indian mobile phone numbers
  /// Returns null if valid, error message if invalid
  static String? validatePhoneNumber(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter your phone number' : null;
    }
    
    // Remove any non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (digitsOnly.length != 10) {
      return 'Phone number must be exactly 10 digits';
    }
    
    // Check if it's a valid Indian mobile number (starts with 6, 7, 8, or 9)
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(digitsOnly)) {
      return 'Please enter a valid Indian mobile number';
    }
    
    return null;
  }

  /// Validates email addresses
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter your email address' : null;
    }
    
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates required text fields
  /// Returns null if valid, error message if invalid
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Validates name fields (only letters and spaces)
  /// Returns null if valid, error message if invalid
  static String? validateName(String? value, String fieldName, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter $fieldName' : null;
    }
    
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return '$fieldName should only contain letters and spaces';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters long';
    }
    
    return null;
  }

  /// Validates numeric fields
  /// Returns null if valid, error message if invalid
  static String? validateNumeric(String? value, String fieldName, {bool isRequired = true, int? min, int? max}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter $fieldName' : null;
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number for $fieldName';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be at most $max';
    }
    
    return null;
  }

  /// Validates pincode (6 digits)
  /// Returns null if valid, error message if invalid
  static String? validatePincode(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Please enter pincode' : null;
    }
    
    if (!RegExp(r'^[0-9]{6}$').hasMatch(value)) {
      return 'Please enter a valid 6-digit pincode';
    }
    
    return null;
  }

  /// Validates password strength
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String? value, {bool isRequired = true}) {
    if (value == null || value.isEmpty) {
      return isRequired ? 'Please enter a password' : null;
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }
    
    return null;
  }

  /// Validates confirm password
  /// Returns null if valid, error message if invalid
  static String? validateConfirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}