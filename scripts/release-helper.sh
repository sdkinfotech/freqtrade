#!/bin/bash

# 🚀 Freqtrade Release Pipeline Helper
# Простой скрипт для запуска пайплайнов через GitHub CLI

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Проверяем наличие gh CLI
if ! command -v gh &> /dev/null; then
    error "GitHub CLI (gh) не установлен. Установите его: https://cli.github.com/"
    exit 1
fi

# Проверяем авторизацию
if ! gh auth status &> /dev/null; then
    error "Не авторизован в GitHub CLI. Выполните: gh auth login"
    exit 1
fi

# Получаем репозиторий
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
log "Работаем с репозиторием: $REPO"

# Функция для отображения меню
show_menu() {
    echo ""
    echo "🚀 Freqtrade Release Pipeline"
    echo "=============================="
    echo "1. 🔍 Проверить версии"
    echo "2. 🐳 Собрать образ"
    echo "3. 📦 Деплой Helm чарта"
    echo "4. 🚀 Полный релиз"
    echo "5. 📊 Показать статус пайплайнов"
    echo "6. ❌ Выход"
    echo ""
}

# Функция для запуска пайплайна
run_workflow() {
    local action=$1
    local version=$2
    local force=$3
    
    log "Запускаем пайплайн с действием: $action"
    
    local inputs="{\"action\":\"$action\""
    if [ -n "$version" ]; then
        inputs="$inputs,\"version\":\"$version\""
    fi
    if [ "$force" = "true" ]; then
        inputs="$inputs,\"force\":true"
    fi
    inputs="$inputs}"
    
    gh workflow run "🚀 Manual Release Pipeline" --field inputs="$inputs"
    
    if [ $? -eq 0 ]; then
        success "Пайплайн запущен успешно!"
        log "Отслеживайте прогресс: https://github.com/$REPO/actions"
    else
        error "Ошибка при запуске пайплайна"
        exit 1
    fi
}

# Функция для проверки версий
check_versions() {
    log "Проверяем доступные версии freqtrade..."
    
    # Получаем последнюю версию
    local latest=$(curl -s https://api.github.com/repos/freqtrade/freqtrade/releases/latest | jq -r '.tag_name')
    log "Последняя версия freqtrade: $latest"
    
    # Проверяем текущую версию в репозитории
    if [ -f ".version" ]; then
        local current=$(cat .version)
        log "Текущая версия в репозитории: $current"
        
        if [ "$latest" != "$current" ]; then
            warning "Доступна новая версия: $current → $latest"
        else
            success "Версия актуальна"
        fi
    else
        warning "Файл .version не найден"
    fi
    
    echo ""
    read -p "Запустить проверку через пайплайн? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_workflow "check"
    fi
}

# Функция для сборки образа
build_image() {
    echo ""
    echo "🐳 Сборка Docker образа"
    echo "========================"
    echo "1. Использовать последнюю версию"
    echo "2. Указать конкретную версию"
    echo "3. Назад"
    echo ""
    
    read -p "Выберите опцию (1-3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            run_workflow "build"
            ;;
        2)
            read -p "Введите версию (например, 2025.9): " version
            if [ -n "$version" ]; then
                run_workflow "build" "$version"
            else
                error "Версия не указана"
            fi
            ;;
        3)
            return
            ;;
        *)
            error "Неверный выбор"
            ;;
    esac
}

# Функция для деплоя
deploy_helm() {
    echo ""
    echo "📦 Деплой Helm чарта"
    echo "===================="
    echo "1. Использовать последнюю версию"
    echo "2. Указать конкретную версию"
    echo "3. Назад"
    echo ""
    
    read -p "Выберите опцию (1-3): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            run_workflow "deploy"
            ;;
        2)
            read -p "Введите версию (например, 2025.9): " version
            if [ -n "$version" ]; then
                run_workflow "deploy" "$version"
            else
                error "Версия не указана"
            fi
            ;;
        3)
            return
            ;;
        *)
            error "Неверный выбор"
            ;;
    esac
}

# Функция для полного релиза
full_release() {
    echo ""
    echo "🚀 Полный релиз"
    echo "==============="
    echo "1. Использовать последнюю версию"
    echo "2. Указать конкретную версию"
    echo "3. Принудительное обновление"
    echo "4. Назад"
    echo ""
    
    read -p "Выберите опцию (1-4): " -n 1 -r
    echo
    
    case $REPLY in
        1)
            run_workflow "full-release"
            ;;
        2)
            read -p "Введите версию (например, 2025.9): " version
            if [ -n "$version" ]; then
                run_workflow "full-release" "$version"
            else
                error "Версия не указана"
            fi
            ;;
        3)
            read -p "Введите версию для принудительного обновления: " version
            if [ -n "$version" ]; then
                run_workflow "full-release" "$version" "true"
            else
                error "Версия не указана"
            fi
            ;;
        4)
            return
            ;;
        *)
            error "Неверный выбор"
            ;;
    esac
}

# Функция для показа статуса
show_status() {
    log "Показываем статус последних пайплайнов..."
    gh run list --limit 5
}

# Основной цикл
main() {
    while true; do
        show_menu
        read -p "Выберите опцию (1-6): " -n 1 -r
        echo
        
        case $REPLY in
            1)
                check_versions
                ;;
            2)
                build_image
                ;;
            3)
                deploy_helm
                ;;
            4)
                full_release
                ;;
            5)
                show_status
                ;;
            6)
                success "До свидания!"
                exit 0
                ;;
            *)
                error "Неверный выбор. Попробуйте снова."
                ;;
        esac
        
        echo ""
        read -p "Нажмите Enter для продолжения..."
    done
}

# Запуск
main
