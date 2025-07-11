import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'dart:convert';
import 'dart:io';

/// Network debugging utilities for troubleshooting API connectivity issues
class NetworkDebug {
  static final _logger = Logger('NetworkDebug');
  
  /// Test basic network connectivity
  static Future<bool> testConnectivity() async {
    try {
      _logger.info('Testing basic network connectivity...');
      
      // Test Google DNS (8.8.8.8) connectivity
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _logger.info('✅ Internet connectivity: OK');
        return true;
      } else {
        _logger.warning('❌ Internet connectivity: Failed');
        return false;
      }
    } catch (e) {
      _logger.severe('❌ Internet connectivity test failed: $e');
      return false;
    }
  }
  
  /// Test HTTPS connectivity to a known endpoint
  static Future<bool> testHttpsConnectivity() async {
    try {
      _logger.info('Testing HTTPS connectivity...');
      
      final response = await http.get(
        Uri.parse('https://httpbin.org/get'),
        headers: {'User-Agent': 'SmarterNEET-Mobile-Debug/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        _logger.info('✅ HTTPS connectivity: OK');
        return true;
      } else {
        _logger.warning('❌ HTTPS connectivity failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      _logger.severe('❌ HTTPS connectivity test failed: $e');
      return false;
    }
  }
  
  /// Test API endpoint with detailed diagnostics
  static Future<Map<String, dynamic>> testApiEndpoint(String url, Map<String, String> headers) async {
    final result = <String, dynamic>{
      'success': false,
      'statusCode': null,
      'headers': null,
      'body': null,
      'error': null,
      'responseTime': null,
    };
    
    try {
      _logger.info('Testing API endpoint: $url');
      
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      stopwatch.stop();
      
      result['success'] = response.statusCode >= 200 && response.statusCode < 300;
      result['statusCode'] = response.statusCode;
      result['headers'] = response.headers;
      result['responseTime'] = stopwatch.elapsedMilliseconds;
      
      // Log response details
      _logger.info('API Response Status: ${response.statusCode}');
      _logger.info('API Response Time: ${stopwatch.elapsedMilliseconds}ms');
      _logger.info('API Response Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        
        if (contentType.contains('application/json')) {
          try {
            final jsonData = json.decode(response.body);
            result['body'] = jsonData;
            _logger.info('✅ Valid JSON response received');
          } catch (e) {
            result['error'] = 'Invalid JSON: $e';
            result['body'] = response.body.substring(0, 500);
            _logger.warning('❌ Invalid JSON response: $e');
          }
        } else if (contentType.contains('text/html')) {
          result['error'] = 'HTML response received (possible security checkpoint)';
          result['body'] = response.body.substring(0, 500);
          _logger.warning('❌ HTML response received - possible security checkpoint');
        } else {
          result['error'] = 'Unexpected content type: $contentType';
          result['body'] = response.body.substring(0, 500);
          _logger.warning('❌ Unexpected content type: $contentType');
        }
      } else {
        result['error'] = 'HTTP ${response.statusCode}';
        result['body'] = response.body.substring(0, 500);
        _logger.warning('❌ HTTP error ${response.statusCode}');
      }
      
    } catch (e) {
      result['error'] = e.toString();
      _logger.severe('❌ API test failed: $e');
    }
    
    return result;
  }
  
  /// Comprehensive network diagnostic
  static Future<Map<String, dynamic>> runFullDiagnostic(String apiUrl, Map<String, String> headers) async {
    _logger.info('🔍 Starting comprehensive network diagnostic...');
    
    final diagnostic = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'connectivity': await testConnectivity(),
      'httpsConnectivity': await testHttpsConnectivity(),
      'apiTest': await testApiEndpoint(apiUrl, headers),
    };
    
    _logger.info('📊 Network diagnostic complete');
    
    // Summary
    final allTestsPassed = diagnostic['connectivity'] && 
                          diagnostic['httpsConnectivity'] && 
                          diagnostic['apiTest']['success'];
    
    if (allTestsPassed) {
      _logger.info('✅ All network tests passed');
    } else {
      _logger.warning('❌ Some network tests failed - check logs for details');
    }
    
    return diagnostic;
  }
  
  /// Log platform and device information
  static void logPlatformInfo() {
    _logger.info('📱 Platform Information:');
    _logger.info('  - Operating System: ${Platform.operatingSystem}');
    _logger.info('  - OS Version: ${Platform.operatingSystemVersion}');
    _logger.info('  - Dart Version: ${Platform.version}');
    _logger.info('  - Environment: ${Platform.environment['PATH']?.isNotEmpty == true ? 'OK' : 'Limited'}');
  }
}