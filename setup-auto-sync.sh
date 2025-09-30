#!/bin/bash

# Скрипт для настройки автоматической синхронизации через cron
# Использование: ./setup-auto-sync.sh

set -e

echo "🔧 Настройка автоматической синхронизации..."

REPO_PATH="/home/antsdk/pro/algotrading/freqtrade"
SCRIPT_PATH="$REPO_PATH/auto-sync-daily.sh"
LOG_FILE="/var/log/freqtrade-sync.log"

# Проверяем, что скрипт существует
if [ ! -f "$SCRIPT_PATH" ]; then
    echo "❌ Ошибка: Скрипт auto-sync-daily.sh не найден в $REPO_PATH"
    exit 1
fi

# Делаем скрипт исполняемым
chmod +x "$SCRIPT_PATH"
echo "✅ Скрипт сделан исполняемым"

# Создаем директорию для логов если её нет
sudo mkdir -p "$(dirname "$LOG_FILE")"
sudo touch "$LOG_FILE"
sudo chown $(whoami):$(whoami) "$LOG_FILE"
echo "✅ Лог файл создан: $LOG_FILE"

# Проверяем существующие cron задачи
echo "📋 Текущие cron задачи:"
crontab -l 2>/dev/null || echo "Нет cron задач"

echo ""
echo "🔧 Настройка cron задачи..."

# Создаем временный файл с cron задачей
TEMP_CRON=$(mktemp)

# Сохраняем существующие задачи
crontab -l 2>/dev/null > "$TEMP_CRON" || true

# Добавляем новую задачу (если её еще нет)
CRON_JOB="0 3 * * * $SCRIPT_PATH >> $LOG_FILE 2>&1"

if ! grep -q "auto-sync-daily.sh" "$TEMP_CRON" 2>/dev/null; then
    echo "$CRON_JOB" >> "$TEMP_CRON"
    echo "✅ Добавлена cron задача: $CRON_JOB"
else
    echo "⚠️  Cron задача уже существует"
fi

# Устанавливаем новые cron задачи
crontab "$TEMP_CRON"
rm "$TEMP_CRON"

echo ""
echo "✅ Автоматическая синхронизация настроена!"
echo ""
echo "📋 Детали:"
echo "   - Время запуска: каждый день в 3:00"
echo "   - Скрипт: $SCRIPT_PATH"
echo "   - Лог файл: $LOG_FILE"
echo ""
echo "🔍 Проверка настроек:"
echo "   - Просмотр cron задач: crontab -l"
echo "   - Просмотр логов: tail -f $LOG_FILE"
echo "   - Ручной запуск: $SCRIPT_PATH"
echo ""
echo "⚙️  Дополнительные настройки:"
echo "   - Изменить время: отредактируйте crontab (crontab -e)"
echo "   - Отключить: удалите строку из crontab"
echo "   - Email уведомления: настройте в $SCRIPT_PATH"
