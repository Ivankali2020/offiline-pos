import 'package:flutter_test/flutter_test.dart';
import 'package:abpos/app_bindings.dart';
import 'package:abpos/widgets/app_shell.dart';

void main() {
  testWidgets('App starts with GetMaterialApp', (WidgetTester tester) async {
    await AppBindings.initServices();
    await tester.pumpWidget(const AppShell());
    await tester.pumpAndSettle();
  });
}
