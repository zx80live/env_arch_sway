#!/bin/zsh

# Проверка, что скрипт запущен от имени root (sudo)
if [[ $EUID -ne 0 ]]; then
   echo "[-] Ошибка: Этот скрипт должен быть запущен через sudo!" 
   exit 1
fi

# Имя файла для логирования
LOG_FILE="security_audit.log"

# Инициализация лог-файла (очищаем старый при новом запуске)
echo "=== СИСТЕМНЫЙ ЛОГ АУДИТА БЕЗОПАСНОСТИ ЗА $(date) ===" > "$LOG_FILE"

# Функция для вывода на экран и одновременной записи в лог (без цветовых кодов в файле)
log_output() {
    local text="$1"
    # Выводим на экран с цветами
    echo -e "$text"
    # Записываем в файл, предварительно очистив от ANSI-цветов
    echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
}

# Цвета для вывода отчета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_output "${BLUE}${BOLD}=== ЗАПУСК КОМПЛЕКСНОГО АУДИТА БЕЗОПАСНОСТИ ===${NC}\n"

# ---------------------------------------------------------------------
# СБОР ДАННЫХ И ПЕРЕМЕННЫХ
# ---------------------------------------------------------------------
log_output "[*] Шаг 1: Получение внешнего IP-адреса..."
CMD_IP="su -c 'curl -s ifconfig.me' \$(logname)"
log_output "    ${CYAN}Запуск команды:${NC} $CMD_IP"

export KEEN_IP=$(su -c "curl -s ifconfig.me" $(logname))
echo "Получен внешний IP: $KEEN_IP" >> "$LOG_FILE"

if [[ -z "$KEEN_IP" ]]; then
    log_output "    ${RED}ОШИБКА (Нет интернета или curl)${NC}"
    exit 1
else
    log_output "    ${GREEN}Внешний IP: $KEEN_IP${NC}"
fi

LOCAL_IP=$(ip -4 addr show scope global | awk '/inet/ {print $2}' | cut -d/ -f1 | head -n 1)
echo "Локальный IP: $LOCAL_IP" >> "$LOG_FILE"

TARGET_PORTS="21,22,23,80,443,445,1194,1723,2121,8291"

if ! command -v nmap &> /dev/null; then
    log_output "${YELLOW}[*] Утилита nmap не найдена. Устанавливаем через pacman...${NC}"
    pacman -S nmap --noconfirm >> "$LOG_FILE" 2>&1
fi

log_output "\n${BLUE}[*] Шаг 2: Запуск сетевых тестов периметра...${NC}"

# СЦЕНАРИЙ 1: Тестирование Ping (выводим результаты на экран)
CMD_PING="ping -c 2 -W 2 \$KEEN_IP"
log_output "    -> Тестирование ICMP (Ping) внешнего IP..."
log_output "       ${CYAN}Запуск команды:${NC} $CMD_PING"
echo "--- ВЫВОД КОМАНДЫ PING ---" >> "$LOG_FILE"

# Запускаем команду так, чтобы вывод шел и на экран, и в лог
PING_OUT=$(ping -c 2 -W 2 $KEEN_IP 2>&1)
PING_RES=$?
echo "$PING_OUT"
echo "$PING_OUT" >> "$LOG_FILE"

# СЦЕНАРИЙ 2: Тестирование портов через Nmap (выводим результаты на экран)
CMD_NMAP="sudo nmap -sS -Pn -p $TARGET_PORTS --reason \$KEEN_IP"
log_output "\n    -> Сканирование внешних портов через Nmap (SYN-Scan)..."
log_output "       ${CYAN}Запуск команды:${NC} $CMD_NMAP"
echo "--- ВЫВОД КОМАНДЫ NMAP ---" >> "$LOG_FILE"

NMAP_OUT=$(nmap -sS -Pn -p $TARGET_PORTS --reason $KEEN_IP 2>&1)
echo "$NMAP_OUT"
echo "$NMAP_OUT" >> "$LOG_FILE"
HAS_OPEN_PORTS=$(echo "$NMAP_OUT" | grep -E '^[0-9]+/tcp\s+open')

log_output "\n${BLUE}[*] Шаг 3: Локальный аудит операционной системы Arch Linux...${NC}"

# СЦЕНАРИЙ 3: Проверка UFW (выводим результаты на экран)
CMD_UFW="sudo ufw status verbose"
log_output "    -> Проверка статуса файрвола UFW..."
log_output "       ${CYAN}Запуск команды:${NC} $CMD_UFW"
echo "--- ВЫВОД КОМАНДЫ UFW ---" >> "$LOG_FILE"

UFW_STATUS=$(ufw status verbose 2>&1)
echo "$UFW_STATUS"
echo "$UFW_STATUS" >> "$LOG_FILE"

# Проверка Ollama (выводим результаты на экран)
CMD_SS="sudo ss -tulnp | grep '11434'"
log_output "\n    -> Проверка сокетов Ollama..."
log_output "       ${CYAN}Запуск команды:${NC} $CMD_SS"
echo "--- ВЫВОД КОМАНДЫ SS (OLLAMA) ---" >> "$LOG_FILE"

SS_OUT=$(ss -tulnp 2>&1 | grep "11434")
if [[ -n "$SS_OUT" ]]; then
    echo "$SS_OUT"
    echo "$SS_OUT" >> "$LOG_FILE"
