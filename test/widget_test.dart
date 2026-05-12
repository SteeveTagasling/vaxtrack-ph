import 'package:flutter_test/flutter_test.dart';
import 'package:vaxtrack_ph/app.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VaxTrackApp());
    // Just verify the app builds without crashing
    expect(find.byType(VaxTrackApp), findsOneWidget);
  });
}
