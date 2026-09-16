import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:randomdom_flutter/domain/models.dart';
import 'package:randomdom_flutter/main.dart';

void main() {
  testWidgets('App shell smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RandomDomApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Can switch task list to circular chart view', (WidgetTester tester) async {
    final originalCwd = Directory.current.path;
    final tempDir = await Directory.systemTemp.createTemp('randomdom_chart_view_test_');
    Directory.current = tempDir.path;
    final configFile = File('${tempDir.path}${Platform.pathSeparator}config.json');
    addTearDown(() async {
      Directory.current = originalCwd;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await configFile.writeAsString(
      jsonEncode(
        RandomDomConfig(
          schemaVersion: 2,
          moodPolicy: MoodPolicy.defaultPolicy(),
          lists: {
            'main': RandomDomList(
              name: 'Основные дела',
              items: const [
                RandomDomItem(
                  id: 'item_1',
                  type: ItemType.text,
                  value: 'Проверить почту',
                  weight: 2,
                  category: ItemCategory.serious,
                ),
                RandomDomItem(
                  id: 'item_2',
                  type: ItemType.text,
                  value: 'Отдохнуть',
                  weight: 1,
                  category: ItemCategory.fun,
                ),
              ],
            ),
          },
        ).toJson(),
      ),
    );

    await tester.pumpWidget(const RandomDomApp());
    await tester.pumpAndSettle();

    expect(find.text('Круговая диаграмма'), findsOneWidget);
    await tester.tap(find.text('Круговая диаграмма'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('Проверить почту'), findsOneWidget);
  });

  testWidgets('Chart items are sorted with serious tasks first, then fun tasks',
      (WidgetTester tester) async {
    final originalCwd = Directory.current.path;
    final tempDir = await Directory.systemTemp.createTemp('randomdom_chart_sort_test_');
    Directory.current = tempDir.path;
    final configFile = File('${tempDir.path}${Platform.pathSeparator}config.json');
    addTearDown(() async {
      Directory.current = originalCwd;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    // Create config with fun task first, then serious task
    // After sorting, serious should be displayed first
    await configFile.writeAsString(
      jsonEncode(
        RandomDomConfig(
          schemaVersion: 2,
          moodPolicy: MoodPolicy.defaultPolicy(),
          lists: {
            'main': RandomDomList(
              name: 'Основные дела',
              items: const [
                RandomDomItem(
                  id: 'item_1',
                  type: ItemType.text,
                  value: 'Отдохнуть',
                  weight: 1,
                  category: ItemCategory.fun,
                ),
                RandomDomItem(
                  id: 'item_2',
                  type: ItemType.text,
                  value: 'Проверить почту',
                  weight: 2,
                  category: ItemCategory.serious,
                ),
              ],
            ),
          },
        ).toJson(),
      ),
    );

    await tester.pumpWidget(const RandomDomApp());
    await tester.pumpAndSettle();

    expect(find.text('Круговая диаграмма'), findsOneWidget);
    await tester.tap(find.text('Круговая диаграмма'));
    await tester.pumpAndSettle();

    // After switching to chart view, the items should be sorted:
    // serious task (Проверить почту) should appear before fun task (Отдохнуть)
    final chipFinder = find.byType(Chip);
    expect(chipFinder, findsWidgets);

    // Find the text widgets for both items
    final seriousTaskFinder = find.textContaining('Проверить почту');
    final funTaskFinder = find.textContaining('Отдохнуть');

    expect(seriousTaskFinder, findsOneWidget);
    expect(funTaskFinder, findsOneWidget);

    // Verify that serious task appears before fun task in the widget tree
    final seriousTaskIndex = tester.getCenter(seriousTaskFinder).dy;
    final funTaskIndex = tester.getCenter(funTaskFinder).dy;

    expect(seriousTaskIndex, lessThan(funTaskIndex),
        reason: 'Serious task should appear before fun task');
  });

  testWidgets('Chart segment clicks adjust task weight by mouse button', (WidgetTester tester) async {
    final originalCwd = Directory.current.path;
    final tempDir = await Directory.systemTemp.createTemp('randomdom_chart_click_test_');
    Directory.current = tempDir.path;
    final configFile = File('${tempDir.path}${Platform.pathSeparator}config.json');
    addTearDown(() async {
      Directory.current = originalCwd;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    await configFile.writeAsString(
      jsonEncode(
        RandomDomConfig(
          schemaVersion: 2,
          moodPolicy: MoodPolicy.defaultPolicy(),
          lists: {
            'main': RandomDomList(
              name: 'Основные дела',
              items: const [
                RandomDomItem(
                  id: 'item_1',
                  type: ItemType.text,
                  value: 'Проверить почту',
                  weight: 2,
                  category: ItemCategory.serious,
                ),
                RandomDomItem(
                  id: 'item_2',
                  type: ItemType.text,
                  value: 'Отдохнуть',
                  weight: 1,
                  category: ItemCategory.fun,
                ),
              ],
            ),
          },
        ).toJson(),
      ),
    );

    await tester.pumpWidget(const RandomDomApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Круговая диаграмма'));
    await tester.pumpAndSettle();

    expect(find.text('Проверить почту (2.00)'), findsOneWidget);

    final chartCenter = tester.getCenter(find.byKey(const ValueKey('task_distribution_chart')));
    final secondaryClick = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    final chartPoint = chartCenter + const Offset(50, 0);
    await secondaryClick.addPointer(location: chartPoint);
    await secondaryClick.down(chartPoint);
    await secondaryClick.up();
    await tester.pumpAndSettle();

    expect(find.text('Проверить почту (1.00)'), findsOneWidget);

    final touchTap = await tester.createGesture(kind: PointerDeviceKind.touch);
    final touchPoint = chartCenter + const Offset(50, 0);
    await touchTap.addPointer(location: touchPoint);
    await touchTap.down(touchPoint);
    await touchTap.up();
    await tester.pumpAndSettle();

    expect(find.text('Проверить почту (2.00)'), findsOneWidget);
  });

  test('Task balance helper moves weight evenly between serious and fun tasks', () {
    final items = const [
      RandomDomItem(
        id: 'serious_1',
        type: ItemType.text,
        value: 'Проверить почту',
        weight: 2,
        category: ItemCategory.serious,
      ),
      RandomDomItem(
        id: 'serious_2',
        type: ItemType.text,
        value: 'Сделать план',
        weight: 2,
        category: ItemCategory.serious,
      ),
      RandomDomItem(
        id: 'fun_1',
        type: ItemType.text,
        value: 'Погулять',
        weight: 1,
        category: ItemCategory.fun,
      ),
      RandomDomItem(
        id: 'fun_2',
        type: ItemType.text,
        value: 'Послушать музыку',
        weight: 1,
        category: ItemCategory.fun,
      ),
    ];

    final balanced = TaskBalanceUtils.applyBalance(items, 0.0);
    final seriousWeights = balanced
        .where((item) => item.category == ItemCategory.serious)
        .map((item) => item.weight)
        .toList();
    final funWeights = balanced
        .where((item) => item.category == ItemCategory.fun)
        .map((item) => item.weight)
        .toList();

    expect(seriousWeights, everyElement(closeTo(1.5, 1e-6)));
    expect(funWeights, everyElement(closeTo(1.5, 1e-6)));
    expect(TaskBalanceUtils.itemBalance(balanced), closeTo(0.0, 1e-6));
  });

  test('Task balance helper redistributes residual weight when an item hits its bound', () {
    final items = const [
      RandomDomItem(
        id: 'serious_1',
        type: ItemType.text,
        value: 'Проверить почту',
        weight: 0.1,
        category: ItemCategory.serious,
      ),
      RandomDomItem(
        id: 'serious_2',
        type: ItemType.text,
        value: 'Сделать план',
        weight: 2,
        category: ItemCategory.serious,
      ),
      RandomDomItem(
        id: 'fun_1',
        type: ItemType.text,
        value: 'Погулять',
        weight: 1,
        category: ItemCategory.fun,
      ),
      RandomDomItem(
        id: 'fun_2',
        type: ItemType.text,
        value: 'Послушать музыку',
        weight: 1,
        category: ItemCategory.fun,
      ),
    ];

    final balanced = TaskBalanceUtils.applyBalance(items, 0.5);
    final seriousWeights = balanced
        .where((item) => item.category == ItemCategory.serious)
        .map((item) => item.weight)
        .toList();
    final funWeights = balanced
        .where((item) => item.category == ItemCategory.fun)
        .map((item) => item.weight)
        .toList();

    expect(seriousWeights.first, closeTo(0.1, 1e-6));
    expect(seriousWeights.last, closeTo(0.925, 1e-6));
    expect(funWeights, everyElement(closeTo(1.5375, 1e-6)));
    expect(
      balanced.fold<double>(0, (sum, item) => sum + item.weight),
      closeTo(items.fold<double>(0, (sum, item) => sum + item.weight), 1e-6),
    );
    expect(TaskBalanceUtils.itemBalance(balanced), closeTo(0.5, 1e-6));
  });
}
