# Сборка и установка

> Статус: проект **собирается без ошибок** (проверено: .NET SDK 8.0.426). **В игре не проверен.** Героев Deadlock пока не добавляет — только находит папку Deadlock и пишет об этом в лог.

## Быстро: install.bat

1. Скачайте репозиторий: зелёная кнопка **Code → Download ZIP**, распакуйте.
2. Закройте Risk of Rain 2, если она открыта.
3. Дважды щёлкните **install.bat**.

Скрипт сам:
- найдёт .NET SDK 8 или скачает его с dot.net в папку `.tools` рядом с проектом (без прав администратора);
- соберёт `DeadlockSurvivors.dll`;
- найдёт Risk of Rain 2 и Deadlock в библиотеках Steam (если не найдёт — спросит путь);
- поставит BepInEx 5.4.21 x64 с GitHub, если его ещё нет;
- положит плагин в `Risk of Rain 2\BepInEx\plugins\DeadlockSurvivors\`;
- запишет путь к Deadlock в `BepInEx\config\ctenadog.deadlocksurvivors.cfg`.

Файлы Deadlock никуда не копируются. Запущенную игру скрипт не закрывает — попросит закрыть самому.

Проверка: запустите Risk of Rain 2, в `BepInEx\LogOutput.log` должна быть строка `Deadlock найден`.

## Вручную

```
dotnet build src/DeadlockSurvivors -c Release
```

Результат: `src/DeadlockSurvivors/bin/Release/netstandard2.1/DeadlockSurvivors.dll`. Положите его в `Risk of Rain 2/BepInEx/plugins/` (BepInEx 5 должен быть установлен) и укажите `DeadlockFolder` в `BepInEx/config/ctenadog.deadlocksurvivors.cfg` или переменную окружения `DEADLOCK_SURVIVORS_DEADLOCK_DIR`.

Зависимости только для компиляции (в DLL не входят): BepInEx.Core 5.4.21, RiskOfRain2.GameLibs 1.3.9-r.0, UnityEngine.Modules 2021.3.33 — из nuget.org и nuget.bepinex.dev (см. `NuGet.Config`).
