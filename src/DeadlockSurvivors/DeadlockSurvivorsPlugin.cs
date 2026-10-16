// СОБИРАЕТСЯ, НО НЕ ПРОВЕРЕНО В ИГРЕ. Героев Deadlock пока не добавляет.
using System;
using System.IO;
using BepInEx;

namespace DeadlockSurvivors
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    public class DeadlockSurvivorsPlugin : BaseUnityPlugin
    {
        public const string PluginGuid = "ctenadog.deadlocksurvivors";
        public const string PluginName = "Deadlock Survivors";
        public const string PluginVersion = "0.0.1";

        // Папка Deadlock: переменная окружения или настройка в BepInEx/config.
        private const string DeadlockPathEnv = "DEADLOCK_SURVIVORS_DEADLOCK_DIR";

        private void Awake()
        {
            var cfgPath = Config.Bind("General", "DeadlockFolder", "",
                "Папка установки Deadlock (если не задана переменная " + DeadlockPathEnv + ")");

            var dir = Environment.GetEnvironmentVariable(DeadlockPathEnv);
            if (string.IsNullOrEmpty(dir)) dir = cfgPath.Value;

            if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir))
            {
                Logger.LogError("Папка Deadlock не найдена. Укажите её в BepInEx/config/" + PluginGuid + ".cfg");
                return;
            }

            var vpk = Path.Combine(dir, "game", "citadel", "pak01_dir.vpk");
            Logger.LogInfo(File.Exists(vpk)
                ? "Deadlock найден: " + vpk
                : "Папка задана, но pak01_dir.vpk не найден: " + vpk);

            // TODO по sheets/: чтение VPK, кэш ассетов, генерация и регистрация выживших.
        }
    }
}
