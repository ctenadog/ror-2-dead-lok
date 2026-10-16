# Сборка и ручная установка

> Статус: проект **собирается без ошибок** (проверено: .NET SDK 8.0.426, Linux). **В игре не проверен.** Героев Deadlock пока не добавляет — только находит папку Deadlock и пишет об этом в лог.

## Сборка

1. Установите .NET SDK 8: https://dotnet.microsoft.com/download/dotnet/8.0
2. В корне репозитория:

```
dotnet build src/DeadlockSurvivors -c Release
```

Результат: `src/DeadlockSurvivors/bin/Release/netstandard2.1/DeadlockSurvivors.dll`.

Зависимости (только для компиляции, в DLL не входят): BepInEx.Core 5.4.21, RiskOfRain2.GameLibs 1.3.9-r.0, UnityEngine.Modules 2021.3.33 — из nuget.org и nuget.bepinex.dev (см. `NuGet.Config`).

## Ручная установка (без Melty)

1. Установите BepInEx 5 в папку Risk of Rain 2 (например, через r2modman или вручную с https://github.com/BepInEx/BepInEx/releases, версия 5.x, x64).
2. Положите `DeadlockSurvivors.dll` в `Risk of Rain 2/BepInEx/plugins/`.
3. Запустите игру один раз, закройте. Откройте `Risk of Rain 2/BepInEx/config/ctenadog.deadlocksurvivors.cfg` и укажите `DeadlockFolder` — папку установки Deadlock (та, где лежит папка `game`).
4. Запустите игру. В `BepInEx/LogOutput.log` должно появиться `Deadlock найден: ...pak01_dir.vpk`.

Вместо настройки можно задать переменную окружения `DEADLOCK_SURVIVORS_DEADLOCK_DIR`.
