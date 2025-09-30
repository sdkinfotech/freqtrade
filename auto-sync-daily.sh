#!/bin/bash

# Автоматическая синхронизация с upstream
# Использование: ./auto-sync-daily.sh
# Для автоматического запуска добавьте в crontab:
# 0 3 * * * /path/to/freqtrade/auto-sync-daily.sh >> /var/log/freqtrade-sync.log 2>&1

set -e

# Настройки
REPO_PATH="/home/antsdk/pro/algotrading/freqtrade"
LOG_FILE="/var/log/freqtrade-sync.log"
EMAIL_NOTIFICATIONS="false"  # Установите true для email уведомлений
EMAIL_ADDRESS="your-email@example.com"

# Функция для логирования
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Функция для отправки email (если настроено)
send_notification() {
    if [ "$EMAIL_NOTIFICATIONS" = "true" ] && command -v mail >/dev/null 2>&1; then
        echo "$1" | mail -s "Freqtrade Auto-Sync Report" "$EMAIL_ADDRESS"
    fi
}

log "🔄 Starting automatic sync with upstream..."

# Проверяем, что мы в правильной директории
if [ ! -f "$REPO_PATH/setup.sh" ]; then
    log "❌ Error: Repository not found at $REPO_PATH"
    exit 1
fi

cd "$REPO_PATH"

# Проверяем статус git
if [ -n "$(git status --porcelain)" ]; then
    log "⚠️  Warning: Uncommitted changes detected"
    log "Current changes:"
    git status --short | tee -a "$LOG_FILE"
    
    # Если есть незакоммиченные изменения, пропускаем синхронизацию
    log "❌ Skipping sync due to uncommitted changes"
    send_notification "Freqtrade auto-sync skipped due to uncommitted changes"
    exit 1
fi

# Добавляем upstream remote если его нет
if ! git remote | grep -q upstream; then
    log "➕ Adding upstream remote..."
    git remote add upstream https://github.com/freqtrade/freqtrade.git
fi

# Получаем последние изменения
log "📥 Fetching changes from upstream..."
git fetch upstream

# Проверяем, нужна ли синхронизация
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse upstream/develop)

if [ "$LOCAL" = "$REMOTE" ]; then
    log "✅ Repository is already up to date"
    send_notification "Freqtrade repository is up to date - no sync needed"
    exit 0
fi

log "🔄 Sync needed - upstream has new commits"

# Отключаем пайплайны
log "🚫 Temporarily disabling workflows..."
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        mv "$workflow" "${workflow}.disabled"
        log "   Disabled: $(basename "$workflow")"
    fi
done

# Коммитим отключение пайплайнов
if [ -n "$(git status --porcelain)" ]; then
    log "💾 Committing disabled workflows..."
    git add .github/workflows/*.disabled
    git commit -m "Disable workflows for auto-sync

- Temporarily disabled all GitHub Actions workflows
- This prevents CI/CD pipelines from running during auto-sync
- Workflows will be re-enabled after sync completion"
fi

# Синхронизируем с upstream
log "🔄 Syncing with upstream/develop..."
git merge upstream/develop --no-edit -m "Auto-sync with upstream/develop

[skip ci] [skip actions] [skip pipeline]
Automated daily sync with upstream repository"

# Включаем пайплайны обратно
log "✅ Re-enabling workflows..."
for workflow in .github/workflows/*.disabled; do
    if [ -f "$workflow" ]; then
        mv "$workflow" "${workflow%.disabled}"
        log "   Enabled: $(basename "${workflow%.disabled}")"
    fi
done

# Коммитим включение пайплайнов
if [ -n "$(git status --porcelain)" ]; then
    log "💾 Committing re-enabled workflows..."
    git add .github/workflows/*.yml
    git commit -m "Re-enable workflows after auto-sync

- Re-enabled all GitHub Actions workflows
- Auto-sync completed successfully
- CI/CD pipelines are now active again"
fi

# Отправляем изменения
log "🚀 Pushing changes..."
git push origin develop

# Логируем результат
log "✅ Auto-sync completed successfully!"
log "📊 Recent commits:"
git log --oneline -5 | tee -a "$LOG_FILE"

# Отправляем уведомление об успехе
send_notification "Freqtrade auto-sync completed successfully!

Recent commits:
$(git log --oneline -5)

Repository is now up to date with upstream."

log "📧 Notification sent (if configured)"
