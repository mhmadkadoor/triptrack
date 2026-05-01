import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ledger/screens/expenses_tab.dart';
import '../../ledger/screens/balances_tab.dart'; // import new tab
import '../../ledger/screens/shopping_list_tab.dart'; // import new tab
import '../../trips/screens/tabs/members_tab.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'desktop_trip_detail_screen.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  int _currentIndex = 0;
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    // We will conditionally render the tabs based on the current index
    final List<Widget> tabs = [
      ExpensesTab(tripId: widget.tripId),
      BalancesTab(tripId: widget.tripId),
      ShoppingListTab(tripId: widget.tripId), // Shopping List
      MembersTab(tripId: widget.tripId),
    ];

    void onDestinationSelected(int index) {
      setState(() {
        _currentIndex = index;
      });
    }

    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return ResponsiveLayout(
      mobileBody: Scaffold(
        appBar: AppBar(
          title: tripAsync.when(
            data: (trip) => Text(trip.name),
            loading: () => const Text('Loading...'),
            error: (_, __) => const Text('Error'),
          ),
          actions: [
            tripAsync.maybeWhen(
              data: (trip) {
                if (trip.phase == TripPhase.settled) {
                  return _isLeaving
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(
                            Icons.exit_to_app,
                            color: Colors.red,
                          ),
                          tooltip: 'Leave Trip',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Leave Trip?'),
                                content: const Text(
                                  'Are you sure you want to leave this trip? Your expense history will remain, but the trip will be removed from your dashboard.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text(
                                      'Leave',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() => _isLeaving = true);
                              try {
                                // Trigger Riverpod action
                                await ref.read(
                                  leaveTripProvider(widget.tripId).future,
                                );

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Successfully left the trip.',
                                      ),
                                    ),
                                  );
                                  Navigator.of(
                                    context,
                                  ).pop(); // Return to dashboard
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setState(() => _isLeaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error leaving trip: $e'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                        );
                }
                return const SizedBox.shrink();
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        body: SafeArea(child: tabs[_currentIndex]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Balances',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Shopping',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Members',
            ),
          ],
        ),
      ),
      desktopBody: DesktopTripDetailScreen(
        tripId: widget.tripId,
        selectedIndex: _currentIndex,
        onDestinationSelected: onDestinationSelected,
        body: tabs[_currentIndex],
      ),
    );
  }
}
