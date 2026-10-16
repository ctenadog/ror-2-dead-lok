# Preflight перед каждой сборкой

1. Наложить все листы из `sheets/` друг на друга.
2. Выписать каждую ячейку `null` или `"status": "unverified"`.
3. Выписать неразрешённые ссылки: `heroes.abilities[]` → `abilities.id`, `abilities.slot` → `slots.id`, `heroes.assets` → `asset_bindings.id`, `heroes.balance` → `balance.id`.
4. Собирать только когда список пуст.

Сейчас список НЕ пуст: пути ассетов, баланс и убираемые способности не проверены по файлам игры.
