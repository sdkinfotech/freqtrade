#!/bin/bash

# Скрипт для создания релизных тегов и запуска сборки Docker образов
# Использование: ./create-release.sh [version] [message]

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
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

# Проверяем, что мы в правильной директории
if [ ! -f "setup.sh" ]; then
    error "Запустите скрипт из корневой директории freqtrade"
    exit 1
fi

# Получаем параметры
VERSION="$1"
MESSAGE="$2"

# Если версия не указана, используем текущую из кода
if [ -z "$VERSION" ]; then
    VERSION=$(python -c "import sys; sys.path.append('.'); from freqtrade import __version__; print(__version__)")
    log "Версия не указана, используем версию из кода: $VERSION"
fi

# Если сообщение не указано, создаем стандартное
if [ -z "$MESSAGE" ]; then
    MESSAGE="Release $VERSION"
fi

log "🚀 Создание релиза $VERSION"

# Проверяем статус git
if [ -n "$(git status --porcelain)" ]; then
    error "Есть незакоммиченные изменения. Сначала закоммитьте их."
    git status --short
    exit 1
fi

# Проверяем, что мы на правильной ветке
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "stable" ] && [ "$CURRENT_BRANCH" != "develop" ]; then
    warning "Вы находитесь на ветке '$CURRENT_BRANCH'. Рекомендуется создавать релизы с ветки 'stable'"
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Отменено пользователем"
        exit 1
    fi
fi

# Проверяем, что тег не существует
if git tag -l | grep -q "^$VERSION$"; then
    error "Тег $VERSION уже существует"
    exit 1
fi

# Получаем информацию о коммите
COMMIT_SHA=$(git rev-parse HEAD)
COMMIT_MESSAGE=$(git log -1 --pretty=%B)

log "📋 Информация о релизе:"
log "  Версия: $VERSION"
log "  Коммит: $COMMIT_SHA"
log "  Сообщение: $MESSAGE"
log "  Ветка: $CURRENT_BRANCH"

# Подтверждение
echo
read -p "Создать релизный тег $VERSION? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Отменено пользователем"
    exit 1
fi

# Создаем аннотированный тег
log "🏷️ Создание тега $VERSION..."
git tag -a "$VERSION" -m "$MESSAGE

Версия: $VERSION
Коммит: $COMMIT_SHA
Дата: $(date)
Ветка: $CURRENT_BRANCH

$COMMIT_MESSAGE"

success "Тег $VERSION создан успешно"

# Отправляем тег
log "📤 Отправка тега в удаленный репозиторий..."
git push origin "$VERSION"

success "Тег $VERSION отправлен в удаленный репозиторий"

# Проверяем, есть ли GitHub Actions
if [ -f ".github/workflows/docker-build.yml" ]; then
    log "🐳 GitHub Actions настроены. Docker образы будут собраны автоматически."
    log "Мониторинг: https://github.com/sdkinfotech/freqtrade/actions"
else
    warning "GitHub Actions не найдены. Docker образы не будут собраны автоматически."
fi

# Показываем информацию о Docker образах
log "🐳 Docker образы будут доступны по следующим тегам:"
echo "  sdkinfo999/freqtrade:$VERSION"
echo "  sdkinfo999/freqtrade:$VERSION"
echo "  sdkinfo999/freqtrade-freqai:$VERSION"
echo "  sdkinfo999/freqtrade-freqai-rl:$VERSION"
echo "  sdkinfo999/freqtrade-plot:$VERSION"

# Показываем ссылки
log "🔗 Полезные ссылки:"
echo "  GitHub: https://github.com/sdkinfotech/freqtrade/releases/tag/$VERSION"
echo "  Docker Hub: https://hub.docker.com/repositories/sdkinfo999"
echo "  Actions: https://github.com/sdkinfotech/freqtrade/actions"

success "🎉 Релиз $VERSION создан успешно!"

# Показываем следующие шаги
echo
log "📋 Следующие шаги:"
echo "  1. Проверьте GitHub Actions для сборки Docker образов"
echo "  2. Проверьте Docker Hub для публикации образов"
echo "  3. Создайте Release Notes в GitHub (опционально)"
echo "  4. Уведомите пользователей о новом релизе"

# Показываем команды для проверки
echo
log "🔍 Команды для проверки:"
echo "  git tag -l | grep $VERSION"
echo "  git show $VERSION"
echo "  docker pull sdkinfo999/freqtrade:$VERSION"
