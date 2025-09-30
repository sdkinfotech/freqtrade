#!/bin/bash

# Скрипт для синхронизации с upstream без отключения пайплайнов
# Использует специальные коммит-сообщения для пропуска пайплайнов
# Использование: ./sync-with-skip-pipelines.sh

set -e

echo "🔄 Начинаем синхронизацию с upstream (с пропуском пайплайнов)..."

# Проверяем, что мы в правильной директории
if [ ! -f "setup.sh" ]; then
    echo "❌ Ошибка: Запустите скрипт из корневой директории freqtrade"
    exit 1
fi

# Проверяем статус git
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  Внимание: Есть незакоммиченные изменения"
    echo "Текущие изменения:"
    git status --short
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Отменено пользователем"
        exit 1
    fi
fi

# Добавляем upstream remote если его нет
if ! git remote | grep -q upstream; then
    echo "➕ Добавляем upstream remote..."
    git remote add upstream https://github.com/freqtrade/freqtrade.git
fi

# Получаем последние изменения
echo "📥 Получаем изменения с upstream..."
git fetch upstream

# Синхронизируем с upstream
echo "🔄 Синхронизируем с upstream..."
CURRENT_BRANCH=$(git branch --show-current)

# Синхронизируем develop ветку
if [ "$CURRENT_BRANCH" = "develop" ]; then
    echo "📋 Синхронизируем develop ветку..."
    git merge upstream/develop --no-edit -m "Sync with upstream/develop

[skip ci] [skip actions] [skip pipeline]
This commit syncs with upstream changes and skips CI/CD pipelines"
elif [ "$CURRENT_BRANCH" = "stable" ]; then
    echo "📋 Синхронизируем stable ветку..."
    git merge upstream/stable --no-edit -m "Sync with upstream/stable

[skip ci] [skip actions] [skip pipeline]
This commit syncs with upstream changes and skips CI/CD pipelines"
else
    echo "📋 Синхронизируем develop ветку (текущая ветка: $CURRENT_BRANCH)..."
    git merge upstream/develop --no-edit -m "Sync with upstream/develop

[skip ci] [skip actions] [skip pipeline]
This commit syncs with upstream changes and skips CI/CD pipelines"
fi

echo "✅ Синхронизация завершена!"
echo "📊 Статус:"
git log --oneline -5

echo ""
echo "🚀 Следующие шаги:"
echo "   1. Проверьте изменения: git log --oneline -10"
echo "   2. Отправьте изменения: git push origin $CURRENT_BRANCH"
echo "   3. Пайплайны должны быть пропущены благодаря [skip ci] в коммите"
