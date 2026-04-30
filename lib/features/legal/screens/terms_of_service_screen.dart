import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              '1. Acceptance of Terms',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'By accessing and using TripTrack, you accept and agree to be bound by the terms and provisions of this agreement. If you do not agree to abide by these terms, please do not use this service.',
            ),
            const SizedBox(height: 24),
            Text(
              '2. Description of Service',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'TripTrack is a digital ledger application provided "as is". We offer tools for individuals and groups to track, manage, and settle shared travel expenses. The app facilitates financial tracking but does not process monetary settlements or bank transfers directly.',
            ),
            const SizedBox(height: 24),
            Text(
              '3. User Accounts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'You are responsible for maintaining the confidentiality of your Google account and Supabase credentials used to access TripTrack. We hold no liability for unauthorized access resulting from the sharing or compromise of your own credentials.',
            ),
            const SizedBox(height: 24),
            Text(
              '4. Limitations of Liability',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'TripTrack assumes no responsibility for errors, financial disputes between members, inaccurate expense logging, or potential data loss. The settlement of debts remains entirely the responsibility of the participating trip members.',
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
