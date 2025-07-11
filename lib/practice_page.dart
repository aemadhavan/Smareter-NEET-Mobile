import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:myapp/subject_details_screen.dart';
import 'package:myapp/config.dart';
import 'package:myapp/network_debug.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  PracticePageState createState() => PracticePageState();
}

class PracticePageState extends State<PracticePage> {
  static final _logger = Logger('PracticePage');
  List<dynamic> subjects = [];
  bool isLoading = true;
  String? errorMessage;
  bool isFromCache = false;
  int retryCount = 0;
  final maxRetries = AppConfig.maxRetries;

  // Static fallback data for emergency cases
  final List<Map<String, dynamic>> fallbackSubjects = [
    {
      "subject_id": 1,
      "subject_name": "Physics",
      "subject_code": "PHY",
      "is_active": true
    },
    {
      "subject_id": 2,
      "subject_name": "Chemistry",
      "subject_code": "CHEM",
      "is_active": true
    },
    {
      "subject_id": 3,
      "subject_name": "Botany",
      "subject_code": "BOT",
      "is_active": true
    },
    {
      "subject_id": 4,
      "subject_name": "Zoology",
      "subject_code": "ZOO",
      "is_active": true
    }
  ];

  @override
  void initState() {
    super.initState();
    
    // Log platform information for debugging
    if (AppConfig.enableApiLogging) {
      NetworkDebug.logPlatformInfo();
    }
    
    fetchSubjectsWithAdvancedRetry();
  }

