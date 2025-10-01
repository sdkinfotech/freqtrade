#!/bin/bash

# Скрипт для перезапуска Docker build пайплайна
# Используется после обновления Docker Hub токена

echo "🚀 Перезапуск Docker Build пайплайна..."

# Проверяем статус последнего пайплайна
echo "📊 Текущий статус пайплайна:"
curl -s "https://api.github.com/repos/sdkinfotech/freqtrade/actions/runs?per_page=1" | jq '.workflow_runs[0] | {name: .name, status: .status, conclusion: .conclusion, created_at: .created_at}'

echo ""
echo "🔄 Для перезапуска пайплайна:"
echo "1. Обновите DOCKER_PASSWORD в GitHub Secrets"
echo "2. Перейдите в Actions и нажмите 'Re-run jobs'"
echo "3. Или сделайте новый commit для автоматического запуска"
echo ""
echo "📝 GitHub Actions: https://github.com/sdkinfotech/freqtrade/actions"
echo "🔐 Secrets: https://github.com/sdkinfotech/freqtrade/settings/secrets/actions"
echo "🐳 Docker Hub: https://hub.docker.com/settings/security"
