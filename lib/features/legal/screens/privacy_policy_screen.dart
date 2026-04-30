import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy for TripTrack',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Last Updated: April 2026\n',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              '1. Introduction',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Welcome to TripTrack. We respect your privacy and are committed to protecting your personal data. This Privacy Policy will inform you as to how we look after your personal data when you visit our application and tell you about your privacy rights.',
            ),
            const SizedBox(height: 24),
            Text(
              '2. Information We Collect',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'To provide you with our expense tracking services, TripTrack utilizes third-party authentication providers such as Google OAuth and Supabase. When you authenticate using these services, we collect and store basic profile information. This includes:',
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Your legal name/display name.'),
                  SizedBox(height: 4),
                  Text('• Your email address.'),
                  SizedBox(height: 4),
                  Text('• Your profile picture / avatar.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This data is collected directly from Google and stored securely via Supabase solely for authentication, account identification, and so other members of your trips can identify you. We do not sell your personal data to any third parties.',
            ),
            const SizedBox(height: 24),
            Text(
              '3. How We Use Your Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'We use your data only when the law allows us to, specifically to:\n\n'
              '• Register you as a new user.\n'
              '• Provide account management and secure login capabilities.\n'
              '• Display your identity within group trip ledgers to your friends.\n'
              '• Prevent fraud and ensure platform integrity.',
            ),
            const SizedBox(height: 40),
            Center(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
