import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_colors.dart';
import '../../services/weather/weather_service.dart';
import '../../models/weather_model.dart';

/// Weather settings screen for API key configuration
class WeatherSettingsScreen extends StatefulWidget {
  const WeatherSettingsScreen({super.key});

  @override
  State<WeatherSettingsScreen> createState() => _WeatherSettingsScreenState();
}

class _WeatherSettingsScreenState extends State<WeatherSettingsScreen> {
  final _apiKeyController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isTestingApi = false;
  bool _obscureApiKey = true;
  WeatherModel? _testWeather;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  /// Load saved API key
  Future<void> _loadSavedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString('weather_api_key');
      if (savedKey != null && savedKey.isNotEmpty) {
        _apiKeyController.text = savedKey;
        WeatherService.setApiKey(savedKey);
      }
    } catch (e) {
      debugPrint('Error loading API key: $e');
    }
  }

  /// Save API key
  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiKey = _apiKeyController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('weather_api_key', apiKey);
      WeatherService.setApiKey(apiKey);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving API key: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Test API key by fetching weather
  Future<void> _testApiKey() async {
    if (_apiKeyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an API key first';
      });
      return;
    }

    setState(() {
      _isTestingApi = true;
      _errorMessage = null;
      _testWeather = null;
    });

    try {
      final apiKey = _apiKeyController.text.trim();
      WeatherService.setApiKey(apiKey);

      // Test with a known city
      final weather = await WeatherService.getCurrentWeatherByCity('London');
      
      if (weather != null) {
        setState(() {
          _testWeather = weather;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('API key is working! ✅'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'API key test failed. Please check your key.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'API test error: $e';
      });
    } finally {
      setState(() {
        _isTestingApi = false;
      });
    }
  }

  /// Clear API key
  Future<void> _clearApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('weather_api_key');
      await WeatherService.clearCache();
      
      _apiKeyController.clear();
      WeatherService.setApiKey('');
      
      setState(() {
        _testWeather = null;
        _errorMessage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API key cleared'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error clearing API key: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),

              // API Key Input
              _buildApiKeyInput(),
              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(),
              const SizedBox(height: 24),

              // Test Results
              if (_testWeather != null) _buildTestResults(),
              if (_errorMessage != null) _buildErrorMessage(),
              
              const SizedBox(height: 24),

              // Instructions
              _buildInstructions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Real-Time Weather',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Configure your OpenWeatherMap API key to get real-time weather data based on your location.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.info,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: ${WeatherService.apiKeyStatus}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyInput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'API Key',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                hintText: 'Enter your OpenWeatherMap API key',
                prefixIcon: const Icon(Icons.key),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureApiKey = !_obscureApiKey;
                        });
                      },
                      icon: Icon(
                        _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _apiKeyController.text = data!.text!;
                        }
                      },
                      icon: const Icon(Icons.paste),
                      tooltip: 'Paste from clipboard',
                    ),
                  ],
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an API key';
                }
                if (value.trim().length < 10) {
                  return 'API key seems too short';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _saveApiKey,
            icon: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isTestingApi ? null : _testApiKey,
            icon: _isTestingApi 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_sync),
            label: Text(_isTestingApi ? 'Testing...' : 'Test'),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _clearApiKey,
          icon: const Icon(Icons.clear),
          tooltip: 'Clear API key',
          color: AppColors.error,
        ),
      ],
    );
  }

  Widget _buildTestResults() {
    return Card(
      color: AppColors.success.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'API Test Successful',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Test Location: ${_testWeather!.location}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Temperature: ${_testWeather!.temperatureString}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Condition: ${_testWeather!.condition}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Description: ${_testWeather!.description}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How to get your API key:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(
              '1.',
              'Visit openweathermap.org/api',
            ),
            _buildInstructionStep(
              '2.',
              'Sign up for a free account',
            ),
            _buildInstructionStep(
              '3.',
              'Go to API keys section',
            ),
            _buildInstructionStep(
              '4.',
              'Copy your API key and paste it above',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: It may take a few minutes for new API keys to become active.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
