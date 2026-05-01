// 위젯 스모크 테스트.
//
// 실제 [App] 위젯은 Hive/Firebase/Supabase 등 인프라 초기화에 의존하므로
// 단순 pumpWidget으로는 띄울 수 없다. Phase 11에서 통합 테스트(integration_test)로
// 대체될 예정이며, 현재는 컴파일/lint 통과 목적의 placeholder만 둔다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('placeholder smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
