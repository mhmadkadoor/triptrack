import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../ledger/models/expense.dart';
import '../../trips/providers/trip_provider.dart';
import '../models/trip_member.dart';

class MemberDetailScreen extends ConsumerWidget {
  final String tripId;
  final TripMember member;

  const MemberDetailScreen({
    super.key,
    required this.tripId,
    required this.member,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));

    final iban = member.profile?.iban;
    final hasIban = iban != null && iban.isNotEmpty;
    final currencyFormat = NumberFormat.simpleCurrency();

    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    UserAvatar(
                      avatarUrl: member.profile?.avatarUrl,
                      // userId: member.userId, // UserAvatar doesn't have userId
                      displayName: member.profile?.displayName ?? 'User',
                      radius: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      member.profile?.displayName ?? 'Unknown User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Chip(
                      label: Text(member.role.name.toUpperCase()),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                    if (hasIban) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IBAN',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(context).hintColor,
                                        ),
                                  ),
                                  Text(
                                    iban,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: iban));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('IBAN copied to clipboard'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 20),
                              tooltip: 'Copy IBAN',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(),
              // Expenses Section
              Expanded(
                child: expensesAsync.when(
                  data: (expenses) {
                    final memberExpenses = expenses
                        .where((e) => e.paidBy == member.userId)
                        .toList();

                    if (memberExpenses.isEmpty) {
                      return Center(
                        child: Text(
                          '${member.profile?.displayName ?? 'User'} has not paid for anything yet.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: memberExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = memberExpenses[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: const Icon(Icons.receipt_long, size: 20),
                          ),
                          title: Text(expense.description),
                          subtitle: Text(
                            DateFormat.yMMMd().format(expense.createdAt),
                          ),
                          trailing: Text(
                            currencyFormat.format(expense.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
