import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hardware_scanner_input/hardware_scanner_input.dart';

void main() {
  group('HardwareScannerInput', () {
    Widget host(HardwareScannerInput child) => MaterialApp(
          home: Scaffold(body: SizedBox(width: 200, height: 200, child: child)),
        );

    testWidgets('fires onScanned when the scanner sends an Enter suffix',
        (tester) async {
      final scans = <String>[];

      await tester.pumpWidget(
        host(HardwareScannerInput(onScanned: scans.add)),
      );

      final field = find.byType(TextField);
      await tester.enterText(field, 'ABC123');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(scans, ['ABC123']);
    });

    testWidgets('flushes after silence timeout when Enter is omitted',
        (tester) async {
      final scans = <String>[];

      await tester.pumpWidget(
        host(
          HardwareScannerInput(
            onScanned: scans.add,
            silenceTimeout: const Duration(milliseconds: 50),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'NO-ENTER');
      // Just before timeout — nothing should have flushed yet.
      await tester.pump(const Duration(milliseconds: 30));
      expect(scans, isEmpty);

      // Cross the timeout — flush fires.
      await tester.pump(const Duration(milliseconds: 30));
      expect(scans, ['NO-ENTER']);
    });

    testWidgets('trims whitespace and drops empty scans', (tester) async {
      final scans = <String>[];

      await tester.pumpWidget(
        host(
          HardwareScannerInput(
            onScanned: scans.add,
            silenceTimeout: const Duration(milliseconds: 20),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(const Duration(milliseconds: 30));

      await tester.enterText(find.byType(TextField), '  WITH-PADDING  ');
      await tester.pump(const Duration(milliseconds: 30));

      expect(scans, ['WITH-PADDING']);
    });

    testWidgets('clears its buffer between scans', (tester) async {
      final scans = <String>[];

      await tester.pumpWidget(
        host(
          HardwareScannerInput(
            onScanned: scans.add,
            silenceTimeout: const Duration(milliseconds: 20),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'FIRST');
      await tester.pump(const Duration(milliseconds: 30));
      await tester.enterText(find.byType(TextField), 'SECOND');
      await tester.pump(const Duration(milliseconds: 30));

      expect(scans, ['FIRST', 'SECOND']);
    });

    testWidgets('respects an externally provided focus node', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        host(
          HardwareScannerInput(
            focusNode: node,
            autofocus: false,
            onScanned: (_) {},
          ),
        ),
      );

      expect(node.hasFocus, isFalse);
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });
  });
}
