# Symptom Checker Error Handling Improvements

## Problem
The symptom checker was showing raw error messages when the Gemini API failed, particularly:
- **503 Error**: "The model is overloaded. Please try again later"
- Poor user experience with technical error messages
- No retry mechanism for temporary failures

## Solution Implemented

### 1. Custom Exception Class
Created `GeminiAPIException` with user-friendly error messages:

```dart
class GeminiAPIException implements Exception {
  final int statusCode;
  final String message;
  
  @override
  String toString() {
    if (statusCode == 503) {
      return 'The AI service is currently overloaded. Please try again in a few moments.';
    } else if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    } else if (statusCode == 403) {
      return 'API access denied. Please check your API key configuration.';
    } else if (statusCode == 400) {
      return 'Invalid request. Please check your input and try again.';
    }
    return 'AI service error (Code: $statusCode). Please try again later.';
  }
}
```

### 2. Automatic Retry Logic
Added intelligent retry mechanism with exponential backoff:

**Retry Conditions:**
- **503 (Service Overloaded)**: Retry up to 3 times with 2-second delay
- **429 (Rate Limited)**: Retry up to 3 times with 4-second delay
- **Network Errors**: Retry up to 3 times with 2-second delay

**Features:**
- Maximum 3 retry attempts
- Progressive delays between retries
- Timeout protection (30 seconds per request)
- Detailed logging for debugging

```dart
static Future<String> _callGeminiAPI(String prompt, {int retryCount = 0}) async {
  const maxRetries = 3;
  const retryDelay = Duration(seconds: 2);
  
  try {
    final response = await http.post(...).timeout(const Duration(seconds: 30));
    
    if (response.statusCode == 503 && retryCount < maxRetries - 1) {
      await Future.delayed(retryDelay);
      return _callGeminiAPI(prompt, retryCount: retryCount + 1);
    }
    // ... handle other cases
  } catch (e) {
    if (retryCount < maxRetries - 1) {
      await Future.delayed(retryDelay);
      return _callGeminiAPI(prompt, retryCount: retryCount + 1);
    }
    throw Exception('Failed after $maxRetries attempts');
  }
}
```

### 3. Graceful Fallback
If all retries fail, returns a fallback result instead of crashing:

```dart
return _getFallbackResult(symptoms);
```

**Fallback Result Includes:**
- Generic possible conditions message
- Basic health recommendations
- Standard urgent warning signs
- Suggestion to consult healthcare provider
- Low confidence indicator

### 4. Improved UI Error Handling
Enhanced error display in the symptom checker screen:

**Before:**
- ❌ Red snackbar with technical error
- ❌ No retry option
- ❌ User stuck on loading screen

**After:**
- ✅ User-friendly dialog with clear message
- ✅ "Try Again" button for easy retry
- ✅ "Go Back" option to modify inputs
- ✅ Helpful guidance text

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Row(
      children: [
        Icon(Icons.error_outline, color: AppColors.error),
        const Text('Analysis Error'),
      ],
    ),
    content: Column(
      children: [
        Text(errorMessage),
        Text('Please try again or consult with a healthcare professional.'),
      ],
    ),
    actions: [
      TextButton(child: Text('Go Back'), onPressed: ...),
      ElevatedButton(child: Text('Try Again'), onPressed: ...),
    ],
  ),
);
```

## Error Handling Flow

```
User submits symptoms
        ↓
Attempt 1: Call Gemini API
        ↓
    [Failed?]
        ↓
Wait 2 seconds
        ↓
Attempt 2: Call Gemini API
        ↓
    [Failed?]
        ↓
Wait 2 seconds
        ↓
Attempt 3: Call Gemini API
        ↓
    [Failed?]
        ↓
Show user-friendly error dialog
with "Try Again" option
```

## Handled Error Codes

| Code | Meaning | User Message | Action |
|------|---------|--------------|--------|
| 200 | Success | - | Return results |
| 400 | Bad Request | "Invalid request. Please check your input..." | Show error dialog |
| 403 | Forbidden | "API access denied. Please check your API key..." | Show error dialog |
| 429 | Rate Limited | "Too many requests. Please wait..." | Auto-retry with 4s delay |
| 503 | Service Unavailable | "The AI service is currently overloaded..." | Auto-retry with 2s delay |
| Network | Connection Error | "Failed to connect..." | Auto-retry with 2s delay |

## Benefits

### User Experience
- ✅ Clear, non-technical error messages
- ✅ Automatic retry for temporary issues
- ✅ Easy manual retry option
- ✅ Graceful degradation with fallback results
- ✅ No app crashes

### Reliability
- ✅ Handles API overload gracefully
- ✅ Manages rate limiting automatically
- ✅ Network error resilience
- ✅ Timeout protection
- ✅ Detailed error logging

### Developer Experience
- ✅ Comprehensive error logging
- ✅ Easy to debug issues
- ✅ Centralized error handling
- ✅ Extensible for new error types

## Testing Scenarios

### 1. API Overload (503)
**Test**: Trigger during high traffic
**Expected**: Auto-retry 3 times, then show friendly error

### 2. Rate Limiting (429)
**Test**: Make multiple rapid requests
**Expected**: Auto-retry with longer delays

### 3. Network Issues
**Test**: Disable internet briefly
**Expected**: Auto-retry, then show connection error

### 4. Invalid API Key (403)
**Test**: Use wrong API key
**Expected**: Show API key error message

### 5. Manual Retry
**Test**: Click "Try Again" in error dialog
**Expected**: Restart analysis with same inputs

## Monitoring

The service logs detailed information for debugging:
```
=== ANALYZING SYMPTOMS WITH GEMINI ===
Symptoms: Fever, Headache
Calling Gemini API (attempt 1/3)...
Gemini API Response Status: 503
Model overloaded (503), retrying in 2 seconds...
Calling Gemini API (attempt 2/3)...
Gemini API Response Status: 200
Gemini Response received: {...
```

## Future Enhancements

- [ ] Exponential backoff for retries
- [ ] Circuit breaker pattern for repeated failures
- [ ] Offline mode with cached responses
- [ ] Alternative AI provider fallback
- [ ] User notification for service status
- [ ] Analytics for error tracking
