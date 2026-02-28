# RandomDom Flutter

Flutter-приложение RandomDom с единым UI для Windows и Android.

## Что реализовано

- Автопереключение светлой/тёмной темы под системную
- Редактор списков и элементов (CRUD)
- Веса и категории задач (`fun` / `serious`)
- Быстрое изменение веса после выпадения (`+/-`)
- Вопрос о настроении и mood multiplier
- Анимация запуска случайного выбора
- Поддержка типов действий:
  - `text`
  - `link`
  - `file`
  - `folder`
  - `application`
  - `nested_list`
  - `random_file_from_folder` (рекурсивно)
- Сохранение изменений в `../config.json`
- Умный поиск `config.json` (рядом с приложением, в рабочей папке, в app documents)
- Экран восстановления при отсутствии конфига (создать `config.json` автоматически)

## Быстрый запуск

```bash
flutter pub get
flutter run -d windows
```

или

```bash
flutter run -d android
```

## Сборка Windows (portable)

В папке `flutter_app` запустите:

```bat
build_windows_portable.bat
```

Результат:

- Портативная папка: `flutter_app\release\windows-portable`
- EXE: `flutter_app\release\windows-portable\randomdom_flutter.exe`

Скрипт автоматически:

1. Копирует проект в `C:\dev\randomdom_win_build` (обход блокировок OneDrive)
2. Выполняет `flutter pub get`
3. Выполняет `flutter build windows --release`
4. Собирает portable-выход и копирует `config.json`

