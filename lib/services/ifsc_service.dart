import 'dart:convert';
import 'package:http/http.dart' as http;

class IFSCService {
  static const String _baseUrl = 'https://ifsc.razorpay.com';

  /// Get list of major Indian banks (predefined list since API doesn't provide all banks)
  static Future<List<BankInfo>> getBanks() async {
    try {
      // Return predefined list of major Indian banks
      // This is more reliable than depending on an API that might be down
      return _getMajorIndianBanks();
    } catch (e) {
      throw Exception('Error fetching banks: $e');
    }
  }

  /// Get predefined list of major Indian banks
  static List<BankInfo> _getMajorIndianBanks() {
    return [
      BankInfo(name: 'State Bank of India', code: 'SBIN'),
      BankInfo(name: 'HDFC Bank', code: 'HDFC'),
      BankInfo(name: 'ICICI Bank', code: 'ICIC'),
      BankInfo(name: 'Axis Bank', code: 'UTIB'),
      BankInfo(name: 'Kotak Mahindra Bank', code: 'KKBK'),
      BankInfo(name: 'IndusInd Bank', code: 'INDB'),
      BankInfo(name: 'Yes Bank', code: 'YESB'),
      BankInfo(name: 'IDFC First Bank', code: 'IDFB'),
      BankInfo(name: 'Federal Bank', code: 'FDRL'),
      BankInfo(name: 'South Indian Bank', code: 'SIBL'),
      BankInfo(name: 'Punjab National Bank', code: 'PUNB'),
      BankInfo(name: 'Bank of Baroda', code: 'BARB'),
      BankInfo(name: 'Canara Bank', code: 'CNRB'),
      BankInfo(name: 'Union Bank of India', code: 'UBIN'),
      BankInfo(name: 'Bank of India', code: 'BKID'),
      BankInfo(name: 'Central Bank of India', code: 'CBIN'),
      BankInfo(name: 'Indian Bank', code: 'IDIB'),
      BankInfo(name: 'Indian Overseas Bank', code: 'IOBA'),
      BankInfo(name: 'Punjab & Sind Bank', code: 'PSIB'),
      BankInfo(name: 'UCO Bank', code: 'UCBA'),
      BankInfo(name: 'Bank of Maharashtra', code: 'MAHB'),
      BankInfo(name: 'IDBI Bank', code: 'IBKL'),
      BankInfo(name: 'Bandhan Bank', code: 'BDBL'),
      BankInfo(name: 'City Union Bank', code: 'CIUB'),
      BankInfo(name: 'DCB Bank', code: 'DCBL'),
      BankInfo(name: 'Dhanlaxmi Bank', code: 'DLXB'),
      BankInfo(name: 'ESAF Small Finance Bank', code: 'ESMF'),
      BankInfo(name: 'HDFC Small Finance Bank', code: 'HDFB'),
      BankInfo(name: 'ICICI Small Finance Bank', code: 'ICSB'),
      BankInfo(name: 'Jana Small Finance Bank', code: 'JSFB'),
      BankInfo(name: 'Karur Vysya Bank', code: 'KVBL'),
      BankInfo(name: 'Lakshmi Vilas Bank', code: 'LAVB'),
      BankInfo(name: 'Nainital Bank', code: 'NTBL'),
      BankInfo(name: 'RBL Bank', code: 'RATN'),
      BankInfo(name: 'Tamilnad Mercantile Bank', code: 'TMBL'),
    ]..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get branches for a specific bank, state, and district using Razorpay API
  static Future<List<BranchInfo>> getBranches({
    required String bankName,
    required String state,
    required String district,
  }) async {
    try {
      // Find the bank code for the given bank name
      final banks = _getMajorIndianBanks();
      final bank = banks.firstWhere(
        (b) => b.name.toLowerCase() == bankName.toLowerCase(),
        orElse: () => throw Exception('Bank not found: $bankName'),
      );

      // Convert state name to ISO3166 code
      final stateCode = _getStateCode(state);

      // Use Razorpay's search API
      final uri = Uri.parse('https://ifsc.razorpay.com/search').replace(
        queryParameters: {
          'bankcode': bank.code,
          'state': stateCode,
          'limit': '100',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle both List and Map responses
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = List<dynamic>.from(responseData['data']);
        } else {
          // If it's a single object, wrap it in a list
          data = [responseData];
        }
        
        // Filter by district and convert to BranchInfo
        final branches = data
            .where((branch) => 
                branch is Map<String, dynamic> &&
                branch['DISTRICT']?.toString().toLowerCase() == district.toLowerCase())
            .map((branch) => BranchInfo.fromRazorpayJson(branch as Map<String, dynamic>))
            .toList();
            
        return branches;
      } else {
        throw Exception('Failed to load branches: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching branches: $e');
    }
  }

  /// Get IFSC details by IFSC code using Razorpay API
  static Future<IFSCDetails> getIFSCDetails(String ifscCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$ifscCode'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IFSCDetails.fromRazorpayJson(data);
      } else {
        throw Exception('Failed to load IFSC details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching IFSC details: $e');
    }
  }

  /// Get unique states for a specific bank using Razorpay API
  static Future<List<String>> getStatesForBank(String bankName) async {
    try {
      // Find the bank code for the given bank name
      final banks = _getMajorIndianBanks();
      final bank = banks.firstWhere(
        (b) => b.name.toLowerCase() == bankName.toLowerCase(),
        orElse: () => throw Exception('Bank not found: $bankName'),
      );

      // Use Razorpay's places API to get states
      final uri = Uri.parse('https://ifsc.razorpay.com/places').replace(
        queryParameters: {
          'bankcode': bank.code,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['states'] != null) {
          final List<String> states = List<String>.from(data['states']);
          states.sort();
          return states;
        }
        return [];
      } else {
        throw Exception('Failed to load states: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching states: $e');
    }
  }

  /// Get unique districts for a specific bank and state using Razorpay API
  static Future<List<String>> getDistrictsForBankAndState({
    required String bankName,
    required String state,
  }) async {
    try {
      // Find the bank code for the given bank name
      final banks = _getMajorIndianBanks();
      final bank = banks.firstWhere(
        (b) => b.name.toLowerCase() == bankName.toLowerCase(),
        orElse: () => throw Exception('Bank not found: $bankName'),
      );

      // Convert state name to ISO3166 code
      final stateCode = _getStateCode(state);
      
      // Use Razorpay's places API to get districts
      final uri = Uri.parse('https://ifsc.razorpay.com/places').replace(
        queryParameters: {
          'bankcode': bank.code,
          'state': stateCode,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['districts'] != null) {
          final List<String> districts = List<String>.from(data['districts']);
          districts.sort();
          return districts;
        }
        
        // If no districts are returned by the API, try to get them from search API
        return await _getDistrictsFromSearch(bank.code, stateCode);
      } else {
        throw Exception('Failed to load districts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching districts: $e');
    }
  }

  /// Fallback method to get districts from search API when places API doesn't return districts
  static Future<List<String>> _getDistrictsFromSearch(String bankCode, String stateCode) async {
    try {
      final uri = Uri.parse('https://ifsc.razorpay.com/search').replace(
        queryParameters: {
          'bankcode': bankCode,
          'state': stateCode,
          'limit': '500', // Get more results to find all districts
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        
        // Handle both List and Map responses
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          data = List<dynamic>.from(responseData['data']);
        } else {
          // If it's a single object, wrap it in a list
          data = [responseData];
        }
        
        // Extract unique districts from the search results
        final Set<String> districtsSet = {};
        for (final branch in data) {
          if (branch is Map<String, dynamic> && 
              branch['DISTRICT'] != null && 
              branch['DISTRICT'].toString().isNotEmpty) {
            districtsSet.add(branch['DISTRICT'].toString());
          }
        }
        
        final districts = districtsSet.toList();
        districts.sort();
        return districts;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Convert state name to ISO3166 code for Razorpay API
  static String _getStateCode(String stateName) {
    final stateMap = {
      'ANDHRA PRADESH': 'IN-AP',
      'ARUNACHAL PRADESH': 'IN-AR',
      'ASSAM': 'IN-AS',
      'BIHAR': 'IN-BR',
      'CHHATTISGARH': 'IN-CT',
      'GOA': 'IN-GA',
      'GUJARAT': 'IN-GJ',
      'HARYANA': 'IN-HR',
      'HIMACHAL PRADESH': 'IN-HP',
      'JHARKHAND': 'IN-JH',
      'KARNATAKA': 'IN-KA',
      'KERALA': 'IN-KL',
      'MADHYA PRADESH': 'IN-MP',
      'MAHARASHTRA': 'IN-MH',
      'MANIPUR': 'IN-MN',
      'MEGHALAYA': 'IN-ML',
      'MIZORAM': 'IN-MZ',
      'NAGALAND': 'IN-NL',
      'ODISHA': 'IN-OR',
      'PUNJAB': 'IN-PB',
      'RAJASTHAN': 'IN-RJ',
      'SIKKIM': 'IN-SK',
      'TAMIL NADU': 'IN-TN',
      'TELANGANA': 'IN-TG',
      'TRIPURA': 'IN-TR',
      'UTTAR PRADESH': 'IN-UP',
      'UTTARAKHAND': 'IN-UT',
      'WEST BENGAL': 'IN-WB',
      'DELHI': 'IN-DL',
      'JAMMU AND KASHMIR': 'IN-JK',
      'LADAKH': 'IN-LA',
      'CHANDIGARH': 'IN-CH',
      'DADRA AND NAGAR HAVELI AND DAMAN AND DIU': 'IN-DN',
      'LAKSHADWEEP': 'IN-LD',
      'PUDUCHERRY': 'IN-PY',
    };
    
    return stateMap[stateName.toUpperCase()] ?? stateName;
  }
}

class BankInfo {
  final String name;
  final String code;

  BankInfo({
    required this.name,
    required this.code,
  });

  factory BankInfo.fromJson(Map<String, dynamic> json) {
    return BankInfo(
      name: json['BANK'] ?? '',
      code: json['BANKCODE'] ?? '',
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BankInfo && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class BranchInfo {
  final String name;
  final String ifsc;
  final String address;
  final String city;
  final String district;
  final String state;
  final String micr;
  final String bankCode;

  BranchInfo({
    required this.name,
    required this.ifsc,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    required this.micr,
    required this.bankCode,
  });

  factory BranchInfo.fromJson(Map<String, dynamic> json) {
    return BranchInfo(
      name: json['BRANCH'] ?? '',
      ifsc: json['IFSC'] ?? '',
      address: json['ADDRESS'] ?? '',
      city: json['CITY'] ?? '',
      district: json['DISTRICT'] ?? '',
      state: json['STATE'] ?? '',
      micr: json['MICR'] ?? '',
      bankCode: json['BANKCODE'] ?? '',
    );
  }

  factory BranchInfo.fromRazorpayJson(Map<String, dynamic> json) {
    return BranchInfo(
      name: json['BRANCH'] ?? '',
      ifsc: json['IFSC'] ?? '',
      address: json['ADDRESS'] ?? '',
      city: json['CITY'] ?? '',
      district: json['DISTRICT'] ?? '',
      state: json['STATE'] ?? '',
      micr: json['MICR'] ?? '',
      bankCode: json['BANKCODE'] ?? '',
    );
  }

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchInfo && runtimeType == other.runtimeType && ifsc == other.ifsc;

  @override
  int get hashCode => ifsc.hashCode;
}

class IFSCDetails {
  final String bank;
  final String branch;
  final String ifsc;
  final String address;
  final String city;
  final String district;
  final String state;
  final String micr;
  final String bankCode;

  IFSCDetails({
    required this.bank,
    required this.branch,
    required this.ifsc,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    required this.micr,
    required this.bankCode,
  });

  factory IFSCDetails.fromJson(Map<String, dynamic> json) {
    return IFSCDetails(
      bank: json['BANK'] ?? '',
      branch: json['BRANCH'] ?? '',
      ifsc: json['IFSC'] ?? '',
      address: json['ADDRESS'] ?? '',
      city: json['CITY'] ?? '',
      district: json['DISTRICT'] ?? '',
      state: json['STATE'] ?? '',
      micr: json['MICR'] ?? '',
      bankCode: json['BANKCODE'] ?? '',
    );
  }

  factory IFSCDetails.fromRazorpayJson(Map<String, dynamic> json) {
    return IFSCDetails(
      bank: json['BANK'] ?? '',
      branch: json['BRANCH'] ?? '',
      ifsc: json['IFSC'] ?? '',
      address: json['ADDRESS'] ?? '',
      city: json['CITY'] ?? '',
      district: json['DISTRICT'] ?? '',
      state: json['STATE'] ?? '',
      micr: json['MICR'] ?? '',
      bankCode: json['BANKCODE'] ?? '',
    );
  }
}