# DevOps Pipeline для Freqtrade Docker Images

Этот документ описывает полный DevOps процесс для автоматической сборки и публикации Docker образов freqtrade в Docker Hub.

## 🎯 Обзор

Настроен полный CI/CD пайплайн, который:
- ✅ Автоматически собирает Docker образы при изменениях в коде
- ✅ Создает образы с правильным версионированием
- ✅ Публикует образы в Docker Hub (sdkinfo999)
- ✅ Поддерживает множественные архитектуры (amd64, arm64)
- ✅ Включает метаданные и лейблы для образов

## 🏗️ Архитектура

### GitHub Actions Workflow
- **Файл:** `.github/workflows/docker-build.yml`
- **Триггеры:** push в stable/develop, создание тегов, ручной запуск
- **Платформы:** linux/amd64, linux/arm64

### Docker Images
- **Base:** `sdkinfo999/freqtrade` - основной образ
- **FreqAI:** `sdkinfo999/freqtrade-freqai` - с машинным обучением
- **FreqAI RL:** `sdkinfo999/freqtrade-freqai-rl` - с reinforcement learning
- **Plot:** `sdkinfo999/freqtrade-plot` - с возможностями построения графиков

## 🏷️ Версионирование

### Схема тегов
Образы создаются с несколькими тегами:

1. **Branch-based:** `stable`, `develop`, `latest`
2. **Code version:** `2025.9`, `2025.8`, etc. (из freqtrade/__init__.py)
3. **Commit SHA:** `4e2e86863` (короткий хеш коммита)

### Примеры тегов
```bash
sdkinfo999/freqtrade:stable
sdkinfo999/freqtrade:2025.9
sdkinfo999/freqtrade:4e2e86863
sdkinfo999/freqtrade:latest
```

## 🚀 Использование

### 1. Настройка секретов

```bash
# Автоматическая настройка (требует GitHub CLI)
./setup-github-secrets.sh

# Или ручная настройка:
# 1. Перейдите в https://github.com/sdkinfotech/freqtrade/settings/secrets/actions
# 2. Добавьте секреты:
#    - DOCKER_USERNAME: ваш Docker Hub username
#    - DOCKER_PASSWORD: ваш Docker Hub access token
```

### 2. Создание релиза

```bash
# Создать релиз с текущей версией
./create-release.sh

# Создать релиз с конкретной версией
./create-release.sh 2025.6

# Создать релиз с сообщением
./create-release.sh 2025.6.1 "Bug fixes and improvements"
```

### 3. Ручной запуск сборки

```bash
# Через GitHub CLI
gh workflow run docker-build.yml

# Или через веб-интерфейс GitHub Actions
```

## 📋 Процесс сборки

### Автоматические триггеры

1. **Push в stable/develop:** Создает образы с тегами веток
2. **Создание тега:** Создает образы с версионными тегами
3. **Ручной запуск:** Позволяет создать образы с кастомными параметрами

### Этапы сборки

1. **Checkout:** Получение кода из репозитория
2. **Setup Buildx:** Настройка Docker Buildx для мультиплатформенной сборки
3. **Login:** Аутентификация в Docker Hub
4. **Extract Version:** Извлечение информации о версии
5. **Build & Push:** Сборка и публикация образов
6. **Update Latest:** Обновление тега `latest` для stable ветки

### Метаданные образов

Каждый образ содержит следующие метаданные:
- `org.opencontainers.image.title` - название
- `org.opencontainers.image.description` - описание
- `org.opencontainers.image.url` - URL репозитория
- `org.opencontainers.image.source` - исходный код
- `org.opencontainers.image.version` - версия
- `org.opencontainers.image.created` - дата создания
- `org.opencontainers.image.revision` - хеш коммита
- `org.opencontainers.image.vendor` - вендор

## 🔍 Мониторинг

### GitHub Actions
- **URL:** https://github.com/sdkinfotech/freqtrade/actions
- **Workflow:** Build and Push Docker Images
- **Логи:** Доступны в интерфейсе GitHub

### Docker Hub
- **URL:** https://hub.docker.com/repositories/sdkinfo999
- **Образы:** Все собранные образы доступны для скачивания
- **Теги:** Автоматически обновляются при новых сборках

### Команды для проверки

```bash
# Проверить доступные теги
docker search sdkinfo999/freqtrade

# Скачать образ
docker pull sdkinfo999/freqtrade:2025.9

# Проверить метаданные
docker inspect sdkinfo999/freqtrade:2025.9

# Запустить контейнер
docker run -it sdkinfo999/freqtrade:2025.9 freqtrade --version
```

## 🛠️ Настройка и кастомизация

### Изменение Docker Hub репозитория

В файле `.github/workflows/docker-build.yml`:
```yaml
env:
  REGISTRY: docker.io
  IMAGE_NAME: your-username/freqtrade  # Измените здесь
```

### Добавление новых образов

1. Создайте новый Dockerfile
2. Добавьте шаг сборки в workflow
3. Обновите документацию

### Изменение архитектур

В workflow измените параметр `platforms`:
```yaml
platforms: linux/amd64,linux/arm64,linux/arm/v7
```

## 🚨 Устранение проблем

### Сборка не запускается

1. **Проверьте секреты:** Убедитесь, что `DOCKER_USERNAME` и `DOCKER_PASSWORD` настроены
2. **Проверьте права:** Убедитесь, что у вас есть права на запись в репозиторий
3. **Проверьте workflow:** Убедитесь, что файл `.github/workflows/docker-build.yml` существует

### Ошибки аутентификации Docker Hub

1. **Проверьте токен:** Убедитесь, что Docker Hub access token действителен
2. **Проверьте права:** Убедитесь, что токен имеет права на запись в репозиторий
3. **Обновите секреты:** Пересоздайте секреты в GitHub

### Образы не публикуются

1. **Проверьте логи:** Посмотрите логи GitHub Actions для деталей ошибки
2. **Проверьте Docker Hub:** Убедитесь, что репозиторий существует
3. **Проверьте теги:** Убедитесь, что теги не конфликтуют с существующими

## 📊 Статистика и метрики

### Автоматические уведомления

Workflow создает summary с информацией о:
- Версии образа
- Тегах
- Ссылках на Docker Hub
- Статусе сборки

### Мониторинг использования

- **Docker Hub:** Статистика скачиваний в интерфейсе Docker Hub
- **GitHub Actions:** Время выполнения и использование ресурсов
- **GitHub Insights:** Статистика активности репозитория

## 🔄 Интеграция с другими системами

### Webhooks

Можно настроить webhooks для уведомлений о новых релизах:
- Discord
- Slack
- Telegram
- Email

### Автоматическое развертывание

Образы можно использовать для:
- Kubernetes deployments
- Docker Compose
- CI/CD других проектов

## 📚 Дополнительные ресурсы

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [OpenContainer Image Spec](https://github.com/opencontainers/image-spec)

## 🎉 Заключение

Настроенный DevOps пайплайн обеспечивает:
- ✅ Автоматическую сборку Docker образов
- ✅ Правильное версионирование
- ✅ Публикацию в Docker Hub
- ✅ Мультиплатформенную поддержку
- ✅ Полную трассируемость и мониторинг

Теперь процесс релизов полностью автоматизирован и соответствует лучшим практикам DevOps!
