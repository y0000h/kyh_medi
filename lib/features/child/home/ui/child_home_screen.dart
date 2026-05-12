import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../shared/widgets/caregiver_card.dart';
import '../../add_parent/ui/add_parent_screen.dart';
import '../../auth/child_auth_service.dart';
import '../../parent_detail/ui/parent_detail_screen.dart';
import 'child_home_provider.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  final _auth = ChildAuthService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ChildHomeProvider>().load();
    });
  }

  Future<void> _confirmAndSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('계정에서 로그아웃하시겠어요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ChildHomeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('부모님 모니터링'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: _confirmAndSignOut,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ChildHomeProvider>().load(),
        child: p.items.isEmpty && !p.loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text(
                    '연결된 부모님이 아직 없어요.\n오른쪽 아래 + 버튼을 누르세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            : ListView(
                children: [
                  for (final s in p.items)
                    CaregiverCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParentDetailScreen(
                            parentDeviceId: s.parentDeviceId,
                            label: s.label,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: AppRadius.pillAll,
                            ),
                            child: const Icon(Icons.person,
                                size: 32, color: Colors.blueAccent),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.label,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '오늘 ${s.takenToday}/${s.totalToday} 복용'
                                  '${s.missedToday > 0 ? " · 미복용 ${s.missedToday}" : ""}',
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddParentScreen()),
          );
          if (added == true && context.mounted) {
            context.read<ChildHomeProvider>().load();
          }
        },
        label: const Text('부모님 추가'),
        icon: const Icon(Icons.person_add),
      ),
    );
  }
}
