import 'package:flutter_test/flutter_test.dart';
import 'package:curevia/utils/validation_utils.dart';

void main() {
  group('Phone Number Validation Tests', () {
    test('Valid Indian mobile numbers should pass', () {
      // Valid 10-digit numbers starting with 6, 7, 8, 9
      expect(ValidationUtils.validatePhoneNumber('9876543210'), isNull);
      expect(ValidationUtils.validatePhoneNumber('8765432109'), isNull);
      expect(ValidationUtils.validatePhoneNumber('7654321098'), isNull);
      expect(ValidationUtils.validatePhoneNumber('6543210987'), isNull);
    });

    test('Invalid phone numbers should fail', () {
      // Less than 10 digits
      expect(ValidationUtils.validatePhoneNumber('987654321'), isNotNull);
      
      // More than 10 digits
      expect(ValidationUtils.validatePhoneNumber('98765432100'), isNotNull);
      
      // Starting with invalid digits (0-5)
      expect(ValidationUtils.validatePhoneNumber('5876543210'), isNotNull);
      expect(ValidationUtils.validatePhoneNumber('1234567890'), isNotNull);
      expect(ValidationUtils.validatePhoneNumber('0987654321'), isNotNull);
      
      // Non-numeric characters
      expect(ValidationUtils.validatePhoneNumber('abcd123456'), isNotNull);
    });

    test('Phone numbers with formatting should be cleaned', () {
      // Numbers with spaces, dashes should be cleaned and validated
      expect(ValidationUtils.validatePhoneNumber('987-654-3210'), isNull);
      expect(ValidationUtils.validatePhoneNumber('987 654 3210'), isNull);
      expect(ValidationUtils.validatePhoneNumber('(987) 654-3210'), isNull); // Valid after cleaning
      expect(ValidationUtils.validatePhoneNumber('+91 9876543210'), isNotNull); // More than 10 digits after cleaning
    });

    test('Empty and null values should be handled correctly', () {
      // Required field
      expect(ValidationUtils.validatePhoneNumber(null, isRequired: true), isNotNull);
      expect(ValidationUtils.validatePhoneNumber('', isRequired: true), isNotNull);
      expect(ValidationUtils.validatePhoneNumber('   ', isRequired: true), isNotNull);
      
      // Optional field
      expect(ValidationUtils.validatePhoneNumber(null, isRequired: false), isNull);
      expect(ValidationUtils.validatePhoneNumber('', isRequired: false), isNull);
      expect(ValidationUtils.validatePhoneNumber('   ', isRequired: false), isNull);
    });
  });

  group('Phone Number Formatting Tests', () {
    test('Valid phone numbers should be formatted correctly', () {
      expect(ValidationUtils.formatPhoneNumber('9876543210'), equals('9876543210'));
      expect(ValidationUtils.formatPhoneNumber('987-654-3210'), equals('9876543210'));
      expect(ValidationUtils.formatPhoneNumber('987 654 3210'), equals('9876543210'));
      expect(ValidationUtils.formatPhoneNumber('987.654.3210'), equals('9876543210'));
    });

    test('Empty values should return null', () {
      expect(ValidationUtils.formatPhoneNumber(null), isNull);
      expect(ValidationUtils.formatPhoneNumber(''), isNull);
      expect(ValidationUtils.formatPhoneNumber('   '), isNull);
    });

    test('Non-digit characters should be removed', () {
      expect(ValidationUtils.formatPhoneNumber('abc987def654ghi3210'), equals('9876543210'));
      expect(ValidationUtils.formatPhoneNumber('+91-987-654-3210'), equals('919876543210'));
    });
  });
}