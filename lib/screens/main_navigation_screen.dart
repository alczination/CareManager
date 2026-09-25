import 'package:flutter/material.dart';
import '../../models/betreuer.dart';
import '../../models/kunde.dart';
import 'home_screen.dart';
import 'opiekunki/betreuer_list_screen.dart';
import 'podopieczni/kunde_list_screen.dart';
import 'kalendarz/kalendarz_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Betreuer> _betreuerList = [];
  List<Kunde> _kundeList = [];
  final GlobalKey<KalendarzScreenState> _calendarKey = GlobalKey<KalendarzScreenState>();

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calendarKey.currentState?.reloadTurnusData();
      });
    }
  }

  void _updateBetreuer(List<Betreuer> newList) {
    setState(() {
      _betreuerList = newList;
    });
  }

  void _updateKunden(List<Kunde> newList) {
    setState(() {
      _kundeList = newList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onNavigateToTab: _navigateToTab),
      BetreuerListScreen(
        betreuerList: _betreuerList,
        onDataChanged: _updateBetreuer,
      ),
      KundenListScreen(
        kundenList: _kundeList,
        onListChanged: _updateKunden,
      ),
      KalendarzScreen(
        key: _calendarKey,
        betreuerList: _betreuerList,
        kundeList: _kundeList,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _navigateToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Start',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Opiekunki',
          ),
          NavigationDestination(
            icon: Icon(Icons.personal_injury_outlined),
            selectedIcon: Icon(Icons.personal_injury),
            label: 'Podopieczni',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Kalendarz',
          ),
        ],
      ),
    );
  }
}