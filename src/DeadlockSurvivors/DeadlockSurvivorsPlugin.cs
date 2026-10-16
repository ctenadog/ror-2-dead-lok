// НЕ СОБРАНО И НЕ ПРОВЕРЕНО. Заготовка плагина BepInEx 5 для Risk of Rain 2.
using System;
using System.IO;
using BepInEx;

namespace DeadlockSurvivors
{
    [BepInPlugin("ctenadog.deadlocksurvivors", "Deadlock Survivors", "0.0.1")]
    public class DeadlockSurvivorsPlugin : BaseUnityPlugin
    {
        // Папку Deadlock передаёт Melty через recipe ({game:deadlock}).
        private const string DeadlockPathEnv = "DEADLOCK_SURVIVORS_DEADLOCK_DIR";

        private void Awake()
        {
            var dir = Environment.GetEnvironmentVariable(DeadlockPathEnv);
            if (string.IsNullOrEmpty(dir) || !Directory.Exists(dir))
            {
                Logger.LogError("Папка Deadlock не передана.");
                return;
            }
            Logger.LogInfo($"Deadlock: {dir}");
            // TODO по sheets/: чтение VPK, кэш ассетов, генерация и регистрация выживших, test mode.
        }
    }
}
