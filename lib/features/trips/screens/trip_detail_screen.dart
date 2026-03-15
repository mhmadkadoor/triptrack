import 'package:flutter/material.dart';
import '../../ledger/screens/expenses_tab.dart';
import '../../ledger/screens/balances_tab.dart'; // import new tab
import '../../ledger/screens/shopping_list_tab.dart'; // import new tab
import '../../trips/screens/tabs/members_tab.dart';
import '../../../core/widgets/responsive_layout.dart';
import 'desktop_trip_detail_screen.dart';

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

    return ResponsiveLayout(
      mobileBody: Scaffold(
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
        selectedIndex: _currentIndex,
        onDestinationSelected: onDestinationSelected,
        body: tabs[_currentIndex],
      ),
    );
  }
}
