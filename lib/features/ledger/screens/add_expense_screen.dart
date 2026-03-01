// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../trips/providers/trip_provider.dart';
import '../../trips/models/trip.dart'; // Ensure trip models are imported
import '../../roster/models/trip_member.dart'; // Ensure profile is known via members

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String tripId;

  const AddExpenseScreen({super.key, required this.tripId});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  // We store the participants locally
  Set<String> _selectedParticipants = {};
  bool _isLoading = false;

  // To avoid stream re-creation loops and state resets
  late Stream<List<TripMember>> _membersStream;
  bool _hasInitializedSelection = false;

  @override
  void initState() {
    super.initState();
    // Initialize stream once
    _membersStream = ref
        .read(tripRepositoryProvider)
        .watchTripMembers(widget.tripId);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Expense')),
      body: StreamBuilder<List<TripMember>>(
        stream: _membersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading members: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = snapshot.data!;

          // Auto-select all members initially
          if (!_hasInitializedSelection && members.isNotEmpty) {
            _selectedParticipants = members.map((m) => m.userId).toSet();
            // We use a microtask to update state after this build phase
            // to ensure checkboxes reflect this change without error
            Future.microtask(() {
              if (mounted) {
                setState(() {
                  _hasInitializedSelection = true;
                });
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'e.g. Dinner at Mario\'s',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      hintText: '0.00',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final n = double.tryParse(value);
                      if (n == null || n <= 0) return 'Invalid amount';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Split with:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: members.map((member) {
                      final userId = member.userId;
                      final isSelected = _selectedParticipants.contains(userId);
                      final name = member.profile?.displayName ?? 'User';
                      final initial = name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?';

                      return FilterChip(
                        label: Text(name),
                        avatar: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Text(
                            initial,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedParticipants.add(userId);
                            } else {
                              _selectedParticipants.remove(userId);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedParticipants.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Select at least one person.',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitExpense,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('SAVE EXPENSE'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one participant.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      await ref
          .read(tripRepositoryProvider)
          .createExpense(
            tripId: widget.tripId,
            description: _descriptionController.text.trim(),
            amount: amount,
            participantUserIds: _selectedParticipants.toList(),
          );
      ref.invalidate(expensesProvider(widget.tripId));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll("Exception: ", "")}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