  Future<void> fetchSubjectsWithAdvancedRetry() async {
    final baseDelay = 1000; // 1 second base delay
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        setState(() {
          isLoading = true;
          errorMessage = null;
          retryCount = attempt;
        });

        if (attempt > 0) {
          // Exponential backoff with jitter
          final delay = baseDelay * pow(2, attempt - 1).toInt();
          final jitter = Random().nextInt(1000); // Add randomness
          final totalDelay = delay + jitter;
          
          _logger.info('Retrying in ${totalDelay}ms... (attempt ${attempt + 1}/$maxRetries)');
          await Future.delayed(Duration(milliseconds: totalDelay));
        }

        final success = await _attemptApiCall();
        if (success) {
          setState(() {
            retryCount = 0;
          });
          return; // Success, exit retry loop
        }
        
        // If this was the last attempt, use fallback
        if (attempt == maxRetries - 1) {
          _useFallbackData();
        }
        
      } catch (e) {
        _logger.warning('Attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          _useFallbackData();
        }
      }
    }
  }

  Future<bool> _attemptApiCall() async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}${AppConfig.subjectsEndpoint}');
    
    try {
      // Generate unique client ID for this session
      final clientId = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
      
      // Build headers for mobile API requests (backend bypasses auth for mobile)
      final headers = <String, String>{
        'User-Agent': 'SmarterNEET-Mobile/1.0.0 (Mobile)',
        'Accept': 'application/json',
        'X-Client-ID': clientId,
        'x-vercel-protection-bypass': AppConfig.vercelBypassSecret,
        'Cache-Control': 'max-age=300',
        'Accept-Encoding': 'gzip, deflate',
      };
      
      _logger.info('Using mobile-optimized headers with Vercel bypass');
      
      final response = await http.get(url, headers: headers)
          .timeout(AppConfig.requestTimeout);

      _logger.info('API Response: ${response.statusCode}');
      
      if (AppConfig.enableApiLogging) {
        _logger.info('Response headers: ${response.headers}');
        _logger.info('Content-Length: ${response.headers['content-length'] ?? 'unknown'}');
      }
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        
        // Check for security checkpoint (HTML response)
        if (contentType.contains('text/html')) {
          _logger.warning('Security checkpoint detected - HTML response received');
          return false;
        }
        
        if (!contentType.contains('application/json')) {
          _logger.warning('Invalid content type: $contentType');
          return false;
        }

        try {
          final decodedData = json.decode(response.body);
          
          if (decodedData is Map<String, dynamic> && 
              decodedData.containsKey('data') && 
              decodedData['data'] is List) {
            
            setState(() {
              subjects = decodedData['data'];
              isLoading = false;
              errorMessage = null;
              isFromCache = decodedData['source'] == 'cache';
            });
            
            _logger.info('Successfully loaded ${subjects.length} subjects (source: ${decodedData['source']})');
            return true;
          } else {
            _logger.warning('Invalid response format');
            return false;
          }
        } catch (jsonError) {
          _logger.severe('JSON parsing error: $jsonError');
          _logger.severe('Raw response body: ${response.body.substring(0, 500)}');
          return false;
        }
      } else if (response.statusCode == 429) {
        // Vercel Security Checkpoint detected
        _logger.warning('Vercel Security Checkpoint detected (429). Implementing bypass strategy...');
        
        final retryAfter = response.headers['retry-after'];
        final waitTime = retryAfter != null ? int.tryParse(retryAfter) ?? 10 : 10;
        
        _logger.info('Waiting ${waitTime}s before retry with enhanced headers...');
        await Future.delayed(Duration(seconds: waitTime));
        return false;
      } else if (response.statusCode >= 500) {
        // Server error - worth retrying
        _logger.warning('Server error: ${response.statusCode}');
        return false;
      } else {
        // Client error (4xx) - log details for debugging
        _logger.warning('Client error: ${response.statusCode}');
        _logger.warning('Error response body: ${response.body}');
        _logger.warning('Error response headers: ${response.headers}');
        return false;
      }
    } catch (e) {
      _logger.severe('Network error: $e');
      
      // Log specific error types for better debugging
      if (e.toString().contains('SocketException')) {
        _logger.severe('Network connectivity issue - check internet connection');
      } else if (e.toString().contains('TimeoutException')) {
        _logger.severe('Request timeout - server may be slow or unreachable');
      } else if (e.toString().contains('HandshakeException')) {
        _logger.severe('SSL/TLS handshake failed - check certificate configuration');
      } else if (e.toString().contains('HttpException')) {
        _logger.severe('HTTP protocol error - check API endpoint and headers');
      }
      
      return false;
    }
  }

  void _useFallbackData() {
    _logger.info('Using fallback data');
    setState(() {
      subjects = fallbackSubjects;
      isLoading = false;
      errorMessage = 'Using offline data. Check your connection and refresh to get latest subjects.';
      isFromCache = false;
    });
  }

  Future<void> refresh() async {
    retryCount = 0;
    await fetchSubjectsWithAdvancedRetry();
  }
  
  /// Run comprehensive network diagnostic for troubleshooting
  Future<void> _runNetworkDiagnostic() async {
    _logger.info('Running network diagnostic...');
    
    // Build the same headers used for API requests
    final headers = <String, String>{
      'User-Agent': AppConfig.userAgent,
      'Accept': 'application/json, text/plain, */*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate, br',
      'Content-Type': 'application/json',
      'X-Client-ID': 'flutter-diagnostic-${DateTime.now().millisecondsSinceEpoch}',
      'X-Requested-With': 'XMLHttpRequest',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
    };
    
    if (AppConfig.vercelBypassSecret.isNotEmpty) {
      headers['x-vercel-protection-bypass'] = AppConfig.vercelBypassSecret;
      headers['x-vercel-set-bypass-cookie'] = 'true';
    }
    
    final apiUrl = '${AppConfig.apiBaseUrl}${AppConfig.subjectsEndpoint}';
    
    try {
      final diagnostic = await NetworkDebug.runFullDiagnostic(apiUrl, headers);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              diagnostic['apiTest']['success'] 
                  ? 'Network diagnostic: All tests passed ✅'
                  : 'Network diagnostic: Issues detected ❌ Check logs'
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Network diagnostic failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network diagnostic failed - check logs'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subjects'),
        actions: [
          if (retryCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  'Retry ${retryCount + 1}/$maxRetries',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          if (isFromCache)
            const Icon(Icons.cloud_off, color: Colors.orange),
          if (AppConfig.enableApiLogging)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: isLoading ? null : _runNetworkDiagnostic,
              tooltip: 'Run Network Diagnostic',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar for cache/offline/retry states
          if (isFromCache || errorMessage != null || retryCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: isFromCache 
                  ? Colors.orange.shade100 
                  : errorMessage != null 
                      ? Colors.red.shade100 
                      : Colors.blue.shade100,
              child: Row(
                children: [
                  Icon(
                    isFromCache 
                        ? Icons.offline_bolt 
                        : errorMessage != null 
                            ? Icons.warning 
                            : Icons.refresh,
                    color: isFromCache 
                        ? Colors.orange 
                        : errorMessage != null 
                            ? Colors.red 
                            : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isFromCache 
                          ? 'Showing cached data'
                          : errorMessage ?? 
                            'Retrying connection...',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (!isLoading)
                    TextButton(
                      onPressed: refresh,
                      child: const Text('Refresh'),
                    ),
                ],
              ),
            ),
          
          // Main content
          Expanded(
            child: isLoading && subjects.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading subjects...'),
                      ],
                    ),
                  )
                : subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No subjects available',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Please check your connection and try again.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: refresh,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getSubjectColor(subject['subject_code']),
                                child: Text(
                                  subject['subject_code']?.substring(0, 2) ?? '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              title: Text(
                                subject['subject_name'] ?? 'Unknown Subject',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                'Code: ${subject['subject_code'] ?? 'N/A'}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                _logger.info('Selected subject: ${subject['subject_name']}');
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubjectDetailsScreen(
                                      subject: subject,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getSubjectColor(String? code) {
    switch (code) {
      case 'PHY':
        return Colors.blue;
      case 'CHEM':
        return Colors.green;
      case 'BOT':
        return Colors.orange;
      case 'ZOO':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}