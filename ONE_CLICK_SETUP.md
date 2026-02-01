# Настройка запуска в один клик / One-Click Launch Setup

## Русский 🇷🇺

### Для Android (Termux)

#### Способ 1: Termux:Widget (РЕКОМЕНДУЕТСЯ для запуска одним кликом)

1. **Установите Termux:Widget** из F-Droid или Google Play
   - Это позволит запускать скрипты прямо с домашнего экрана Android!

2. **Создайте папку для виджетов:**
   ```bash
   mkdir -p ~/.shortcuts
   ```

3. **Скопируйте скрипт виджета:**
   ```bash
   cp ~/randomdom/randomdom-widget.sh ~/.shortcuts/RandomDom
   chmod +x ~/.shortcuts/RandomDom
   ```

4. **Добавьте виджет на домашний экран:**
   - Долгое нажатие на рабочий стол → Виджеты → Termux:Widget
   - Выберите "RandomDom" из списка
   - Теперь одно нажатие запускает случайное дело! ✨

#### Способ 2: Termux ярлык

1. **В Termux создайте ярлык:**
   ```bash
   termux-create-shortcut ~/randomdom/quick-start.sh RandomDom
   ```

2. Ярлык появится в списке приложений Android

#### Способ 3: Быстрый запуск из Termux

Просто запустите:
```bash
~/randomdom/quick-start.sh
```

### Для Windows

#### Способ 1: Двойной клик (САМЫЙ ПРОСТОЙ)

1. Найдите файл `quick-start.bat` в папке randomdom
2. **Дважды кликните по нему** - всё!
3. Никаких командных строк не нужно!

**Дополнительно:** Создайте ярлык на рабочем столе:
- Правый клик на `quick-start.bat` → Отправить → Рабочий стол (создать ярлык)
- Теперь можно запускать прямо с рабочего стола!

#### Способ 2: Создать .vbs файл для запуска без окна командной строки

Создайте файл `randomdom-silent.vbs` с таким содержимым:
```vbs
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd /c cd /d """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & """ && python randomdom.py --list main", 0, True
CreateObject("WScript.Shell").Popup "Задача выбрана! Проверьте браузер или другие приложения.", 3, "RandomDom", 64
```

Двойной клик на этом файле запустит программу незаметно в фоне!

### Для Linux

Просто запустите:
```bash
./quick-start.sh
```

Или создайте desktop-ярлык (создайте файл `randomdom.desktop`):
```desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=RandomDom
Comment=Random Task Selector
Exec=/path/to/randomdom/quick-start.sh
Icon=utilities-terminal
Terminal=true
Categories=Utility;
```

---

## English 🇬🇧

### For Android (Termux)

#### Method 1: Termux:Widget (RECOMMENDED for one-click launch)

1. **Install Termux:Widget** from F-Droid or Google Play
   - This allows you to run scripts directly from your Android home screen!

2. **Create shortcuts folder:**
   ```bash
   mkdir -p ~/.shortcuts
   ```

3. **Copy the widget script:**
   ```bash
   cp ~/randomdom/randomdom-widget.sh ~/.shortcuts/RandomDom
   chmod +x ~/.shortcuts/RandomDom
   ```

4. **Add widget to home screen:**
   - Long press on home screen → Widgets → Termux:Widget
   - Select "RandomDom" from the list
   - Now one tap launches a random task! ✨

#### Method 2: Termux Shortcut

1. **Create a shortcut in Termux:**
   ```bash
   termux-create-shortcut ~/randomdom/quick-start.sh RandomDom
   ```

2. The shortcut will appear in your Android app list

#### Method 3: Quick launch from Termux

Simply run:
```bash
~/randomdom/quick-start.sh
```

### For Windows

#### Method 1: Double-Click (EASIEST)

1. Find the `quick-start.bat` file in the randomdom folder
2. **Double-click it** - that's it!
3. No command line needed!

**Extra:** Create a desktop shortcut:
- Right-click on `quick-start.bat` → Send to → Desktop (create shortcut)
- Now you can launch directly from your desktop!

#### Method 2: Create a .vbs file for silent execution (no command window)

Create a file `randomdom-silent.vbs` with this content:
```vbs
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "cmd /c cd /d """ & CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName) & """ && python randomdom.py --list main", 0, True
CreateObject("WScript.Shell").Popup "Task selected! Check your browser or other apps.", 3, "RandomDom", 64
```

Double-click this file to run the program silently in the background!

### For Linux

Simply run:
```bash
./quick-start.sh
```

Or create a desktop shortcut (create `randomdom.desktop` file):
```desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=RandomDom
Comment=Random Task Selector
Exec=/path/to/randomdom/quick-start.sh
Icon=utilities-terminal
Terminal=true
Categories=Utility;
```

---

## Изменение списка по умолчанию / Changing the Default List

Если вы хотите использовать другой список вместо "main":
If you want to use a different list instead of "main":

**В файле quick-start / In quick-start files:**
Измените `--list main` на `--list your_list_name`
Change `--list main` to `--list your_list_name`

**Пример / Example:**
```bash
python randomdom.py --list work_tasks
```
