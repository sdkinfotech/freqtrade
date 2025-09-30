#!/bin/bash

# Скрипт для настройки секретов GitHub для Docker Hub
# Использование: ./setup-github-secrets.sh

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "🔧 Настройка секретов GitHub для Docker Hub"

# Проверяем, что мы в правильной директории
if [ ! -f "setup.sh" ]; then
    error "Запустите скрипт из корневой директории freqtrade"
    exit 1
fi

# Проверяем наличие GitHub CLI
if ! command -v gh &> /dev/null; then
    error "GitHub CLI не установлен. Установите его для автоматической настройки секретов."
    echo "Инструкции: https://cli.github.com/manual/installation"
    echo ""
    warning "Альтернативно, настройте секреты вручную:"
    echo "1. Перейдите в https://github.com/sdkinfotech/freqtrade/settings/secrets/actions"
    echo "2. Добавьте следующие секреты:"
    echo "   - DOCKER_USERNAME: ваш Docker Hub username"
    echo "   - DOCKER_PASSWORD: ваш Docker Hub access token"
    exit 1
fi

# Проверяем аутентификацию GitHub CLI
if ! gh auth status &> /dev/null; then
    error "GitHub CLI не аутентифицирован. Выполните: gh auth login"
    exit 1
fi

log "📋 Настройка секретов для Docker Hub..."

# Запрашиваем Docker Hub credentials
echo
read -p "Введите ваш Docker Hub username: " DOCKER_USERNAME
read -s -p "Введите ваш Docker Hub access token: " DOCKER_PASSWORD
echo

if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ]; then
    error "Username и password не могут быть пустыми"
    exit 1
fi

# Проверяем доступ к репозиторию
REPO="sdkinfotech/freqtrade"
if ! gh repo view "$REPO" &> /dev/null; then
    error "Не удается получить доступ к репозиторию $REPO"
    exit 1
fi

log "🔐 Настройка секретов в GitHub..."

# Устанавливаем секреты
if gh secret set DOCKER_USERNAME --body "$DOCKER_USERNAME" --repo "$REPO"; then
    success "DOCKER_USERNAME установлен"
else
    error "Не удалось установить DOCKER_USERNAME"
    exit 1
fi

if gh secret set DOCKER_PASSWORD --body "$DOCKER_PASSWORD" --repo "$REPO"; then
    success "DOCKER_PASSWORD установлен"
else
    error "Не удалось установить DOCKER_PASSWORD"
    exit 1
fi

success "🎉 Секреты GitHub настроены успешно!"

# Показываем информацию о Docker Hub
log "🐳 Информация о Docker Hub:"
echo "  Username: $DOCKER_USERNAME"
echo "  Repository: sdkinfo999/freqtrade"
echo "  URL: https://hub.docker.com/repositories/sdkinfo999"

# Показываем следующие шаги
echo
log "📋 Следующие шаги:"
echo "  1. Проверьте секреты: https://github.com/sdkinfotech/freqtrade/settings/secrets/actions"
echo "  2. Запустите тестовую сборку: gh workflow run docker-build.yml"
echo "  3. Мониторинг: https://github.com/sdkinfotech/freqtrade/actions"
echo "  4. Проверьте Docker Hub: https://hub.docker.com/repositories/sdkinfo999"

# Показываем команды для тестирования
echo
log "🧪 Команды для тестирования:"
echo "  # Запуск сборки вручную"
echo "  gh workflow run docker-build.yml"
echo ""
echo "  # Проверка статуса workflow"
echo "  gh run list --workflow=docker-build.yml"
echo ""
echo "  # Просмотр логов"
echo "  gh run view --log"

# Показываем информацию о создании релиза
echo
log "🚀 Создание релиза:"
echo "  ./create-release.sh [version] [message]"
echo ""
echo "  Примеры:"
echo "    ./create-release.sh 2025.6"
echo "    ./create-release.sh 2025.6.1 'Bug fixes and improvements'"

success "Настройка завершена! Теперь можно создавать релизы и собирать Docker образы."
