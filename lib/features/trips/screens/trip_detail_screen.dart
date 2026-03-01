import 'package:flutter/material.dart';
import '../../ledger/screens/expenses_tab.dart'; // Add expenses tab import
import '../../trips/screens/tabs/members_tab.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // We will conditionally render the 3 tabs based on the current index
    final List<Widget> tabs = [
      ExpensesTab(tripId: widget.tripId), // The new Expenses tab
      const Center(child: Text('Balances Tab placeholder')),
      MembersTab(tripId: widget.tripId), // Use MembersTab
    ];

    return Scaffold(
      body: SafeArea(child: tabs[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
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
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Members',
          ),
        ],
      ),
    );
  }
}
