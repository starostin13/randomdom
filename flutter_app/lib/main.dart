import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:device_apps_plus/device_apps_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'domain/engine.dart';
import 'domain/executor.dart';
import 'domain/models.dart';

void main() {
  runApp(const RandomDomApp());
}

class RandomDomApp extends StatefulWidget {
  const RandomDomApp({super.key});

  @override
  State<RandomDomApp> createState() => _RandomDomAppState();
}

class _RandomDomAppState extends State<RandomDomApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  RandomDomConfig? _config;
  String? _configFilePath;
  List<String> _searchedConfigPaths = const [];
  String? _error;
  String? _status;
  String _selectedMood = 'neutral';
  bool _startupMoodAsked = false;
  bool _showDebugLog = false;
  final List<String> _runtimeLog = [];
  String _selectedListId = 'main';
  int? _editingIndex;
  ItemType _editingType = ItemType.text;
  ItemCategory _editingCategory = ItemCategory.serious;
  final TextEditingController _editingValueController = TextEditingController();
  final TextEditingController _editingWeightController = TextEditingController();
  SelectionResult? _lastResult;
  bool _isSelecting = false;
  String? _rollingPreview;
  final Random _random = Random();
  final RandomDomExecutor _executor = RandomDomExecutor();

  @override
  void initState() {
    super.initState();
    _loadDefaultConfig();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showStartupMoodDialog();
    });
  }

  @override
  void dispose() {
    _editingValueController.dispose();
    _editingWeightController.dispose();
    super.dispose();
  }

  Future<void> _showStartupMoodDialog() async {
    if (!mounted || _startupMoodAsked) {
      return;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null || Localizations.maybeLocaleOf(dialogContext) == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStartupMoodDialog();
      });
      return;
    }

    try {
      final selectedMood = await showDialog<String>(
        context: dialogContext,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Как настроение?'),
          content: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('bad'),
                  child: const Text('Плохо'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop('neutral'),
                  child: const Text('Хорошо'),
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      if (selectedMood == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showStartupMoodDialog();
        });
        return;
      }

      setState(() {
        _selectedMood = selectedMood;
        _status = selectedMood == 'bad' ? 'Настроение: плохо' : 'Настроение: хорошо';
        _startupMoodAsked = true;
      });
      _addLog('Startup mood selected: $_selectedMood');
    } catch (exception) {
      _addLog('Startup mood dialog failed: $exception');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStartupMoodDialog();
      });
    }
  }

  void _addLog(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$time] $message';
    _runtimeLog.add(line);
    if (_runtimeLog.length > 80) {
      _runtimeLog.removeRange(0, _runtimeLog.length - 80);
    }
    debugPrint('[RandomDom] $line');
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<String>> _candidateConfigPaths() async {
    final paths = <String>{
      'config.json',
      '../config.json',
    };

    final separator = Platform.pathSeparator;
    final executablePath = Platform.resolvedExecutable;
    final separatorIndex = executablePath.lastIndexOf(separator);
    if (separatorIndex > 0) {
      final executableDir = executablePath.substring(0, separatorIndex);
      paths.add('$executableDir${Platform.pathSeparator}config.json');
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      paths.add('${appDir.path}${Platform.pathSeparator}config.json');
    } catch (_) {
    }

    return paths.toList();
  }

  Future<File?> _findExistingConfigFile() async {
    final candidates = await _candidateConfigPaths();
    setState(() {
      _searchedConfigPaths = candidates;
    });

    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) {
        return file;
      }
    }

    return null;
  }

  Future<void> _openConfigFile(File file) async {
    final jsonMap = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final config = RandomDomConfig.fromJson(jsonMap);

    setState(() {
      _error = null;
      _config = config;
      _configFilePath = file.path;
      _selectedListId = config.lists.containsKey('main')
          ? 'main'
          : config.lists.keys.first;
      _status = 'Конфиг загружен: ${file.path}';
    });
    _addLog('Config loaded from ${file.path}');
  }

  Future<void> _loadDefaultConfig() async {
    final file = await _findExistingConfigFile();
    if (file == null) {
      setState(() {
        _error = 'Не найден config.json. Можно создать новый автоматически.';
        _config = null;
        _configFilePath = null;
      });
      return;
    }

    try {
      await _openConfigFile(file);
    } catch (exception) {
      setState(() {
        _error = 'Ошибка загрузки конфига: $exception';
      });
    }
  }

  RandomDomConfig _buildDefaultConfig() {
    return RandomDomConfig(
      schemaVersion: 2,
      moodPolicy: MoodPolicy.defaultPolicy(),
      lists: {
        'main': RandomDomList(
          name: 'Основные дела',
          items: const [
            RandomDomItem(
              id: 'item_1',
              type: ItemType.text,
              value: 'Добавь свои дела в редакторе',
              weight: 1.0,
              category: ItemCategory.serious,
            ),
          ],
        ),
      },
    );
  }

  Future<String> _defaultConfigTargetPath() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      return '${appDir.path}${Platform.pathSeparator}config.json';
    }
    return 'config.json';
  }

  Future<void> _createDefaultConfig() async {
    try {
      final targetPath = await _defaultConfigTargetPath();
      final config = _buildDefaultConfig();
      final file = File(targetPath);
      await file.parent.create(recursive: true);
      const encoder = JsonEncoder.withIndent('  ');
      await file.writeAsString('${encoder.convert(config.toJson())}\n');
      await _openConfigFile(file);
      setState(() {
        _status = 'Создан новый конфиг: $targetPath';
      });
    } catch (exception) {
      setState(() {
        _error = 'Не удалось создать config.json: $exception';
      });
    }
  }

  Future<void> _persistConfig(RandomDomConfig config) async {
    final configPath = _configFilePath;
    if (configPath == null || configPath.isEmpty) {
      setState(() {
        _error = 'Путь к config.json не определён. Перезагрузите конфиг.';
      });
      return;
    }

    final file = File(configPath);
    final tempFile = File('$configPath.tmp');
    final encoder = const JsonEncoder.withIndent('  ');
    final jsonText = encoder.convert(config.toJson());

    await file.parent.create(recursive: true);
    await tempFile.writeAsString('$jsonText\n');
    if (file.existsSync()) {
      await file.delete();
    }
    await tempFile.rename(configPath);

    setState(() {
      _status = 'Сохранено в $configPath';
      _error = null;
    });
  }

  Future<void> _selectRandom() async {
    final config = _config;
    if (config == null || _isSelecting) {
      return;
    }

    try {
      setState(() {
        _isSelecting = true;
        _error = null;
      });

      final activeList = config.lists[_selectedListId];
      if (activeList != null && activeList.items.isNotEmpty) {
        await _runRollAnimation(activeList);
      }

      final result = await RandomDomEngine(config: config).selectFromList(
        listId: _selectedListId,
        mood: _selectedMood,
      );
      _addLog('Random selected: ${result.item.value} (${result.item.type.name})');

      setState(() {
        _lastResult = result;
        _status = 'Готово';
      });
      await _executeSelection(result);
    } catch (exception) {
      setState(() {
        _error = 'Ошибка выбора: $exception';
      });
    } finally {
      setState(() {
        _isSelecting = false;
        _rollingPreview = null;
      });
    }
  }

  Future<void> _runRollAnimation(RandomDomList list) async {
    const frames = 12;
    for (var index = 0; index < frames; index++) {
      if (!mounted) {
        return;
      }
      final preview = list.items[_random.nextInt(list.items.length)].value;
      setState(() {
        _rollingPreview = preview;
      });
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
  }

  String _typeLabel(ItemType type) {
    return switch (type) {
      ItemType.text => 'Текст',
      ItemType.link => 'Ссылка',
      ItemType.file => 'Файл',
      ItemType.folder => 'Папка',
      ItemType.application => 'Приложение',
      ItemType.nestedList => 'Вложенный список',
      ItemType.randomFileFromFolder => 'Случайный файл из папки',
    };
  }

  String _categoryLabel(ItemCategory category) {
    return category == ItemCategory.fun ? 'Весёлое' : 'Серьёзное';
  }

  bool _requiresPathValue(ItemType type) {
    return type == ItemType.file ||
        type == ItemType.folder ||
        type == ItemType.randomFileFromFolder;
  }

  bool _isLikelyPath(String value) {
    return value.contains(':/') ||
        value.contains(':\\') ||
        value.startsWith('/') ||
        value.startsWith('~/');
  }

  String? _validateValueForType({
    required ItemType type,
    required String value,
  }) {
    if (value.isEmpty) {
      return 'Значение обязательно';
    }

    if (type == ItemType.link) {
      final uri = Uri.tryParse(value);
      if (uri == null || !uri.hasScheme) {
        return 'Для типа "Ссылка" нужен корректный URL';
      }
    }

    if (_requiresPathValue(type) && !_isLikelyPath(value)) {
      return 'Для этого типа ожидается путь к файлу/папке';
    }

    if (type == ItemType.nestedList && !(_config?.lists.containsKey(value) ?? false)) {
      return 'Вложенный список "$value" не найден';
    }

    return null;
  }

  Future<void> _executeSelection(SelectionResult result) async {
    try {
      final message = await _executor.execute(result);
      _addLog('Execute success: ${result.item.type.name} -> ${result.item.value}');
      setState(() {
        _status = message;
        _error = null;
      });
    } catch (exception) {
      _addLog('Execute error: $exception');
      setState(() {
        _error = 'Ошибка запуска: $exception';
      });
    }
  }

  Future<void> _executeLastResult() async {
    final result = _lastResult;
    if (result == null) {
      return;
    }
    await _executeSelection(result);
  }

  Future<void> _adjustWeight(double delta) async {
    final config = _config;
    final result = _lastResult;
    if (config == null || result == null) {
      return;
    }

    final list = config.lists[result.sourceListId];
    if (list == null) {
      return;
    }

    final index = list.items.indexWhere((item) => item.id == result.item.id);
    if (index < 0) {
      return;
    }

    final oldItem = list.items[index];
    final updatedWeight = (oldItem.weight + delta).clamp(0.1, 9999.0);
    final updatedItem = oldItem.copyWith(weight: updatedWeight);
    final updatedItems = [...list.items];
    updatedItems[index] = updatedItem;

    final updatedList = list.copyWith(items: updatedItems);
    final updatedLists = {...config.lists, result.sourceListId: updatedList};
    final updatedConfig = config.copyWith(
      schemaVersion: 2,
      lists: updatedLists,
    );

    setState(() {
      _config = updatedConfig;
      _lastResult = result.copyWith(item: updatedItem);
    });

    await _persistConfig(updatedConfig);
  }

  Future<void> _saveAndApplyConfig(RandomDomConfig config) async {
    setState(() {
      _config = config;
    });
    await _persistConfig(config);
  }

  Future<void> _addList() async {
    final config = _config;
    if (config == null) {
      return;
    }

    final listNameController = TextEditingController();
    final listIdController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый список'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: listIdController,
              decoration: const InputDecoration(labelText: 'ID списка'),
            ),
            TextField(
              controller: listNameController,
              decoration: const InputDecoration(labelText: 'Название'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Создать'),
          ),
        ],
      ),
    );

    if (created != true) {
      return;
    }

    final newId = listIdController.text.trim();
    final newName = listNameController.text.trim();
    if (newId.isEmpty || newName.isEmpty) {
      setState(() {
        _error = 'ID и название списка обязательны';
      });
      return;
    }
    if (config.lists.containsKey(newId)) {
      setState(() {
        _error = 'Список с ID "$newId" уже существует';
      });
      return;
    }

    final updatedLists = {
      ...config.lists,
      newId: RandomDomList(name: newName, items: const []),
    };
    final updatedConfig = config.copyWith(schemaVersion: 2, lists: updatedLists);

    setState(() {
      _selectedListId = newId;
    });
    await _saveAndApplyConfig(updatedConfig);
  }

  Future<void> _renameCurrentList() async {
    final config = _config;
    if (config == null) {
      return;
    }

    final list = config.lists[_selectedListId];
    if (list == null) {
      return;
    }

    final nameController = TextEditingController(text: list.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать список'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Название списка'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (ok != true) {
      return;
    }

    final name = nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final updatedList = list.copyWith(name: name);
    final updatedConfig = config.copyWith(
      schemaVersion: 2,
      lists: {...config.lists, _selectedListId: updatedList},
    );
    await _saveAndApplyConfig(updatedConfig);
  }

  Future<void> _deleteCurrentList() async {
    final config = _config;
    if (config == null || config.lists.length <= 1) {
      setState(() {
        _error = 'Нужно оставить хотя бы один список';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить список?'),
        content: Text('Список "$_selectedListId" будет удалён'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final updatedLists = {...config.lists}..remove(_selectedListId);
    final nextListId = updatedLists.keys.first;
    final updatedConfig = config.copyWith(schemaVersion: 2, lists: updatedLists);

    setState(() {
      _selectedListId = nextListId;
      _lastResult = null;
    });
    await _saveAndApplyConfig(updatedConfig);
  }

  Future<String?> _pickApplication() async {
    if (!Platform.isAndroid) {
      return null;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      return null;
    }

    // Show loading dialog while fetching apps
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    List<Application> apps = [];
    try {
      apps = await DeviceAppsPlusPlugin.getInstalledApplications(
        onlyLaunchable: true,
        includeSystemApps: false,
      );
      apps.sort((a, b) => (a.appName).compareTo(b.appName));
    } catch (e) {
      _addLog('Error fetching apps: $e');
    }

    // Close loading dialog
    if (dialogContext.mounted) {
      Navigator.of(dialogContext).pop();
    }

    if (apps.isEmpty) {
      if (dialogContext.mounted) {
        await showDialog(
          context: dialogContext,
          builder: (context) => AlertDialog(
            title: const Text('Ошибка'),
            content: const Text('Не удалось получить список приложений'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return null;
    }

    // Show app picker dialog
    final selectedApp = await showDialog<Application>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Выберите приложение'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return ListTile(
                leading: app is ApplicationWithIcon
                    ? Image.memory(
                        app.icon,
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.apps),
                      )
                    : const Icon(Icons.apps),
                title: Text(app.appName),
                subtitle: Text(
                  app.packageName,
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => Navigator.of(context).pop(app),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (selectedApp != null) {
      return selectedApp.packageName;
    }
    return null;
  }

  Future<void> _upsertItem({RandomDomItem? item, required int? index}) async {
    final config = _config;
    final list = config?.lists[_selectedListId];
    if (config == null || list == null) {
      return;
    }

    final dialogContext = _navigatorKey.currentContext;
    if (dialogContext == null) {
      setState(() {
        _error = 'Не удалось открыть окно редактирования. Повторите попытку.';
      });
      _addLog('Upsert dialog skipped: navigator context is null');
      return;
    }

    ItemType selectedType = item?.type ?? ItemType.text;
    ItemCategory selectedCategory = item?.category ?? ItemCategory.serious;
    final isEditing = item != null && index != null;

    final valueController = TextEditingController(text: item?.value ?? '');
    final weightController = TextEditingController(
      text: (item?.weight ?? 1.0).toString(),
    );

    _addLog('Open fallback edit dialog: ${item?.id ?? 'new'}');
    final ok = await showDialog<bool>(
      context: dialogContext,
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEditing ? 'Редактировать элемент' : 'Добавить элемент'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ID: ${item.id}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                  DropdownButtonFormField<ItemType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(labelText: 'Тип'),
                    items: ItemType.values
                        .map(
                          (type) => DropdownMenuItem<ItemType>(
                            value: type,
                            child: Text(_typeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                  if (selectedType == ItemType.application && Platform.isAndroid)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: valueController,
                              decoration: const InputDecoration(labelText: 'Пакет приложения'),
                              readOnly: true,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.search),
                            tooltip: 'Выбрать приложение',
                            onPressed: () async {
                              final packageName = await _pickApplication();
                              if (packageName != null) {
                                setModalState(() {
                                  valueController.text = packageName;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    TextField(
                      controller: valueController,
                      decoration: const InputDecoration(labelText: 'Значение'),
                    ),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: 'Вес'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  DropdownButtonFormField<ItemCategory>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Категория'),
                    items: ItemCategory.values
                        .map(
                          (category) => DropdownMenuItem<ItemCategory>(
                            value: category,
                            child: Text(_categoryLabel(category)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(modalContext).pop(false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(modalContext).pop(true),
                child: Text(isEditing ? 'Сохранить изменения' : 'Сохранить'),
              ),
            ],
          );
        },
      ),
    );

    if (ok != true) {
      _addLog('Fallback edit dialog canceled');
      return;
    }

    final value = valueController.text.trim();
    final weight = double.tryParse(weightController.text.trim());
    final validationError = _validateValueForType(type: selectedType, value: value);
    if (validationError != null || weight == null || weight <= 0) {
      setState(() {
        _error = validationError ?? 'Вес должен быть > 0';
      });
      return;
    }

    if (_requiresPathValue(selectedType) &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final exists = selectedType == ItemType.folder || selectedType == ItemType.randomFileFromFolder
          ? Directory(value).existsSync()
          : File(value).existsSync();
      if (!exists) {
        if (!mounted) {
          return;
        }
        final pathDialogContext = _navigatorKey.currentContext;
        if (pathDialogContext == null) {
          return;
        }
        final proceed = await showDialog<bool>(
          context: pathDialogContext,
          builder: (context) => AlertDialog(
            title: const Text('Путь не найден'),
            content: Text('Путь "$value" не существует. Сохранить всё равно?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );
        if (proceed != true) {
          return;
        }
      }
    }

    final updatedItems = [...list.items];
    final updatedItem = RandomDomItem(
      id: item?.id ?? 'item_${DateTime.now().microsecondsSinceEpoch}',
      type: selectedType,
      value: value,
      weight: weight,
      category: selectedCategory,
    );

    if (index == null) {
      updatedItems.add(updatedItem);
    } else {
      updatedItems[index] = updatedItem;
    }

    final updatedList = list.copyWith(items: updatedItems);
    final updatedConfig = config.copyWith(
      schemaVersion: 2,
      lists: {...config.lists, _selectedListId: updatedList},
    );

    await _saveAndApplyConfig(updatedConfig);

    setState(() {
      _status = isEditing ? 'Элемент обновлён' : 'Элемент добавлен';
      _error = null;
    });
    _addLog(isEditing ? 'Fallback edit saved' : 'Item created from dialog');
  }

  Future<void> _editItem(int index) async {
    final config = _config;
    final list = config?.lists[_selectedListId];
    if (config == null || list == null || index < 0 || index >= list.items.length) {
      _addLog('Edit tap ignored: invalid index/list state');
      return;
    }

    final item = list.items[index];
    _addLog('Edit tap: index=$index id=${item.id} value="${item.value}"');
    setState(() {
      _editingIndex = index;
      _editingType = item.type;
      _editingCategory = item.category;
      _editingValueController.text = item.value;
      _editingWeightController.text = item.weight.toString();
      _status = 'Редактирование элемента';
      _error = null;
    });
  }

  void _cancelInlineEdit() {
    setState(() {
      _editingIndex = null;
      _status = 'Редактирование отменено';
    });
  }

  Future<void> _saveInlineEdit() async {
    final config = _config;
    final list = config?.lists[_selectedListId];
    final index = _editingIndex;
    if (config == null || list == null || index == null || index < 0 || index >= list.items.length) {
      return;
    }

    final value = _editingValueController.text.trim();
    final weight = double.tryParse(_editingWeightController.text.trim());
    final validationError = _validateValueForType(type: _editingType, value: value);
    if (validationError != null || weight == null || weight <= 0) {
      setState(() {
        _error = validationError ?? 'Вес должен быть > 0';
      });
      return;
    }

    final updatedItems = [...list.items];
    updatedItems[index] = updatedItems[index].copyWith(
      type: _editingType,
      value: value,
      weight: weight,
      category: _editingCategory,
    );

    final updatedList = list.copyWith(items: updatedItems);
    final updatedConfig = config.copyWith(
      schemaVersion: 2,
      lists: {...config.lists, _selectedListId: updatedList},
    );

    await _saveAndApplyConfig(updatedConfig);
    setState(() {
      _editingIndex = null;
      _status = 'Элемент обновлён';
      _error = null;
    });
    _addLog('Inline edit saved index=$index');
  }

  Future<void> _deleteInlineEdit() async {
    final config = _config;
    final list = config?.lists[_selectedListId];
    final index = _editingIndex;
    if (config == null || list == null || index == null || index < 0 || index >= list.items.length) {
      return;
    }

    final updatedItems = [...list.items]..removeAt(index);
    final updatedList = list.copyWith(items: updatedItems);
    final updatedConfig = config.copyWith(
      schemaVersion: 2,
      lists: {...config.lists, _selectedListId: updatedList},
    );

    await _saveAndApplyConfig(updatedConfig);
    setState(() {
      _editingIndex = null;
      _status = 'Элемент удалён';
      _error = null;
    });
    _addLog('Inline edit deleted index=$index');
  }

  Future<void> _deleteItem(int index) async {
    final config = _config;
    final list = config?.lists[_selectedListId];
    if (config == null || list == null) {
      _addLog('Delete ignored: list not available');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить элемент?'),
        content: Text('"${list.items[index].value}" будет удалён'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      _addLog('Delete canceled for index=$index');
      return;
    }

    final updatedItems = [...list.items]..removeAt(index);
    final updatedList = list.copyWith(items: updatedItems);
    final updatedConfig = config.copyWith(
      schemaVersion: 2,
      lists: {...config.lists, _selectedListId: updatedList},
    );

    await _saveAndApplyConfig(updatedConfig);
    _addLog('Deleted item index=$index');
  }

  String _describeResult() {
    final result = _lastResult;
    if (result == null) {
      return '';
    }
    if (result.resolvedFilePath != null) {
      return '${result.item.value} -> ${result.resolvedFilePath}';
    }
    return result.item.value;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'RandomDom',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('RandomDom')),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: _config == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: SizedBox(
                  height: 64,
                  child: FloatingActionButton.extended(
                    onPressed: _isSelecting ? null : _selectRandom,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
                    icon: _isSelecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.casino, size: 28),
                    label: const Text(
                      'Выбрать',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: _config == null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      )
                    else
                      const Center(child: CircularProgressIndicator()),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _createDefaultConfig,
                      child: const Text('Создать config.json автоматически'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _loadDefaultConfig,
                      child: const Text('Повторить поиск'),
                    ),
                    if (_searchedConfigPaths.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Пути, где искали config.json:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _searchedConfigPaths.length,
                          itemBuilder: (context, index) => Text('• ${_searchedConfigPaths[index]}'),
                        ),
                      ),
                    ],
                  ],
                )
              : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        Text('Настроение: ${_selectedMood == 'bad' ? 'плохо' : 'хорошо'}'),
                        const SizedBox(height: 12),
                        const Text('Список'),
                        DropdownButton<String>(
                          value: _selectedListId,
                          isExpanded: true,
                          items: _config!.lists.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedListId = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _addList,
                              child: const Text('Добавить список'),
                            ),
                            OutlinedButton(
                              onPressed: _renameCurrentList,
                              child: const Text('Переименовать'),
                            ),
                            OutlinedButton(
                              onPressed: _deleteCurrentList,
                              child: const Text('Удалить список'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isSelecting && _rollingPreview != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('Крутится: $_rollingPreview'),
                          ),
                        if (_status != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _status!,
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showDebugLog = !_showDebugLog;
                                });
                              },
                              child: Text(_showDebugLog ? 'Скрыть логи' : 'Показать логи'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _runtimeLog.isEmpty
                                  ? null
                                  : () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: _runtimeLog.join('\n')),
                                      );
                                      if (!mounted) {
                                        return;
                                      }
                                      setState(() {
                                        _status = 'Логи скопированы в буфер обмена';
                                      });
                                    },
                              icon: const Icon(Icons.copy),
                              label: const Text('Копировать логи'),
                            ),
                          ],
                        ),
                        if (_showDebugLog)
                          Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            height: 120,
                            child: ListView(
                              children: _runtimeLog.reversed.take(20).map((line) => Text(line)).toList(),
                            ),
                          ),
                        if (_lastResult != null) ...[
                          Text('Результат: ${_describeResult()}'),
                          Text('Тип: ${_typeLabel(_lastResult!.item.type)}'),
                          Text('Вес: ${_lastResult!.item.weight.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _executeLastResult,
                            child: const Text('Запустить сейчас'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () async => _adjustWeight(-0.5),
                                child: const Text('- вес'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async => _adjustWeight(0.5),
                                child: const Text('+ вес'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Элементы списка',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            ElevatedButton(
                              onPressed: () => _upsertItem(index: null),
                              child: const Text('+ Добавить'),
                            ),
                          ],
                        ),
                        if (_editingIndex != null)
                          Card(
                            margin: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Редактирование элемента',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<ItemType>(
                                    initialValue: _editingType,
                                    decoration: const InputDecoration(labelText: 'Тип'),
                                    items: ItemType.values
                                        .map(
                                          (type) => DropdownMenuItem<ItemType>(
                                            value: type,
                                            child: Text(_typeLabel(type)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _editingType = value;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _editingValueController,
                                    decoration: const InputDecoration(labelText: 'Значение'),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _editingWeightController,
                                    decoration: const InputDecoration(labelText: 'Вес'),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<ItemCategory>(
                                    initialValue: _editingCategory,
                                    decoration: const InputDecoration(labelText: 'Категория'),
                                    items: ItemCategory.values
                                        .map(
                                          (category) => DropdownMenuItem<ItemCategory>(
                                            value: category,
                                            child: Text(_categoryLabel(category)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _editingCategory = value;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: _deleteInlineEdit,
                                        icon: const Icon(Icons.delete),
                                        label: const Text('Удалить'),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _cancelInlineEdit,
                                        child: const Text('Отмена'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _saveInlineEdit,
                                        child: const Text('Сохранить'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              final currentList = _config!.lists[_selectedListId];
                              final items = currentList?.items ?? const <RandomDomItem>[];
                              if (items.isEmpty) {
                                return const Center(child: Text('Список пуст'));
                              }
                              return ListView.separated(
                                itemCount: items.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  return ListTile(
                                    onTap: () => _editItem(index),
                                    title: Text(item.value),
                                    subtitle: Text(
                                      'тип=${_typeLabel(item.type)} · категория=${_categoryLabel(item.category)} · вес=${item.weight.toStringAsFixed(2)}',
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Редактировать',
                                          onPressed: () => _editItem(index),
                                          icon: const Icon(Icons.edit),
                                        ),
                                        IconButton(
                                          tooltip: 'Удалить',
                                          onPressed: () => _deleteItem(index),
                                          icon: const Icon(Icons.delete),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}
