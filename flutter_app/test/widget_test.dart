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
}
