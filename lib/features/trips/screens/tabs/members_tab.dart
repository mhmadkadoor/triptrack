import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trip_provider.dart';
import '../../../roster/models/trip_member.dart';
import '../../../auth/providers/auth_provider.dart'; // Add auth provider

class MembersTab extends ConsumerWidget {
  final String tripId;

  const MembersTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the trip via a provider (assuming tripProvider(id) exists or we fetch it)
    // Actually the previous code used tripAsync directly.
    // Let's assume tripProvider(id) is valid.
    final tripAsync = ref.watch(tripProvider(tripId));
    final membersAsync = ref.watch(tripMembersProvider(tripId));
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Avoid double background
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
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
              data: (trip) => Card(
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Trip Invitation Code',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        trip.inviteCode ?? 'Generating...',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              letterSpacing: 4,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share this code to let others join.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Error: $e'),
              ),
            ),
          ),

          // Members List Header
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

              // Determine if current user is a leader
              final myMemberRecord = members.firstWhere(
                (m) => m.userId == currentUser?.id,
                orElse: () =>
                    members.first, // Fallback (shouldn't happen if trusted)
              );

              // Only check role if we actually found ourselves in the list
              final amILeader = members.any(
                (m) => m.userId == currentUser?.id && m.role == TripRole.leader,
              );

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final member = members[index];
                  final profile = member.profile;
                  final name = profile?.displayName ?? 'Unknown User';
                  // Handle possibly null/empty avatar or name
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

                  final isMe = member.userId == currentUser?.id;
                  final isLeader = member.role == TripRole.leader;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          profile?.avatarUrl != null &&
                              profile!.avatarUrl!.isNotEmpty
                          ? NetworkImage(profile.avatarUrl!)
                          : null,
                      child:
                          (profile?.avatarUrl == null ||
                              profile!.avatarUrl!.isEmpty)
                          ? Text(initial)
                          : null,
                    ),
                    title: Text(name + (isMe ? ' (You)' : '')),
                    subtitle: Text(member.role.name.toUpperCase()),
                    trailing: amILeader
                        ? PopupMenuButton<TripRole>(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Change Role',
                            onSelected: (newRole) async {
                              if (newRole == member.role) return;

                              // Check self-demotion
                              if (isMe &&
                                  member.role == TripRole.leader &&
                                  newRole != TripRole.leader) {
                                // Ensure there is at least one other leader?
                                // For now, just show a warning or allow it.
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Demote yourself?'),
                                    content: const Text(
                                      'You are about to remove your Leader status. You might lose administrative access.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(c, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                              }

                              try {
                                await ref
                                    .read(tripRepositoryProvider)
                                    .updateMemberRole(
                                      tripId: tripId,
                                      memberId: member.userId,
                                      newRole: newRole,
                                    );
                                ref.invalidate(tripMembersProvider(tripId));

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Role updated successfully',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) {
                              return TripRole.values.map((role) {
                                return PopupMenuItem(
                                  value: role,
                                  child: Row(
                                    children: [
                                      if (role == member.role)
                                        const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.green,
                                        )
                                      else
                                        const SizedBox(width: 16),
                                      const SizedBox(width: 8),
                                      Text(role.name.toUpperCase()),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          )
                        : (isLeader
                              ? const Chip(label: Text('Leader'))
                              : null), // Show chip for leaders if not editing
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
