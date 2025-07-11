import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

class SubjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectDetailsScreen({super.key, required this.subject});

  @override
  SubjectDetailsScreenState createState() => SubjectDetailsScreenState();
}

class SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  static final _logger = Logger('SubjectDetailsScreen');

  @override
  void initState() {
    super.initState();
    _logger.info('Viewing details for subject: ${widget.subject['subject_name']}');
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

  @override
  Widget build(BuildContext context) {
    final subject = widget.subject;
    final subjectColor = _getSubjectColor(subject['subject_code']);

    return Scaffold(
      appBar: AppBar(
        title: Text(subject['subject_name'] ?? 'Subject Details'),
        backgroundColor: subjectColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.0),
                  gradient: LinearGradient(
                    colors: [
                      subjectColor.withValues(alpha: 0.1),
                      subjectColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: subjectColor,
                      radius: 30,
                      child: Text(
                        subject['subject_code']?.substring(0, 2) ?? '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject['subject_name'] ?? 'Unknown Subject',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${subject['subject_code'] ?? 'N/A'}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: subject['is_active'] == true
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.red.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              subject['is_active'] == true ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 12,
                                color: subject['is_active'] == true
                                    ? Colors.green[700]
                                    : Colors.red[700],
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
            ),
            
            const SizedBox(height: 24),
            
            // Study Options
            const Text(
              'Study Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Practice Tests Card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  child: const Icon(Icons.quiz, color: Colors.blue),
                ),
                title: const Text('Practice Tests'),
                subtitle: const Text('Take practice tests to assess your knowledge'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _logger.info('Practice Tests tapped for ${subject['subject_name']}');
                  // TODO: Navigate to practice tests
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Practice tests coming soon!'),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Study Materials Card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  child: const Icon(Icons.book, color: Colors.green),
                ),
                title: const Text('Study Materials'),
                subtitle: const Text('Access notes, formulas, and concepts'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _logger.info('Study Materials tapped for ${subject['subject_name']}');
                  // TODO: Navigate to study materials
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Study materials coming soon!'),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Previous Year Questions Card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.1),
                  child: const Icon(Icons.history, color: Colors.orange),
                ),
                title: const Text('Previous Year Questions'),
                subtitle: const Text('Practice with real NEET questions'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _logger.info('Previous Year Questions tapped for ${subject['subject_name']}');
                  // TODO: Navigate to previous year questions
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Previous year questions coming soon!'),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Mock Tests Card
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  child: const Icon(Icons.timer, color: Colors.purple),
                ),
                title: const Text('Mock Tests'),
                subtitle: const Text('Full-length timed practice tests'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  _logger.info('Mock Tests tapped for ${subject['subject_name']}');
                  // TODO: Navigate to mock tests
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mock tests coming soon!'),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Subject Information
            const Text(
              'Subject Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Subject ID', subject['subject_id']?.toString() ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Subject Code', subject['subject_code'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Status', subject['is_active'] == true ? 'Active' : 'Inactive'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        const Text(': '),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}