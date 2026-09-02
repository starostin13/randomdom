import 'dart:convert';
import 'dart:io';

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
    final configFile = File('${Directory.systemTemp.path}${Platform.pathSeparator}config.json');
    final originalConfig = await configFile.exists() ? await configFile.readAsString() : null;
    addTearDown(() async {
      if (originalConfig == null) {
        if (await configFile.exists()) {
          await configFile.delete();
        }
      } else {
        await configFile.writeAsString(originalConfig);
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
    final configFile = File('${Directory.systemTemp.path}${Platform.pathSeparator}config.json');
    final originalConfig = await configFile.exists() ? await configFile.readAsString() : null;
    addTearDown(() async {
      if (originalConfig == null) {
        if (await configFile.exists()) {
          await configFile.delete();
        }
      } else {
        await configFile.writeAsString(originalConfig);
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
}
