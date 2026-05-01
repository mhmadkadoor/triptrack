import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart';

class DesktopTripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;

  const DesktopTripDetailScreen({
    super.key,
    required this.tripId,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
  });

  @override
  ConsumerState<DesktopTripDetailScreen> createState() =>
      _DesktopTripDetailScreenState();
}

class _DesktopTripDetailScreenState
    extends ConsumerState<DesktopTripDetailScreen> {
  bool _isLeaving = false;

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripProvider(widget.tripId));

    return Scaffold(
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
                        icon: const Icon(Icons.exit_to_app, color: Colors.red),
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
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Expenses'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: Text('Balances'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.checklist_outlined),
                selectedIcon: Icon(Icons.checklist),
                label: Text('Shopping'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Members'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: Colors.white10),
                    ),
                  ),
                  child: widget.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
