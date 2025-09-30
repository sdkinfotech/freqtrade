#!/bin/bash

# Скрипт для модификации пайплайнов с добавлением условия пропуска
# Использование: ./modify-pipelines-for-skip.sh

set -e

echo "🔧 Модифицируем пайплайны для поддержки пропуска..."

# Проверяем, что мы в правильной директории
if [ ! -f "setup.sh" ]; then
    echo "❌ Ошибка: Запустите скрипт из корневой директории freqtrade"
    exit 1
fi

# Создаем бэкап оригинальных пайплайнов
echo "💾 Создаем бэкап оригинальных пайплайнов..."
if [ ! -d ".github/workflows.backup" ]; then
    cp -r .github/workflows .github/workflows.backup
    echo "   Бэкап создан в .github/workflows.backup"
fi

# Модифицируем каждый пайплайн
echo "🔧 Модифицируем пайплайны..."
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        echo "   Обрабатываем: $(basename "$workflow")"
        
        # Создаем временный файл
        temp_file=$(mktemp)
        
        # Добавляем условие пропуска в начало пайплайна
        cat > "$temp_file" << 'EOF'
# Условие для пропуска пайплайна при синхронизации с upstream
if: ${{ !contains(github.event.head_commit.message, '[skip ci]') && !contains(github.event.head_commit.message, '[skip actions]') && !contains(github.event.head_commit.message, '[skip pipeline]') }}

EOF
        
        # Добавляем содержимое оригинального файла
        cat "$workflow" >> "$temp_file"
        
        # Заменяем оригинальный файл
        mv "$temp_file" "$workflow"
    fi
done

echo "✅ Модификация завершена!"
echo ""
echo "📋 Что было сделано:"
echo "   - Создан бэкап в .github/workflows.backup"
echo "   - Добавлено условие пропуска во все пайплайны"
echo "   - Пайплайны будут пропущены при коммитах с [skip ci], [skip actions] или [skip pipeline]"
echo ""
echo "🚀 Теперь можно использовать sync-with-skip-pipelines.sh для синхронизации"
