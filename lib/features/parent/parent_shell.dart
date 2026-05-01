// lib/features/parent/parent_shell.dart
import 'package:flutter/material.dart';
import 'intake/ui/home_screen.dart';
import 'intake/ui/history_calendar_screen.dart';
import 'medication/ui/medication_list_screen.dart';
import 'settings/ui/settings_screen.dart';
import 'slot/ui/slot_list_screen.dart';

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});
  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _idx = 0;
  final _pages = const [
    HomeScreen(),
    MedicationListScreen(),
    SlotListScreen(),
    HistoryCalendarScreen(),
    SettingsScreen(),
  ];
  final _labels = const ['오늘', '약 관리', '시간 관리', '이력', '설정'];
  final _icons = const [
    Icons.today, Icons.medication, Icons.schedule,
    Icons.calendar_month, Icons.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: List.generate(_pages.length, (i) =>
          NavigationDestination(icon: Icon(_icons[i], size: 28), label: _labels[i]),
        ),
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
