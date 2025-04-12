#!/bin/bash

# Скрипт для тестирования всех функций licensify CLI
# Включает тестирование:
# - Клиентских команд
# - Серверных команд 
# - Команд работы с ключами
# - Полного процесса лицензирования

# Настройка цветов для вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Пути к временным файлам
TEST_DIR="./test_cli/tmp"
KEYS_DIR="$TEST_DIR/keys"
LICENSE_PLANS="$TEST_DIR/license_plans.json"
LICENSE_REQUEST="$TEST_DIR/license_request.bin"
LICENSE_FILE="$TEST_DIR/license.licensify"
TRIAL_LICENSE="$TEST_DIR/trial.licensify"
APP_ID="test.app.123"
PLAN_ID="test-plan-pro"
TRIAL_PLAN_ID="test-plan-trial"

# Путь к CLI инструменту
CLI="bin/licensify.dart"

# Утилиты для сообщений
log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
  exit 1
}

log_info() {
  echo -e "${BLUE}ℹ️ $1${NC}"
}

log_step() {
  echo -e "\n${YELLOW}🔹 $1${NC}"
}

# Очистка и настройка тестового окружения
setup() {
  log_step "Настройка тестового окружения"
  
  # Удаляем тестовую директорию и корневой файл планов
  rm -rf $TEST_DIR
  rm -f license_plans.json
  
  mkdir -p $TEST_DIR
  if [ ! -d $TEST_DIR ]; then
    log_error "Не удалось создать временную директорию: $TEST_DIR"
  fi
  log_success "Тестовое окружение создано"
}

# Тестирование команд для работы с ключами
test_keys() {
  log_step "Тестирование генерации ключей"
  
  # Создаем директорию для ключей
  mkdir -p $KEYS_DIR
  
  # Генерируем ключи
  dart $CLI server keygen --output $KEYS_DIR --name "test_keys"
  
  # Проверяем, что ключи созданы
  PRIVATE_KEY="$KEYS_DIR/test_keys.private.pem"
  PUBLIC_KEY="$KEYS_DIR/test_keys.public.pem"
  
  if [ ! -f $PRIVATE_KEY ] || [ ! -f $PUBLIC_KEY ]; then
    log_error "Не удалось создать ключи"
  fi
  
  log_success "Ключи успешно созданы: $PRIVATE_KEY и $PUBLIC_KEY"
}

# Тестирование серверных команд для работы с планами
test_plans() {
  log_step "Тестирование работы с планами лицензий"
  
  # Создание стандартного плана
  log_info "Создание стандартного плана..."
  dart $CLI server create --id $PLAN_ID --name "Pro Plan" --description "Professional Plan" --type pro --duration 365 --price 49.99 --app-id $APP_ID --file $LICENSE_PLANS
  
  # Создание пробного плана
  log_info "Создание пробного плана..."
  dart $CLI server create --id $TRIAL_PLAN_ID --name "Trial Plan" --description "Trial Plan" --type standard --duration 30 --trial --app-id $APP_ID --file $LICENSE_PLANS
  
  # Просмотр созданного плана
  log_info "Просмотр плана..."
  dart $CLI server plan --id $PLAN_ID --app-id $APP_ID --file $LICENSE_PLANS
  
  # Просмотр списка планов
  log_info "Список всех планов..."
  dart $CLI server ls --app-id $APP_ID --file $LICENSE_PLANS
  
  # Экспорт планов в файл (для последовательности, хотя уже не нужно)
  log_info "Экспорт планов в файл..."
  dart $CLI server export --output $LICENSE_PLANS --app-id $APP_ID --file $LICENSE_PLANS --force
  
  if [ ! -f $LICENSE_PLANS ]; then
    log_error "Не удалось экспортировать планы в файл: $LICENSE_PLANS"
  fi
  
  log_success "Планы лицензий успешно созданы и экспортированы"
}

