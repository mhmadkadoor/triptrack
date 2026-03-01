import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trips/models/trip.dart'; // import TripPhase
import '../../trips/providers/trip_provider.dart';
import '../../trips/providers/trip_repository.dart';
import '../providers/balances_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../roster/models/trip_member.dart'; // import TripRole

import '../../ledger/models/settlement.dart';

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
      body: tripAsync.when(
        data: (trip) {
          final isFinished = trip.phase == TripPhase.finished;
          final isSettled = trip.phase == TripPhase.settled;
          final showSettlements = isFinished || isSettled;

          // Banner Logic
          final color = isSettled
              ? Colors.purple.shade100
              : (isFinished ? Colors.green.shade100 : Colors.orange.shade100);
          final iconColor = isSettled
              ? Colors.purple.shade800
              : (isFinished ? Colors.green.shade800 : Colors.orange.shade800);
          final textColor = isSettled
              ? Colors.purple.shade900
              : (isFinished ? Colors.green.shade900 : Colors.orange.shade900);
          final icon = isSettled
              ? Icons.celebration
              : (isFinished
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded);
          final text = isSettled
              ? '🎉 Trip Settled! All debts are cleared.'
              : (isFinished
                    ? 'Step 2: Math is locked. Settle up with external payments.'
                    : 'Trip in progress: Balances are estimates and will change.');

          return Column(
            children: [
              // Warning Banner
              Container(
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
              ),

              // Content Area
              Expanded(
                child: membersAsync.when(
                  data: (members) {
                    if (members.isEmpty) {
                      return const Center(child: Text('No members found.'));
                    }

                    // Sort members by balance
                    final sortedMembers = List.of(members);
                    sortedMembers.sort((a, b) {
                      final balanceA = balances[a.userId] ?? 0.0;
                      final balanceB = balances[b.userId] ?? 0.0;
                      return balanceB.compareTo(balanceA);
                    });

                    // Build user map for easy lookup in settlements
                    final memberMap = {for (var m in members) m.userId: m};

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text(
                          'Net Balances',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sortedMembers.map((member) {
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
                            balanceColor = Colors.green.shade700;
                            balanceText = '+${balance.toStringAsFixed(2)}';
                          } else if (balance < -0.005) {
                            balanceColor = Colors.red.shade700;
                            balanceText = balance.toStringAsFixed(2);
                          } else {
                            balanceColor = Colors.grey;
                            balanceText = '0.00';
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
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
                        }),

                        // How to Settle Up Section
                        if (showSettlements) ...[
                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 16),
                          const Text(
                            'How to Settle Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Consumer(
                            builder: (context, ref, _) {
                              final settlementsAsync = ref.watch(
                                savedSettlementsProvider(tripId),
                              );

                              return settlementsAsync.when(
                                data: (settlements) {
                                  if (settlements.isEmpty) {
                                    return const Text('All settled up!');
                                  }

                                  return Column(
                                    children: settlements.map((settlement) {
                                      final fromMember =
                                          memberMap[settlement.fromUserId];
                                      final toMember =
                                          memberMap[settlement.toUserId];

                                      final fromName =
                                          fromMember?.profile?.displayName ??
                                          'User';
                                      final toName =
                                          toMember?.profile?.displayName ??
                                          'User';
                                      final amount = settlement.amount;
                                      final status = settlement.status;

                                      final isPayer =
                                          settlement.fromUserId ==
                                          currentUser?.id;
                                      final isPayee =
                                          settlement.toUserId ==
                                          currentUser?.id;

                                      Widget? actionButton;
                                      String statusText = '';
                                      Color statusColor = Colors.grey;

                                      if (status == SettlementStatus.pending) {
                                        statusText = 'Pending';
                                        if (isPayer) {
                                          actionButton = TextButton(
                                            onPressed: () async {
                                              await ref
                                                  .read(tripRepositoryProvider)
                                                  .markSettlementSent(
                                                    settlement.id!,
                                                  );
                                            },
                                            child: const Text('Mark as Paid'),
                                          );
                                        }
                                      } else if (status ==
                                          SettlementStatus.sent) {
                                        statusText = 'Payment Sent';
                                        statusColor = Colors.blue;
                                        if (isPayee) {
                                          actionButton = TextButton(
                                            onPressed: () async {
                                              await ref
                                                  .read(tripRepositoryProvider)
                                                  .confirmSettlementReceived(
                                                    settlement.id!,
                                                  );
                                            },
                                            child: const Text(
                                              'Confirm Receipt',
                                            ),
                                          );
                                        }
                                      } else if (status ==
                                          SettlementStatus.confirmed) {
                                        statusText = 'Settled';
                                        statusColor = Colors.green;
                                      }

                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 8.0,
                                        ),
                                        child: ListTile(
                                          leading: const Icon(
                                            Icons.monetization_on,
                                            color: Colors.green,
                                          ),
                                          title: RichText(
                                            text: TextSpan(
                                              style: DefaultTextStyle.of(
                                                context,
                                              ).style,
                                              children: [
                                                TextSpan(
                                                  text: fromName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const TextSpan(text: ' owes '),
                                                TextSpan(
                                                  text: toName,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              if (status ==
                                                  SettlementStatus.confirmed)
                                                const Icon(
                                                  Icons.check_circle,
                                                  size: 16,
                                                  color: Colors.green,
                                                ),
                                              if (status ==
                                                  SettlementStatus.confirmed)
                                                const SizedBox(width: 4),
                                              Text(
                                                statusText,
                                                style: TextStyle(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '\$${amount.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              if (actionButton != null) ...[
                                                const SizedBox(width: 8),
                                                actionButton,
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, st) => Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Error loading settlements: $e',
                                    style: TextStyle(
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],

                        // Settle Trip Button
                        if (isFinished && !isSettled) ...[
                          const SizedBox(height: 32),
                          Consumer(
                            builder: (context, ref, _) {
                              final settlementsAsync = ref.watch(
                                savedSettlementsProvider(tripId),
                              );
                              final allSettled = settlementsAsync.when(
                                data: (s) => s.every(
                                  (settlement) =>
                                      settlement.status ==
                                      SettlementStatus.confirmed,
                                ),
                                loading: () => false,
                                error: (_, __) => false,
                              );

                              final myMember = members.firstWhere(
                                (m) => m.userId == currentUser?.id,
                                orElse: () => TripMember.empty(),
                              );
                              final isLeader = myMember.role == TripRole.leader;

                              if (!isLeader) return const SizedBox.shrink();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 32.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: allSettled
                                          ? Colors.purple
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                    ),
                                    onPressed: !allSettled
                                        ? null
                                        : () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (c) => AlertDialog(
                                                title: const Text(
                                                  'Confirm Settlement',
                                                ),
                                                content: const Text(
                                                  'Are you sure all external payments have happened? This will mark the trip as fully settled and archive it.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, true),
                                                    child: const Text(
                                                      'Confirm & Close',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              try {
                                                await ref
                                                    .read(
                                                      tripRepositoryProvider,
                                                    )
                                                    .settleTrip(tripId);
                                                ref.invalidate(
                                                  tripProvider(tripId),
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Trip settled successfully!',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Error: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                    child: const Text(
                                      'Confirm All Debts Paid & Close Trip',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
