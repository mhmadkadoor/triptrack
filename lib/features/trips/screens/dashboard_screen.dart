import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tripsAsync = ref.watch(userTripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TripTrack'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return _buildEmptyState(
              context,
              user?.userMetadata?['full_name'] ?? 'Tracker',
            );
          }

          final activeTrips = trips
              .where((t) => t.phase == TripPhase.active)
              .toList();
          final pastTrips = trips
              .where((t) => t.phase != TripPhase.active)
              .toList();

          return RefreshIndicator(
            onRefresh: () => ref.refresh(userTripsProvider.future),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (activeTrips.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'ACTIVE TRIPS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...activeTrips.map((trip) => _TripListTile(trip: trip)),
                ],
                if (pastTrips.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'PAST TRIPS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...pastTrips.map((trip) => _TripListTile(trip: trip)),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('Error loading trips: $error')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'join',
            onPressed: () => _showJoinTripDialog(context, ref),
            label: const Text('Join'),
            icon: const Icon(Icons.group_add),
            backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => context.push('/trips/create'),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _showJoinTripDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    // We use a simple dialog for input
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Join a Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the 6-character invite code shared by the trip leader.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Invite Code',
                border: OutlineInputBorder(),
                hintText: 'e.g. A8X2B9',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid code length. Must be 6 characters.'),
                  ),
                );
                return;
              }

              // Show loading? Ideally we'd use a state provider or just close and show snackbar progress.
              // For simplicity:
              Navigator.of(dialogContext).pop(); // Close dialog first

              try {
                final scaffold = ScaffoldMessenger.of(context);
                scaffold.showSnackBar(
                  const SnackBar(content: Text('Joining trip...')),
                );

                await Future.delayed(
                  const Duration(milliseconds: 300),
                ); // Let Supabase commit
                await ref.read(tripRepositoryProvider).joinTrip(code);
                ref.invalidate(userTripsProvider);

                scaffold.hideCurrentSnackBar();
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('Successfully joined trip!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceAll("Exception: ", "")}',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (_) {
                  // Fallback if context is invalid
                  debugPrint('Failed to show error snackbar: $e');
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String name) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Welcome, $name!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no active trips. Create one to start tracking expenses with friends.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripListTile extends StatelessWidget {
  final Trip trip;

  const _TripListTile({required this.trip});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(Icons.flight, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        trip.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        'Created ${dateFormat.format(trip.createdAt)} • ${trip.baseCurrency}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        context.push('/trip/${trip.id}');
      },
    );
  }
}
