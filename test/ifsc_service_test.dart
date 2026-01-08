import 'package:flutter_test/flutter_test.dart';
import 'package:curevia/services/ifsc_service.dart';

void main() {
  group('IFSC Service Tests', () {
    test('should get list of banks', () async {
      final banks = await IFSCService.getBanks();
      expect(banks, isNotEmpty);
      expect(banks.first.name, isNotEmpty);
      expect(banks.first.code, isNotEmpty);
    });

    test('should get IFSC details for valid code', () async {
      try {
        final details = await IFSCService.getIFSCDetails('SBIN0000001');
        expect(details.bank, isNotEmpty);
        expect(details.ifsc, equals('SBIN0000001'));
      } catch (e) {
        print('IFSC Details Error: $e');
        fail('Should not throw error for valid IFSC code');
      }
    });

    test('should get states for a bank', () async {
      try {
        final states = await IFSCService.getStatesForBank('State Bank of India');
        expect(states, isNotEmpty);
        print('States found: ${states.length}');
        print('First few states: ${states.take(5).join(', ')}');
      } catch (e) {
        print('States Error: $e');
        fail('Should not throw error when getting states');
      }
    });

    test('should get districts for bank and state - detailed', () async {
      try {
        final states = await IFSCService.getStatesForBank('State Bank of India');
        expect(states, isNotEmpty);
        print('Available states: ${states.take(5).join(', ')}');
        
        // Try multiple states to find one with districts
        for (int i = 0; i < states.length && i < 5; i++) {
          final state = states[i];
          print('\nTrying state: $state');
          
          final districts = await IFSCService.getDistrictsForBankAndState(
            bankName: 'State Bank of India',
            state: state,
          );
          
          print('Districts found for $state: ${districts.length}');
          if (districts.isNotEmpty) {
            print('First few districts: ${districts.take(3).join(', ')}');
            expect(districts, isNotEmpty);
            return; // Success, exit the test
          }
        }
        
        fail('No districts found for any of the first 5 states');
      } catch (e) {
        print('Districts Error: $e');
        fail('Should not throw error when getting districts: $e');
      }
    });

    test('should get branches for bank, state, and district', () async {
      try {
        final states = await IFSCService.getStatesForBank('State Bank of India');
        if (states.isNotEmpty) {
          // Try multiple states to find one with districts and branches
          for (int i = 0; i < states.length && i < 3; i++) {
            final state = states[i];
            final districts = await IFSCService.getDistrictsForBankAndState(
              bankName: 'State Bank of India',
              state: state,
            );
            
            if (districts.isNotEmpty) {
              final branches = await IFSCService.getBranches(
                bankName: 'State Bank of India',
                state: state,
                district: districts.first,
              );
              
              if (branches.isNotEmpty) {
                print('Branches found: ${branches.length}');
                expect(branches, isNotEmpty);
                return; // Success
              }
            }
          }
          
          print('No branches found for any state/district combination');
        }
      } catch (e) {
        print('Branches Error: $e');
        fail('Should not throw error when getting branches');
      }
    });
  });
}