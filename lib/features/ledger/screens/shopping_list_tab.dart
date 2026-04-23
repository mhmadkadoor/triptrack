import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../trips/providers/trip_provider.dart';
import '../../trips/providers/trip_repository.dart';
import '../../roster/models/trip_member.dart';
import '../../ledger/models/shopping_item.dart';
import '../../ledger/screens/add_expense_screen.dart';
import 'ai_suggestions_sheet.dart';

class ShoppingListTab extends ConsumerStatefulWidget {
  final String tripId;

  const ShoppingListTab({super.key, required this.tripId});

  @override
  ConsumerState<ShoppingListTab> createState() => _ShoppingListTabState();
}

class _ShoppingListTabState extends ConsumerState<ShoppingListTab> {
  final _itemController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      await ref
          .read(tripRepositoryProvider)
          .addShoppingItem(widget.tripId, text);
      _itemController.clear();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Get current user
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // 2. Watch data
    final shoppingItemsAsync = ref.watch(shoppingItemsProvider(widget.tripId));
    final membersAsync = ref.watch(tripMembersProvider(widget.tripId));
    final expensesAsync = ref.watch(expensesProvider(widget.tripId));

    // 3. Determine if Leader
    final currentMember = membersAsync.asData?.value.firstWhereOrNull(
      (m) => m.userId == currentUserId,
    );
    final isLeader = currentMember?.role == TripRole.leader;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Shopping List'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isLeader)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'AI Suggestions',
              onPressed: shoppingItemsAsync.hasValue && expensesAsync.hasValue
                  ? () {
                      final currentItems = shoppingItemsAsync.value!
                          .map((e) => e.itemName)
                          .toList();
                      final currentExpenses = expensesAsync.value!
                          .map((e) => e.description)
                          .toList();
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => AiSuggestionsSheet(
                          tripId: widget.tripId,
                          currentExpenses: currentExpenses,
                          currentShoppingItems: currentItems,
                        ),
                      );
                    }
                  : null,
            ),
        ],
      ),
      body: Column(
        children: [
          // Leader Input Area
          if (isLeader)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _itemController,
                      decoration: const InputDecoration(
                        hintText: 'Add needed item...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isAdding ? null : _addItem,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                  ),
                ],
              ),
            ),

          // List Area
          Expanded(
            child: shoppingItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items yet. Add something!'),
                  );
                }
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final isClaimed = item.claimedBy != null;
                    final claimedByMe = item.claimedBy == currentUserId;

                    // Find claimer name/avatar if claimed
                    TripMember? claimer;
                    if (isClaimed) {
                      claimer = membersAsync.asData?.value.firstWhereOrNull(
                        (m) => m.userId == item.claimedBy,
                      );
                    }

                    return ListTile(
                      title: Text(
                        item.itemName,
                        style: TextStyle(
                          decoration: isClaimed
                              ? TextDecoration.lineThrough
                              : null,
                          color: isClaimed ? Colors.grey : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Claim/Unclaim Button logic
                          if (!isClaimed)
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await ref
                                      .read(tripRepositoryProvider)
                                      .toggleClaimItem(
                                        item.id,
                                        currentUserId,
                                        null,
                                      );
                                  await Future.delayed(
                                    const Duration(milliseconds: 100),
                                  );
                                  ref.invalidate(
                                    shoppingItemsProvider(widget.tripId),
                                  );
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error claiming: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade100,
                                foregroundColor: Colors.green.shade800,
                                elevation: 0,
                              ),
                              child: const Text('Claim'),
                            )
                          else if (claimedByMe)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(tripRepositoryProvider)
                                          .toggleClaimItem(
                                            item.id,
                                            currentUserId,
                                            currentUserId,
                                          );
                                      await Future.delayed(
                                        const Duration(milliseconds: 100),
                                      );
                                      ref.invalidate(
                                        shoppingItemsProvider(widget.tripId),
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error unclaiming: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: const Text('Unclaim'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddExpenseScreen(
                                          tripId: widget.tripId,
                                          initialTitle: item.itemName,
                                          shoppingItemId: item.id,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(
                                    Icons.receipt_long,
                                    size: 16,
                                  ),
                                  label: const Text('Bought It'),
                                ),
                              ],
                            )
                          else
                            // Claimed by someone else
                            Chip(
                              avatar: claimer?.profile?.avatarUrl != null
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        claimer!.profile!.avatarUrl!,
                                      ),
                                    )
                                  : const Icon(Icons.person, size: 16),
                              label: Text(
                                claimer?.profile?.displayName ?? 'Claimed',
                              ),
                              backgroundColor: Colors.grey.shade200,
                            ),

                          // Delete Button (Leader only)
                          if (isLeader) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => ref
                                  .read(tripRepositoryProvider)
                                  .deleteShoppingItem(item.id),
                            ),
                          ],
                        ],
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