else
    echo "Служба Ollama не найдена или не слушает порты в данный момент."
    echo "No active ports for Ollama found" >> "$LOG_FILE"
fi
OLLAMA_LISTEN_ALL=$(ss -tulnp 2>/dev/null | grep "11434" | awk '{print $5}' | grep -E '^0\.0\.0\.0:|^\[::\]:|^_*:')

# Проверка прав домашней папки (выводим результаты на экран)
USER_HOME="/home/$(logname)"
CMD_STAT="stat $USER_HOME"
log_output "\n    -> Проверка прав директории пользователя..."
log_output "       ${CYAN}Запуск команды:${NC} $CMD_STAT"
echo "--- ВЫВОД ПРАВ ДОМАШНЕЙ ПАПКИ ---" >> "$LOG_FILE"

STAT_OUT=$(stat "$USER_HOME" 2>&1)
echo "$STAT_OUT"
echo "$STAT_OUT" >> "$LOG_FILE"
HOME_PERM=$(stat -c "%a" "$USER_HOME" 2>/dev/null)

# Проверка Docker (выводим результаты на экран)
CMD_DOCKER="sudo docker ps -a"
log_output "\n    -> Проверка активности демона Docker..."
log_output "       ${CYAN}Запуск команды:${NC} $CMD_DOCKER"
echo "--- ВЫВОД КОМАНДЫ DOCKER PS ---" >> "$LOG_FILE"

DOCKER_OUT=$(docker ps -a 2>&1)
echo "$DOCKER_OUT"
echo "$DOCKER_OUT" >> "$LOG_FILE"
DOCKER_ACTIVE=$(docker ps -q 2>/dev/null)


# ---------------------------------------------------------------------
# ВЫВОД ИТОГОВОГО ОТЧЕТА (БЕЗ ПЕРЕЗАТИРАНИЯ КОНСОЛИ)
# ---------------------------------------------------------------------
log_output "\n"
log_output "${BLUE}${BOLD}======================================================${NC}"
log_output "${BLUE}${BOLD}             ИТОГОВЫЙ ОТЧЕТ БЕЗОПАСНОСТИ              ${NC}"
log_output "${BLUE}${BOLD}======================================================${NC}\n"

log_output "${BOLD}Текущие параметры среды:${NC}"
log_output "  Локальный IP машины:  ${YELLOW}$LOCAL_IP${NC}"
log_output "  Внешний IP Keenetic:  ${YELLOW}$KEEN_IP${NC}\n"

log_output "${BOLD}1. ВНЕШНИЙ ПЕРИМЕТР (Роутер Keenetic из Интернета):${NC}"
if [ $PING_RES -eq 0 ]; then
    log_output "  [-] ICMP (Ping):      ${RED}ОТВЕЧАЕТ (Узел виден в сети)${NC}"
else
    log_output "  [+] ICMP (Ping):      ${GREEN}БЛОКИРУЕТСЯ (Режим Стелс)${NC}"
fi

if [ -n "$HAS_OPEN_PORTS" ]; then
    log_output "  [-] Открытые порты:   ${RED}ОБНАРУЖЕНЫ ОТКРЫТЫЕ ПОРТЫ!${NC}"
    echo "$NMAP_OUT" | grep -E "port|" | grep "open" | sed 's/^/      /' >> "$LOG_FILE"
else
    log_output "  [+] Открытые порты:   ${GREEN}ВСЕ ЗАКРЫТЫ / ФИЛЬТРУЮТСЯ (filtered)${NC}"
fi

log_output "\n${BOLD}2. ЛОКАЛЬНЫЙ ПЕРИМЕТР (Твой компьютер Arch Linux):${NC}"
if echo "$UFW_STATUS" | grep -q "Status: active"; then
    log_output "  [+] Локальный UFW:    ${GREEN}АКТИВЕН (Защита включена)${NC}"
else
    log_output "  [-] Локальный UFW:    ${RED}ОТКЛЮЧЕН ИЛИ НЕ НАСТРОЕН!${NC}"
fi

if [ -n "$OLLAMA_LISTEN_ALL" ]; then
    log_output "  [-] Сервис Ollama:    ${RED}УЯЗВИМ (Слушает внешний интерфейс 0.0.0.0)${NC}"
else
    log_output "  [+] Сервис Ollama:    ${GREEN}БЕЗОПАСЕН (Привязан к локальному 127.0.0.1)${NC}"
fi

if [ "$HOME_PERM" -eq 700 ]; then
    log_output "  [+] Права папки $USER_HOME: ${GREEN}БЕЗОПАСНО (700 - Доступ только владельцу)${NC}"
else
    log_output "  [-] Права папки $USER_HOME: ${RED}НЕБЕЗОПАСНО ($HOME_PERM - Возможен доступ извне)${NC}"
fi

if [ -n "$DOCKER_ACTIVE" ]; then
    log_output "  [-] Активный Docker:  ${YELLOW}ВНИМАНИЕ (Есть запущенные контейнеры. Проверь обход UFW!)${NC}"
else
    log_output "  [+] Активный Docker:  ${GREEN}БЕЗОПАСЕН (Запущенные контейнеры отсутствуют)${NC}"
fi

log_output "\n${BLUE}${BOLD}======================================================${NC}"
log_output "${BLUE}${BOLD}Аудит успешно завершен. Полный сырой лог сохранен в: $LOG_FILE${NC}"
