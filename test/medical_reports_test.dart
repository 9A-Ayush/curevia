import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import '../lib/providers/medical_report_provider.dart';
import '../lib/services/ai/google_vision_service.dart';

void main() {
  group('Medical Reports Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Medical report provider initial state', () {
      final state = container.read(medicalReportProvider);
      
      expect(state.reports, isEmpty);
      expect(state.isLoading, false);
      expect(state.isUploading, false);
      expect(state.isProcessing, false);
      expect(state.error, null);
      expect(state.extractedData, null);
      expect(state.uploadProgress, 0.0);
    });

    test('Medical report state copyWith', () {
      const initialState = MedicalReportState();
      
      final newState = initialState.copyWith(
        isLoading: true,
        uploadProgress: 0.5,
      );
      
      expect(newState.isLoading, true);
      expect(newState.uploadProgress, 0.5);
      expect(newState.reports, isEmpty);
      expect(newState.isUploading, false);
    });

    group('Google Vision Service', () {
      test('MedicalReportData creation', () {
        final data = MedicalReportData(
          patientName: 'John Doe',
          doctorName: 'Dr. Smith',
          hospitalName: 'City Hospital',
          reportDate: DateTime(2024, 1, 15),
          diagnosis: 'Hypertension',
          treatment: 'Medication',
          prescription: 'Lisinopril 10mg',
          medications: ['Lisinopril'],
          labResults: {'bp': '140/90'},
          vitals: {'heart_rate': '80'},
          extractedText: 'Sample medical report text',
          notes: 'Follow up in 2 weeks',
        );

        expect(data.patientName, 'John Doe');
        expect(data.doctorName, 'Dr. Smith');
        expect(data.hospitalName, 'City Hospital');
        expect(data.diagnosis, 'Hypertension');
        expect(data.medications, contains('Lisinopril'));
        expect(data.labResults['bp'], '140/90');
        expect(data.vitals['heart_rate'], '80');
      });

      test('MedicalReportData toMap', () {
        final data = MedicalReportData(
          patientName: 'John Doe',
          reportDate: DateTime(2024, 1, 15),
          extractedText: 'Sample text',
        );

        final map = data.toMap();

        expect(map['patientName'], 'John Doe');
        expect(map['reportDate'], '2024-01-15T00:00:00.000');
        expect(map['extractedText'], 'Sample text');
        expect(map['medications'], isEmpty);
        expect(map['labResults'], isEmpty);
        expect(map['vitals'], isEmpty);
      });
    });

    group('Medical Report Provider Actions', () {
      test('clearError sets error to null', () {
        final notifier = container.read(medicalReportProvider.notifier);
        
        // Set an error first
        notifier.state = notifier.state.copyWith(error: 'Test error');
        expect(notifier.state.error, 'Test error');
        
        // Clear the error
        notifier.clearError();
        expect(notifier.state.error, null);
      });

      test('clearExtractedData sets extractedData to null', () {
        final notifier = container.read(medicalReportProvider.notifier);
        
        // Set extracted data first
        final testData = MedicalReportData(
          reportDate: DateTime.now(),
          extractedText: 'test',
        );
        notifier.state = notifier.state.copyWith(extractedData: testData);
        expect(notifier.state.extractedData, testData);
        
        // Clear the extracted data
        notifier.clearExtractedData();
        expect(notifier.state.extractedData, null);
      });

      test('resetProgress resets upload state', () {
        final notifier = container.read(medicalReportProvider.notifier);
        
        // Set upload state
        notifier.state = notifier.state.copyWith(
          isUploading: true,
          isProcessing: true,
          uploadProgress: 0.8,
        );
        
        // Reset progress
        notifier.resetProgress();
        
        expect(notifier.state.isUploading, false);
        expect(notifier.state.isProcessing, false);
        expect(notifier.state.uploadProgress, 0.0);
      });
    });

    group('Provider Selectors', () {
      test('medicalReportsCountProvider returns correct count', () {
        final notifier = container.read(medicalReportProvider.notifier);
        
        // Initially should be 0
        expect(container.read(medicalReportsCountProvider), 0);
        
        // Add some mock reports
        notifier.state = notifier.state.copyWith(
          reports: [
            // Mock reports would go here
            // For now, just test the provider structure
          ],
        );
        
        expect(container.read(medicalReportsCountProvider), 0);
      });
    });
  });

  group('Text Parsing Tests', () {
    test('Extract value after colon', () {
      const line = 'Patient Name: John Doe';
      final result = _extractValueAfterColon(line);
      expect(result, 'John Doe');
    });

    test('Extract numbers from text', () {
      const line = 'Blood Pressure: 120/80 mmHg';
      final result = _extractNumbers(line);
      expect(result, '120');
    });

    test('Extract value after colon - no colon', () {
      const line = 'Patient Name John Doe';
      final result = _extractValueAfterColon(line);
      expect(result, null);
    });

    test('Extract numbers - no numbers', () {
      const line = 'No numbers here';
      final result = _extractNumbers(line);
      expect(result, null);
    });
  });
}

// Helper functions for testing (copied from GoogleVisionService)
String? _extractValueAfterColon(String line) {
  final colonIndex = line.indexOf(':');
  if (colonIndex != -1 && colonIndex < line.length - 1) {
    return line.substring(colonIndex + 1).trim();
  }
  return null;
}

String? _extractNumbers(String line) {
  final regex = RegExp(r'[\d.]+');
  final match = regex.firstMatch(line);
  return match?.group(0);
}
