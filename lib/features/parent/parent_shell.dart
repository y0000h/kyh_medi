// lib/features/parent/parent_shell.dart
import 'package:flutter/material.dart';
import '../../core/theme/tokens.dart';
import '../../shared/widgets/floating_nav_bar.dart';
import 'assistant/ui/chat_screen.dart';
import 'intake/ui/home_screen.dart';
import 'intake/ui/history_calendar_screen.dart';
import 'medication/ui/medication_list_screen.dart';
import 'settings/ui/settings_screen.dart';
import 'slot/ui/slot_list_screen.dart';

class ParentShell extends StatefulWidget {
  final VoidCallback? onModeChange;
  const ParentShell({super.key, this.onModeChange});
  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int _idx = 0;
  late final List<Widget> _pages = [
    const HomeScreen(),
    const MedicationListScreen(),
    const SlotListScreen(),
    const HistoryCalendarScreen(),
    const ChatScreen(),
    SettingsScreen(onModeChange: widget.onModeChange),
  ];

  static const _items = [
    FloatingNavItem(Icons.today_rounded, '오늘'),
    FloatingNavItem(Icons.medication_rounded, '약 관리'),
    FloatingNavItem(Icons.schedule_rounded, '시간'),
    FloatingNavItem(Icons.calendar_month_rounded, '이력'),
    FloatingNavItem(Icons.forum_rounded, '도움'),
    FloatingNavItem(Icons.settings_rounded, '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.seniorBg),
        child: _pages[_idx],
      ),
      bottomNavigationBar: FloatingNavBar(
        items: _items,
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
      ),
    );
  }
}
