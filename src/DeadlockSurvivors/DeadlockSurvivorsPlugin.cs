// СОБИРАЕТСЯ, НО НЕ ПРОВЕРЕНО В ИГРЕ. Героев Deadlock пока не добавляет.
using System;
using System.IO;
using System.Text;
using BepInEx;

namespace DeadlockSurvivors
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    public class DeadlockSurvivorsPlugin : BaseUnityPlugin
    {
        public const string PluginGuid = "ctenadog.deadlocksurvivors";
        public const string PluginName = "Deadlock Survivors";
        public const string PluginVersion = "0.0.2";

        // Метка, по которой строки мода легко найти в BepInEx\LogOutput.log (Ctrl+F "[DS ").
        public const string LogTag = "[DS " + PluginVersion + "]";

        // Папка Deadlock: переменная окружения или настройка в BepInEx/config.
        private const string DeadlockPathEnv = "DEADLOCK_SURVIVORS_DEADLOCK_DIR";

        // Отдельный лог мода рядом с DLL. Перезаписывается при каждом запуске игры.
        private static string _ownLogPath;

        private void Awake()
        {
            OpenOwnLog();
            LogI("Запуск. Версия " + PluginVersion + ", DLL: " + Info.Location);

            var cfgPath = Config.Bind("General", "DeadlockFolder", "",
                "Папка установки Deadlock (если не задана переменная " + DeadlockPathEnv + ")");

            var dir = Environment.GetEnvironmentVariable(DeadlockPathEnv);
            var source = "переменная " + DeadlockPathEnv;
            if (string.IsNullOrEmpty(dir)) { dir = cfgPath.Value; source = "конфиг " + PluginGuid + ".cfg"; }

            if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir))
            {
                LogE("Папка Deadlock не найдена (" + source + "). Укажите её в BepInEx/config/" + PluginGuid + ".cfg");
                return;
            }

            var vpk = Path.Combine(dir, "game", "citadel", "pak01_dir.vpk");
            if (File.Exists(vpk)) LogI("Deadlock найден: " + vpk + " (из: " + source + ")");
            else LogW("Папка задана, но pak01_dir.vpk не найден: " + vpk);

            // TODO по sheets/: чтение VPK, кэш ассетов, генерация и регистрация выживших.
            LogI("Готово. Героев пока не добавлено (заготовка).");
        }

        // ---- Логирование с меткой ----

        private void LogI(string msg) { Logger.LogInfo(LogTag + " " + msg); Own("INFO ", msg); }
        private void LogW(string msg) { Logger.LogWarning(LogTag + " " + msg); Own("WARN ", msg); }
        private void LogE(string msg) { Logger.LogError(LogTag + " " + msg); Own("ERROR", msg); }

        private void OpenOwnLog()
        {
            try
            {
                var dllDir = Path.GetDirectoryName(Info.Location);
                _ownLogPath = Path.Combine(dllDir ?? Paths.PluginPath, "DeadlockSurvivors.log");
                File.WriteAllText(_ownLogPath,
                    "=== " + PluginName + " " + PluginVersion + " | " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + " ===\r\n",
                    new UTF8Encoding(false));
            }
            catch (Exception e)
            {
                _ownLogPath = null;
                Logger.LogWarning(LogTag + " Не удалось создать DeadlockSurvivors.log: " + e.Message);
            }
        }

        private static void Own(string level, string msg)
        {
            if (_ownLogPath == null) return;
            try
            {
                File.AppendAllText(_ownLogPath,
                    DateTime.Now.ToString("HH:mm:ss.fff") + " " + level + " " + LogTag + " " + msg + "\r\n",
                    new UTF8Encoding(false));
            }
            catch { /* лог не должен ронять мод */ }
        }
    }
}
