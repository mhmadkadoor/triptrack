import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trips/models/trip.dart'; // import TripPhase
import '../../trips/providers/trip_provider.dart';
import '../providers/balances_provider.dart';
import '../../auth/providers/auth_provider.dart';

class BalancesTab extends ConsumerWidget {
  final String tripId;

  const BalancesTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We need members to show names/avatars
    final membersAsync = ref.watch(tripMembersProvider(tripId));
    // We need balances map
    final balances = ref.watch(netBalancesProvider(tripId));
    final tripAsync = ref.watch(tripProvider(tripId));

    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Warning Banner
          tripAsync.when(
            data: (trip) {
              final isFinished = trip.phase != TripPhase.active;
              final color = isFinished
                  ? Colors.green.shade100
                  : Colors.orange.shade100;
              final iconColor = isFinished
                  ? Colors.green.shade800
                  : Colors.orange.shade800;
              final textColor = isFinished
                  ? Colors.green.shade900
                  : Colors.orange.shade900;
              final icon = isFinished
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded;
              final text = isFinished
                  ? 'Step 2: Math is locked. Settle up with external payments.'
                  : 'Trip in progress: Balances are estimates and will change.';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                color: color,
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Leaderboard List
          Expanded(
            child: membersAsync.when(
              data: (members) {
                if (members.isEmpty) {
                  return const Center(child: Text('No members found.'));
                }

                // Sort members by balance (highest positive -> lowest negative)
                // Need to create a mutable list or sort on a copy
                final sortedMembers = List.of(members);
                sortedMembers.sort((a, b) {
                  final balanceA = balances[a.userId] ?? 0.0;
                  final balanceB = balances[b.userId] ?? 0.0;
                  return balanceB.compareTo(balanceA); // Descending
                });

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedMembers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final member = sortedMembers[index];
                    final balance = balances[member.userId] ?? 0.0;
                    final isMe = member.userId == currentUser?.id;

                    final profile = member.profile;
                    final name = isMe
                        ? 'You'
                        : (profile?.displayName ?? 'User');
                    final initial = name.isNotEmpty
                        ? name[0].toUpperCase()
                        : '?';

                    Color balanceColor;
                    String balanceText;

                    if (balance > 0.005) {
                      // Threshold for float precision
                      balanceColor = Colors.green.shade700;
                      balanceText = '+${balance.toStringAsFixed(2)}';
                    } else if (balance < -0.005) {
                      balanceColor = Colors.red.shade700;
                      balanceText = balance.toStringAsFixed(
                        2,
                      ); // Includes negative sign
                    } else {
                      balanceColor = Colors.grey;
                      balanceText = '0.00';
                    }

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 4,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey.shade100,
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                      title: Text(
                        name,
                        style: TextStyle(
                          fontWeight: isMe
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        balanceText,
                        style: TextStyle(
                          color: balanceColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
