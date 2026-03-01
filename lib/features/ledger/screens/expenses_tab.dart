import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../trips/models/trip.dart'; // import TripPhase
import '../../trips/providers/trip_provider.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class ExpensesTab extends ConsumerWidget {
  final String tripId;

  const ExpensesTab({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider(tripId));
    final tripAsync = ref.watch(tripProvider(tripId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: expensesAsync.when(
        data: (expenses) => _buildExpensesList(context, expenses),
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

  Widget _buildExpensesList(BuildContext context, List<Expense> expenses) {
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
        return _ExpenseTile(expense: expense);
      },
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  final Expense expense;

  const _ExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payerName = expense.paidByProfile?.displayName ?? 'Unknown';
    // If no initial, use first letter of name
    final initial = payerName.isNotEmpty ? payerName[0].toUpperCase() : '?';

    // Format amount
    // Ideally use NumberFormat with currency symbol map, but simple here
    final amountText =
        '${expense.currency} ${expense.amount.toStringAsFixed(2)}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0, // Flat look
      color: theme.colorScheme.surfaceContainerLow,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: Text(initial),
        ),
        title: Text(
          expense.description,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Paid by $payerName'),
        trailing: Column(
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
      ),
    );
  }
}
