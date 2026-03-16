import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import 'engine.dart';
import 'models.dart';

class RandomDomExecutor {
  static const MethodChannel _androidAppsChannel = MethodChannel('randomdom/android_apps');

  Future<String> execute(SelectionResult result) async {
    final item = result.item;

    switch (item.type) {
      case ItemType.text:
        return 'Текстовая задача выбрана';
      case ItemType.link:
        await _openLink(item.value);
        return 'Ссылка открыта';
      case ItemType.file:
        await _openFile(item.value);
        return 'Файл открыт';
      case ItemType.folder:
        final folderResolvedPath = result.resolvedFilePath;
        if (folderResolvedPath == null || folderResolvedPath.isEmpty) {
          throw StateError('Не удалось определить случайный файл из папки');
        }
        await _openFile(folderResolvedPath);
        return 'Случайный файл из папки открыт';
      case ItemType.application:
        await _launchApplication(item.value);
        return 'Приложение запущено';
      case ItemType.randomFileFromFolder:
        final path = result.resolvedFilePath;
        if (path == null || path.isEmpty) {
          throw StateError('Не удалось определить случайный файл');
        }
        await _openFile(path);
        return 'Случайный файл открыт';
      case ItemType.nestedList:
        return 'Выбран вложенный список';
    }
  }

  Future<void> _openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null) {
      throw StateError('Некорректная ссылка: $value');
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      throw StateError('Не удалось открыть ссылку: $value');
    }
  }

  Future<void> _openFile(String path) async {
    if (Platform.isWindows) {
      final file = File(path);
      final workingDirectory = file.existsSync() ? file.parent.path : null;
      await _startWindowsPath(path, workingDirectory: workingDirectory);
      return;
    }

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw StateError('Не удалось открыть файл: ${result.message}');
    }
  }

  Future<void> _startWindowsPath(String path, {String? workingDirectory}) async {
    final args = <String>['/c', 'start', ''];
    if (workingDirectory != null && workingDirectory.isNotEmpty) {
      args.addAll(['/d', workingDirectory]);
    }
    args.add(path);

    final process = await Process.run(
      'cmd',
      args,
      runInShell: true,
    );

    if (process.exitCode != 0) {
      throw StateError('Windows start вернул код ${process.exitCode}');
    }
  }

  Future<void> _launchApplication(String value) async {
    if (Platform.isAndroid) {
      final packageName = value.trim();
      if (packageName.isEmpty || packageName.contains('/')) {
        throw StateError('Некорректный package name: $packageName');
      }

      final opened = await _androidAppsChannel.invokeMethod<bool>(
        'launchApp',
        <String, dynamic>{'packageName': packageName},
      );
      if (opened != true) {
        throw StateError('Не удалось запустить приложение: $packageName');
      }
      return;
    }

    if (Platform.isWindows) {
      final file = File(value);
      if (file.existsSync()) {
        final isBatchFile = value.toLowerCase().endsWith('.bat') || value.toLowerCase().endsWith('.cmd');
        if (isBatchFile) {
          await _startWindowsPath(value, workingDirectory: file.parent.path);
          return;
        }

        final process = await Process.start(
          value,
          [],
          runInShell: true,
          workingDirectory: file.parent.path,
        );
        if (process.pid <= 0) {
          throw StateError('Не удалось запустить: $value');
        }
        return;
      }

      final process = await Process.run(
        'cmd',
        ['/c', 'start', '', value],
        runInShell: true,
      );
      if (process.exitCode != 0) {
        throw StateError('Не удалось запустить: $value');
      }
      return;
    }

    throw StateError('Тип application пока не поддерживается на этой платформе');
  }
}
