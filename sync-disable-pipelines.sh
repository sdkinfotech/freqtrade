#!/bin/bash

# Скрипт для синхронизации с upstream и отключения пайплайнов
# Использование: ./sync-disable-pipelines.sh

set -e

echo "🔄 Начинаем синхронизацию с upstream..."

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

# Отключаем пайплайны
echo "🚫 Отключаем пайплайны..."
if [ -d ".github/workflows" ]; then
    for workflow in .github/workflows/*.yml; do
        if [ -f "$workflow" ]; then
            mv "$workflow" "${workflow}.disabled"
            echo "   Отключен: $(basename "$workflow")"
        fi
    done
fi

# Создаем коммит с отключенными пайплайнами
if [ -n "$(git status --porcelain)" ]; then
    echo "💾 Коммитим отключение пайплайнов..."
    git add .github/workflows/*.disabled
    git commit -m "Disable workflows for upstream sync

- Temporarily disabled all GitHub Actions workflows
- This prevents CI/CD pipelines from running during upstream sync
- Workflows will be re-enabled after sync completion"
fi

# Синхронизируем с upstream
echo "🔄 Синхронизируем с upstream..."
CURRENT_BRANCH=$(git branch --show-current)

# Синхронизируем develop ветку
if [ "$CURRENT_BRANCH" = "develop" ]; then
    echo "📋 Синхронизируем develop ветку..."
    git merge upstream/develop --no-edit
elif [ "$CURRENT_BRANCH" = "stable" ]; then
    echo "📋 Синхронизируем stable ветку..."
    git merge upstream/stable --no-edit
else
    echo "📋 Синхронизируем develop ветку (текущая ветка: $CURRENT_BRANCH)..."
    git merge upstream/develop --no-edit
fi

# Включаем пайплайны обратно
echo "✅ Включаем пайплайны обратно..."
if [ -d ".github/workflows" ]; then
    for workflow in .github/workflows/*.disabled; do
        if [ -f "$workflow" ]; then
            mv "$workflow" "${workflow%.disabled}"
            echo "   Включен: $(basename "${workflow%.disabled}")"
        fi
    done
fi

# Коммитим включение пайплайнов
if [ -n "$(git status --porcelain)" ]; then
    echo "💾 Коммитим включение пайплайнов..."
    git add .github/workflows/*.yml
    git commit -m "Re-enable workflows after upstream sync

- Re-enabled all GitHub Actions workflows
- Upstream sync completed successfully
- CI/CD pipelines are now active again"
fi

echo "✅ Синхронизация завершена!"
echo "📊 Статус:"
git log --oneline -5

echo ""
echo "🚀 Следующие шаги:"
echo "   1. Проверьте изменения: git log --oneline -10"
echo "   2. Отправьте изменения: git push origin $CURRENT_BRANCH"
echo "   3. Проверьте, что пайплайны работают корректно"