# Тестирование создания лицензий на основе запроса
test_license_request_flow() {
  log_step "Тестирование процесса работы с запросами лицензий"
  
  # Клиентская часть: создание запроса
  log_info "Создание запроса на лицензию (клиент)..."
  dart $CLI client request --appId $APP_ID --publicKey $PUBLIC_KEY --output $LICENSE_REQUEST
  
  if [ ! -f $LICENSE_REQUEST ]; then
    log_error "Не удалось создать запрос на лицензию: $LICENSE_REQUEST"
  fi
  
  # Серверная часть: расшифровка запроса
  log_info "Расшифровка запроса на лицензию (сервер)..."
  dart $CLI server decrypt-request --requestFile $LICENSE_REQUEST --privateKey $PRIVATE_KEY
  
  # Серверная часть: создание лицензии на основе запроса и плана
  log_info "Создание лицензии на основе запроса и плана (сервер)..."
  dart $CLI server respond-with-plan --requestFile $LICENSE_REQUEST --privateKey $PRIVATE_KEY --planId $PLAN_ID --app-id $APP_ID --output $LICENSE_FILE --plansFile $LICENSE_PLANS
  
  if [ ! -f $LICENSE_FILE ]; then
    log_error "Не удалось создать лицензию: $LICENSE_FILE"
  fi
  
  # Создание пробной лицензии
  log_info "Создание пробной лицензии на основе запроса и плана (сервер)..."
  dart $CLI server respond-with-plan --requestFile $LICENSE_REQUEST --privateKey $PRIVATE_KEY --planId $TRIAL_PLAN_ID --app-id $APP_ID --output $TRIAL_LICENSE --plansFile $LICENSE_PLANS
  
  if [ ! -f $TRIAL_LICENSE ]; then
    log_error "Не удалось создать пробную лицензию: $TRIAL_LICENSE"
  fi
  
  log_success "Лицензии успешно созданы на основе запроса"
}

# Тестирование прямого создания лицензий
test_direct_license_generation() {
  log_step "Тестирование прямой генерации лицензий"
  
  # Генерация лицензии напрямую
  DIRECT_LICENSE="$TEST_DIR/direct_license.licensify"
  log_info "Прямая генерация лицензии (сервер)..."
  dart $CLI server generate --appId $APP_ID --privateKey $PRIVATE_KEY --expiration "2025-12-31" --type pro --output $DIRECT_LICENSE
  
  if [ ! -f $DIRECT_LICENSE ]; then
    log_error "Не удалось создать лицензию напрямую: $DIRECT_LICENSE"
  fi
  
  log_success "Лицензия успешно создана напрямую"
}

# Тестирование клиентских команд для проверки лицензий
test_license_verification() {
  log_step "Тестирование проверки лицензий"
  
  # Проверка стандартной лицензии
  log_info "Проверка лицензии (клиент)..."
  dart $CLI client verify --license $LICENSE_FILE --publicKey $PUBLIC_KEY
  
  # Просмотр данных лицензии
  log_info "Просмотр данных лицензии (клиент)..."
  dart $CLI client show --license $LICENSE_FILE
  
  # Проверка пробной лицензии
  log_info "Проверка пробной лицензии (клиент)..."
  dart $CLI client verify --license $TRIAL_LICENSE --publicKey $PUBLIC_KEY
  
  log_success "Все лицензии успешно проверены"
}

# Тестирование импорта планов
test_import_plans() {
  log_step "Тестирование импорта планов"
  
  # Создаем временную копию файла планов
  TEMP_PLANS="$TEST_DIR/temp_plans.json"
  cp $LICENSE_PLANS $TEMP_PLANS
  
  # Удаляем существующие планы (симуляция)
  log_info "Удаляем текущие планы..."
  rm -f $LICENSE_PLANS
  
  # Импортируем ранее экспортированные планы
  log_info "Импорт планов из файла..."
  dart $CLI server import --input $TEMP_PLANS --app-id $APP_ID --file $LICENSE_PLANS
  
  # Проверяем, что планы импортированы, запросив список
  log_info "Проверка импортированных планов..."
  dart $CLI server ls --app-id $APP_ID --file $LICENSE_PLANS
  
  log_success "Планы успешно импортированы"
}

# Очистка тестовых данных
cleanup() {
  log_step "Очистка тестового окружения"
  
  # Удаляем файл планов из корневой директории
  rm -f license_plans.json
  
  # Оставляем файлы для ручной проверки, но можно раскомментировать для удаления
  # rm -rf $TEST_DIR
  
  log_success "Тестовое окружение оставлено для проверки: $TEST_DIR"
}

# Запуск всех тестов
run_all_tests() {
  setup
  test_keys
  test_plans
  test_license_request_flow
  test_direct_license_generation
  test_license_verification
  test_import_plans
  cleanup
  
  echo -e "\n${GREEN}=== Все тесты успешно завершены ===${NC}"
}

# Запуск тестов
run_all_tests 