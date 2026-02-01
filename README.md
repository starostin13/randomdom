# RandomDom - Случайный выбор дел

Кросс-платформенное приложение для случайного выбора задач/дел из списков.
Работает на Windows PC и Android устройствах.

## Возможности

- ✅ Работает на Windows и Android
- ✅ Множество списков задач
- ✅ Вложенные списки
- ✅ Поддержка разных типов элементов:
  - Текстовые задачи
  - Ссылки (открываются в браузере)
  - Папки (выбор случайного файла)
  - Android приложения (только на Android)

## Установка

### Windows

1. Убедитесь, что установлен Python 3.6+:
```bash
python --version
```

2. Скачайте файлы:
```bash
git clone https://github.com/starostin13/randomdom.git
cd randomdom
```

3. Запустите приложение:
```bash
python randomdom.py
```

### Android (Termux)

1. Установите Termux из F-Droid или Google Play

2. В Termux установите Python и Git:
```bash
pkg install python git
```

3. Скачайте приложение:
```bash
git clone https://github.com/starostin13/randomdom.git
cd randomdom
```

4. Запустите:
```bash
python randomdom.py
```

Для работы с приложениями Android в Termux может потребоваться Termux:API.

## Использование

### Интерактивный режим

Просто запустите без параметров:
```bash
python randomdom.py
```

Или явно с флагом `-i`:
```bash
python randomdom.py -i
```

### Командная строка

Выбрать задачу из конкретного списка:
```bash
python randomdom.py --list main
python randomdom.py --list work_tasks
```

Использовать свой файл конфигурации:
```bash
python randomdom.py --config my_config.json
```

## Конфигурация

Конфигурация хранится в файле `config.json`. Пример структуры:

```json
{
  "lists": {
    "main": {
      "name": "Основные дела",
      "items": [
        {
          "type": "text",
          "value": "Сделать зарядку"
        },
        {
          "type": "link",
          "value": "https://github.com"
        },
        {
          "type": "nested_list",
          "value": "work_tasks"
        },
        {
          "type": "folder",
          "value": "~/Documents"
        },
        {
          "type": "application",
          "value": "com.android.chrome/.Main"
        }
      ]
    },
    "work_tasks": {
      "name": "Рабочие задачи",
      "items": [
        {
          "type": "text",
          "value": "Проверить почту"
        }
      ]
    }
  }
}
```

### Типы элементов

#### `text` - Текстовая задача
```json
{
  "type": "text",
  "value": "Описание задачи"
}
```

#### `link` - Ссылка
Открывается в браузере по умолчанию:
```json
{
  "type": "link",
  "value": "https://example.com"
}
```

#### `folder` - Папка
Выбирается и открывается случайный файл из папки:
```json
{
  "type": "folder",
  "value": "/path/to/folder"
}
```
Можно использовать `~` для домашней директории.

#### `nested_list` - Вложенный список
Переход к другому списку:
```json
{
  "type": "nested_list",
  "value": "название_списка"
}
```

#### `application` - Android приложение
Запускает приложение на Android (работает только на Android):
```json
{
  "type": "application",
  "value": "com.package.name/.ActivityName"
}
```

Для получения имени пакета и активности используйте:
```bash
# В Termux
pm list packages  # список всех пакетов
dumpsys package <package_name> | grep -A 1 "android.intent.action.MAIN"
```

## Примеры использования

### Пример 1: Простой список задач
```json
{
  "lists": {
    "daily": {
      "name": "Ежедневные задачи",
      "items": [
        {"type": "text", "value": "Зарядка 15 минут"},
        {"type": "text", "value": "Медитация 10 минут"},
        {"type": "text", "value": "Прочитать 20 страниц"}
      ]
    }
  }
}
```

### Пример 2: Вложенные списки
```json
{
  "lists": {
    "main": {
      "name": "Главное меню",
      "items": [
        {"type": "nested_list", "value": "work"},
        {"type": "nested_list", "value": "hobby"},
        {"type": "text", "value": "Отдохнуть"}
      ]
    },
    "work": {
      "name": "Работа",
      "items": [
        {"type": "text", "value": "Код ревью"},
        {"type": "text", "value": "Написать документацию"}
      ]
    },
    "hobby": {
      "name": "Хобби",
      "items": [
        {"type": "text", "value": "Рисование"},
        {"type": "text", "value": "Игра на гитаре"}
      ]
    }
  }
}
```

### Пример 3: Мультимедиа
```json
{
  "lists": {
    "media": {
      "name": "Случайное медиа",
      "items": [
        {"type": "folder", "value": "~/Music"},
        {"type": "folder", "value": "~/Videos"},
        {"type": "link", "value": "https://www.youtube.com"}
      ]
    }
  }
}
```

## Компиляция в исполняемый файл (опционально)

Для создания standalone приложения можно использовать PyInstaller:

### Windows
```bash
pip install pyinstaller
pyinstaller --onefile randomdom.py
```
Исполняемый файл будет в папке `dist/`.

### Android
На Android рекомендуется использовать как Python скрипт через Termux.

## Лицензия

MIT License

## Вклад

Приветствуются pull requests и issues на GitHub!
