import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feedback Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.feedback,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Send Feedback',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Help us improve TaskBound by sharing your thoughts, suggestions, or reporting issues.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showFeedbackDialog(context),
                        icon: const Icon(Icons.message),
                        label: const Text('Send Feedback'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQSection(context),

            const SizedBox(height: 24),

            // Contact Section
            Text(
              'Contact Us',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildContactSection(context),

            const SizedBox(height: 24),

            // App Info Section
            _buildAppInfoSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(BuildContext context) {
    final faqs = [
      {
        'question': 'How does the XP system work?',
        'answer': 'You earn XP by completing tasks. Different difficulty levels give different amounts of XP. Easy tasks give 25 XP, Medium tasks give 50 XP, Hard tasks give 100 XP, and Epic tasks give 200 XP.'
      },
      {
        'question': 'What are task notifications?',
        'answer': 'Task notifications remind you about scheduled tasks and help you stay on track with your goals. You can customize which notifications you receive in your notification settings.'
      },
      {
        'question': 'How do I create recurring tasks?',
        'answer': 'When creating a task, select a recurrence pattern like Daily, Weekly, or Workdays. The app will automatically create future instances of your task.'
      },
      {
        'question': 'Can I backup my data?',
        'answer': 'Yes! Go to Settings > Backup & Restore to export your tasks and progress. This helps you keep your data safe and transfer it between devices.'
      },
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: faqs.map((faq) => _buildFAQItem(
          context,
          faq['question']!,
          faq['answer']!,
        )).toList(),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.email, color: Colors.blue),
            ),
            title: const Text('Email Support'),
            subtitle: const Text('Get help via email'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchEmail(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.web, color: Colors.green),
            ),
            title: const Text('Visit Website'),
            subtitle: const Text('Learn more about TaskBound'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchWebsite(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TaskBound',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.1',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A gamified task management app that helps you level up your productivity through XP rewards and achievement systems.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    final emailController = TextEditingController();
    String feedbackType = 'General';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Send Feedback'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Feedback Type'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: feedbackType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['General', 'Bug Report', 'Feature Request', 'UI/UX Feedback']
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )).toList(),
                      onChanged: (value) => setState(() => feedbackType = value!),
                    ),
                    const SizedBox(height: 16),
                    const Text('Your Email (Optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'your.email@example.com',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    const Text('Feedback'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: feedbackController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Tell us what you think...',
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 5,
                      maxLength: 500,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (feedbackController.text.trim().isNotEmpty) {
                      _submitFeedback(
                        context,
                        feedbackType,
                        emailController.text.trim(),
                        feedbackController.text.trim(),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Send'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitFeedback(BuildContext context, String type, String email, String feedback) {
    // In a real app, you would send this to your backend or email service
    // For now, we'll copy it to clipboard and show a success message
    
    final feedbackText = '''
Feedback Type: $type
Email: ${email.isEmpty ? 'Not provided' : email}
Feedback: $feedback
''';

    Clipboard.setData(ClipboardData(text: feedbackText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text('Thank you for your feedback! We\'ll review it soon.'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@dailyxp.app',
      query: 'subject=Daily XP Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchWebsite() async {
    final Uri websiteUri = Uri.parse('https://dailyxp.app');
    
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri);
    }
  }
} 