import 'dart:io';
import 'dart:math';

import 'models.dart';

class SelectionResult {
  const SelectionResult({
    required this.sourceListId,
    required this.item,
    this.resolvedFilePath,
  });

  final String sourceListId;
  final RandomDomItem item;
  final String? resolvedFilePath;

  SelectionResult copyWith({
    String? sourceListId,
    RandomDomItem? item,
    String? resolvedFilePath,
  }) {
    return SelectionResult(
      sourceListId: sourceListId ?? this.sourceListId,
      item: item ?? this.item,
      resolvedFilePath: resolvedFilePath ?? this.resolvedFilePath,
    );
  }
}

class RandomDomEngine {
  RandomDomEngine({
    required this.config,
    Random? random,
  }) : _random = random ?? Random();

  final RandomDomConfig config;
  final Random _random;

  Future<SelectionResult> selectFromList({
    required String listId,
    required String mood,
  }) async {
    final list = config.lists[listId];
    if (list == null) {
      throw StateError('Список не найден: $listId');
    }
    if (list.items.isEmpty) {
      throw StateError('Список пуст: $listId');
    }

    final selected = _selectWeightedItem(list.items, mood);

    if (selected.type == ItemType.nestedList) {
      return selectFromList(listId: selected.value, mood: mood);
    }

    if (selected.type == ItemType.randomFileFromFolder || selected.type == ItemType.folder) {
      final path = _selectRandomFileRecursively(selected.value);
      return SelectionResult(
        sourceListId: listId,
        item: selected,
        resolvedFilePath: path,
      );
    }

    return SelectionResult(sourceListId: listId, item: selected);
  }

  RandomDomItem _selectWeightedItem(List<RandomDomItem> items, String mood) {
    final moodProfile = config.moodPolicy.profiles[mood] ??
        config.moodPolicy.profiles[config.moodPolicy.activeMood] ??
        MoodPolicy.defaultPolicy().profiles['neutral']!;

    final effectiveWeights = items
        .map((item) {
          final moodMultiplier = item.category == ItemCategory.fun
              ? moodProfile.funMultiplier
              : moodProfile.seriousMultiplier;
          final value = item.weight * moodMultiplier;
          return value <= 0 ? 0.0001 : value;
        })
        .toList();

    final total = effectiveWeights.fold<double>(0, (sum, value) => sum + value);
    var cursor = _random.nextDouble() * total;

    for (var index = 0; index < items.length; index++) {
      cursor -= effectiveWeights[index];
      if (cursor <= 0) {
        return items[index];
      }
    }

    return items.last;
  }

  String _selectRandomFileRecursively(String rootPath) {
    final directory = Directory(rootPath);
    if (!directory.existsSync()) {
      throw StateError('Папка не найдена: $rootPath');
    }

    final files = directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.existsSync())
        .toList();

    if (files.isEmpty) {
      throw StateError('В папке нет файлов: $rootPath');
    }

    return files[_random.nextInt(files.length)].path;
  }
}
