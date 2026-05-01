import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../trips/models/trip.dart'; // import TripPhase
import '../../trips/providers/trip_provider.dart';
import '../../trips/providers/trip_repository.dart';
import '../../roster/models/trip_member.dart';
import '../models/expense.dart';
import '../providers/balances_provider.dart';
import 'add_expense_screen.dart';
import 'ai_suggestions_sheet.dart';

class ExpensesTab extends ConsumerWidget {
  final String tripId;

  const ExpensesTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));
    final tripAsync = ref.watch(tripProvider(tripId));
    final membersAsync = ref.watch(tripMembersProvider(tripId));

    // Get current user securely as requested
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // Safely calculate isLeader using collection's firstWhereOrNull
    // If members are loading, this will be null, resulting in isLeader=false (hidden), which is safe.
    final currentMember = membersAsync.asData?.value.firstWhereOrNull(
      (m) => m.userId == currentUserId,
    );

    final isLeader = currentMember?.role == TripRole.leader;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Expenses'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (isLeader)
            tripAsync.when(
              data: (trip) => IconButton(
                icon: Icon(
                  trip.isExpenseEditingLocked ? Icons.lock : Icons.lock_open,
                ),
                tooltip: trip.isExpenseEditingLocked
                    ? 'Unlock Expenses'
                    : 'Lock Expenses',
                onPressed: () async {
                  await ref.read(
                    toggleExpenseLockActionProvider(
                      tripId,
                      !trip.isExpenseEditingLocked,
                    ).future,
                  );
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: expensesAsync.when(
        data: (expenses) => _buildExpensesList(
          context,
          expenses,
          tripAsync.asData?.value,
          membersAsync.asData?.value ?? [],
          currentUserId,
          ref,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: tripAsync.when(
        data: (trip) {
          if (trip.phase != TripPhase.active) return null;
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddExpenseScreen(tripId: tripId),
                ),
              );
            },
            label: const Text('Add Expense'),
            icon: const Icon(Icons.receipt_long),
          );
        },
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }

  Widget _buildExpensesList(
    BuildContext context,
    List<Expense> expenses,
    Trip? trip,
    List<TripMember> members,
    String? currentUserId,
    WidgetRef ref,
  ) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No expenses yet.\nTap + to add one!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return _ExpenseTile(
          expense: expense,
          trip: trip,
          members: members,
          currentUserId: currentUserId,
          ref: ref,
        );
      },
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;
  final Trip? trip;
  final List<TripMember> members;
  final String? currentUserId;
  final WidgetRef ref;

  const _ExpenseTile({
    required this.expense,
    required this.trip,
    required this.members,
    required this.currentUserId,
    required this.ref,
  });

  Future<void> _showEditSheet(BuildContext context) async {
    if (trip == null || currentUserId == null) return;

    // Determine current user role
    final myMember = members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => TripMember.empty(),
    );
    final isLeader = myMember.role == TripRole.leader;
    final allowSelfExclusion = trip!.allowSelfExclusion;

    // Phase Protection Gate
    if (trip!.phase != TripPhase.active) {
      if (!isLeader) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This trip is locked for settlement. You can no longer edit splits.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Leader Warning
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text(
            'Warning: Trip is Locked',
            style: TextStyle(color: Colors.orange),
          ),
          content: const Text(
            'This trip is locked. Editing splits now will recalculate '
            'everyone\'s final debts. Are you sure you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text(
                'Edit Anyway',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    if (!isLeader && !allowSelfExclusion) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only the Leader can edit splits for this trip.'),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // Local state for the sheet
        final oldParticipantIds = List<String>.from(expense.participantUserIds);
        final selectedIds = Set<String>.from(oldParticipantIds);

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Splits',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${expense.description} (${expense.currency} ${expense.amount.toStringAsFixed(2)})',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: members.map((member) {
                        final isMe = member.userId == currentUserId;
                        final name = member.profile?.displayName ?? 'Unknown';
                        final isSelected = selectedIds.contains(member.userId);

                        // Logic Rules
                        // Leader: Can edit ANY
                        // Non-Leader: Can ONLY edit SELF (if allowed)
                        bool isEnabled = false;
                        if (isLeader) {
                          isEnabled = true;
                        } else if (allowSelfExclusion) {
                          isEnabled = isMe;
                        }

                        return CheckboxListTile(
                          title: Text(isMe ? '$name (You)' : name),
                          value: isSelected,
                          onChanged: isEnabled
                              ? (val) {
                                  setState(() {
                                    if (val == true) {
                                      selectedIds.add(member.userId);
                                    } else {
                                      selectedIds.remove(member.userId);
                                    }
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (selectedIds.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'At least one participant is required.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.pop(context); // Close sheet
                      try {
                        await ref
                            .read(tripRepositoryProvider)
                            .updateExpenseParticipants(
                              expense.id,
                              selectedIds.toList(),
                              oldParticipantIds,
                            );

                        // Invalidate providers to recalculate balances and refresh UI
                        if (trip != null) {
                          ref.invalidate(expensesProvider(trip!.id));
                          ref.invalidate(netBalancesProvider(trip!.id));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update splits: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payerName = expense.paidByProfile?.displayName ?? 'Unknown';
    // Format amount
    // Ideally use NumberFormat with currency symbol map, but simple here
    final amountText =
        '${expense.currency} ${expense.amount.toStringAsFixed(2)}';

    // Determine leader id, ownership and permissions exactly as required
    final leaderId = members
        .firstWhereOrNull((m) => m.role == TripRole.leader)
        ?.userId;
    final bool isLeader =
        currentUserId != null && leaderId != null && currentUserId == leaderId;
    final bool isOwner =
        currentUserId != null && currentUserId == expense.paidBy;
    final bool canEdit =
        isLeader || (isOwner && (trip?.isExpenseEditingLocked != true));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0, // Flat look
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: () => _showEditSheet(context),
        borderRadius: BorderRadius.circular(12), // Match default Card radius
        child: ListTile(
          leading: UserAvatar(
            avatarUrl: expense.paidByProfile?.avatarUrl,
            displayName: payerName,
            backgroundColor: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
          ),
          title: Text(
            expense.description,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('Paid by $payerName'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM d').format(expense.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (canEdit && trip?.phase == TripPhase.active)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _showEditExpenseDialog(context);
                    } else if (value == 'delete') {
                      await _showDeleteExpenseDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Name/Price'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditExpenseDialog(BuildContext context) async {
    final titleController = TextEditingController(text: expense.description);
    final amountController = TextEditingController(
      text: expense.amount.toString(),
    );

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm == true && trip != null) {
      final newDesc = titleController.text.trim();
      final newAmount = double.tryParse(amountController.text.trim());
      if (newDesc.isNotEmpty && newAmount != null && newAmount > 0) {
        final updatedExpense = Expense(
          id: expense.id,
          tripId: expense.tripId,
          description: newDesc,
          amount: newAmount,
          currency: expense.currency,
          paidBy: expense.paidBy,
          createdAt: expense.createdAt,

          participantUserIds: expense.participantUserIds,
          paidByProfile: expense.paidByProfile,
        );
        try {
          await ref.read(
            updateExpenseActionProvider(trip!.id, updatedExpense).future,
          );
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating expense: $e')),
            );
          }
        }
      }
    }
  }

  Future<void> _showDeleteExpenseDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text(
          'Are you sure you want to delete this expense? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && trip != null) {
      try {
        await ref.read(
          deleteExpenseActionProvider(trip!.id, expense.id).future,
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error deleting expense: $e')));
        }
      }
    }
  }
}
