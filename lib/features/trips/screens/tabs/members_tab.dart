import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trip_provider.dart';
import '../../../roster/models/trip_member.dart';

class MembersTab extends ConsumerWidget {
  final String tripId;

  const MembersTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripProvider(tripId));
    final membersAsync = ref.watch(tripMembersProvider(tripId));

    return Scaffold(
      backgroundColor: Colors.transparent, // Avoid double background
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement "Invite via Link/Share" logic
          // For now, simple snackbar with code copy
          tripAsync.whenData((trip) {
            if (trip.inviteCode != null) {
              Clipboard.setData(ClipboardData(text: trip.inviteCode!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invite code copied to clipboard'),
                ),
              );
            }
          });
        },
        label: const Text('Invite'),
        icon: const Icon(Icons.person_add),
      ),
      body: CustomScrollView(
        slivers: [
          // Trip Info / Header
          SliverToBoxAdapter(
            child: tripAsync.when(
              data: (trip) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Trip Code',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          trip.inviteCode ?? 'Generating...',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Share this code to let others join.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: LinearProgressIndicator(),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading trip details: $e'),
              ),
            ),
          ),

          // Members List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Members',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),

          membersAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No members found.')),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final member = members[index];
                  final profile = member.profile;
                  final name = profile?.displayName ?? 'Unknown User';
                  final isLeader = member.role == TripRole.leader;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile?.avatarUrl != null
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: profile?.avatarUrl == null
                          ? Text(name.substring(0, 1).toUpperCase())
                          : null,
                    ),
                    title: Text(name),
                    subtitle: Text(member.role.name.toUpperCase()),
                    trailing: isLeader
                        ? const Chip(
                            label: Text('Leader'),
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                  );
                }, childCount: members.length),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (e, st) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error loading members: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
