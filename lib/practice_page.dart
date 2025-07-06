import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  PracticePageState createState() => PracticePageState();
}

class PracticePageState extends State<PracticePage> {
  List<dynamic> subjects = [];
  bool isLoading = true;
  String? errorMessage;
  bool isFromCache = false;
  int retryCount = 0;
  final maxRetries = 5;

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
          
          print('Retrying in ${totalDelay}ms... (attempt ${attempt + 1}/$maxRetries)');
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
        print('Attempt ${attempt + 1} failed: $e');
        if (attempt == maxRetries - 1) {
          _useFallbackData();
        }
      }
    }
  }

  Future<bool> _attemptApiCall() async {
    final url = Uri.parse('https://www.dev.smarterneet.com/api/subjects');
    
    try {
      // Generate unique client ID for this session
      final clientId = 'flutter-${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'SmarterNEET-Mobile/1.0 (Flutter; ${Platform.operatingSystem})',
          'X-Client-ID': clientId,
          'Cache-Control': 'max-age=300', // Accept 5-minute cached responses
          'Accept-Encoding': 'gzip, deflate',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (!contentType.contains('application/json')) {
          print('Invalid content type: $contentType');
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
            
            print('Successfully loaded ${subjects.length} subjects (source: ${decodedData['source']})');
            return true;
          } else {
            print('Invalid response format');
            return false;
          }
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          return false;
        }
      } else if (response.statusCode == 429) {
        // Rate limited - check for Retry-After header
        final retryAfter = response.headers['retry-after'];
        if (retryAfter != null) {
          final waitTime = int.tryParse(retryAfter) ?? 5;
          print('Rate limited. Server says wait ${waitTime}s');
          await Future.delayed(Duration(seconds: waitTime));
        }
        return false;
      } else if (response.statusCode >= 500) {
        // Server error - worth retrying
        print('Server error: ${response.statusCode}');
        return false;
      } else {
        // Client error (4xx) - probably not worth retrying except 429
        print('Client error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Network error: $e');
      return false;
    }
  }

  void _useFallbackData() {
    print('Using fallback data');
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
                                print('Selected subject: ${subject['subject_name']}');
                                // TODO: Navigate to subject details
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