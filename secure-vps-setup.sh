cat > /tmp/secure_ssh.sh <<'EOF'
#!/bin/bash
#
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                       SETUP VPS SCRIPT v0.5-beta                             ║
# ║          Automated security configuration for Remnawave Node & VPN           ║
# ║                                                                              ║
# ║  GitHub:   https://github.com/UnderGut/setup-vps-script                      ║
# ║  License:  MIT                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

LANG_CODE="${LANG_CODE:-auto}"
SSH_PORT="${SSH_PORT:-}"
SSH_CONF_PATH="${SSH_CONF_PATH:-/etc/ssh/sshd_config.d/99-local.conf}"
PANEL_IPS="${PANEL_IPS:-}"
PANEL_PORT="${PANEL_PORT:-2222}"
INTERACTIVE="${INTERACTIVE:-auto}"
BACKUP_DIR="${BACKUP_DIR:-/root/.vps-setup-backups}"
LOG_FILE="${LOG_FILE:-/var/log/vps-setup.log}"

# Installation flags
INSTALL_DOCKER="${INSTALL_DOCKER:-}"
INSTALL_FAIL2BAN="${INSTALL_FAIL2BAN:-}"
ENABLE_BBR="${ENABLE_BBR:-}"
INSTALL_TBLOCKER="${INSTALL_TBLOCKER:-}"
BLOCK_ICMP="${BLOCK_ICMP:-}"
CHANGE_SSH_PORT="${CHANGE_SSH_PORT:-}"
SETUP_SWAP="${SETUP_SWAP:-}"
SETUP_TIMEZONE="${SETUP_TIMEZONE:-}"
DISABLE_IPV6="${DISABLE_IPV6:-}"
SETUP_AUTOUPDATE="${SETUP_AUTOUPDATE:-}"
INSTALL_TOOLS="${INSTALL_TOOLS:-}"
KERNEL_HARDENING="${KERNEL_HARDENING:-}"
SETUP_NETLIMITS="${SETUP_NETLIMITS:-}"
SETUP_LOGROTATE="${SETUP_LOGROTATE:-}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-90}"
SETUP_NTP="${SETUP_NTP:-}"
SETUP_RATELIMIT="${SETUP_RATELIMIT:-}"

DRY_RUN="${DRY_RUN:-false}"
NO_COLOR="${NO_COLOR:-false}"

# ══════════════════════════════════════════════════════════════════════════════
# DESCRIPTIONS / ОПИСАНИЯ
# ══════════════════════════════════════════════════════════════════════════════

declare -A DESC_EN=(
    # SSH
    [ssh_port_title]="🔐 SSH Port Change"
    [ssh_port_desc]="Changes SSH from standard port 22 to a custom port.
   WHY: Port 22 is constantly scanned by bots. A custom port
   reduces automated attacks by 99%. You'll connect using:
   ssh -p YOUR_PORT root@server"

    # Docker
    [docker_title]="🐳 Docker"
    [docker_desc]="Container platform for running applications in isolation.
   WHY: Remnawave node runs in Docker. Also useful for
   running other services without conflicts.
   INSTALLS: docker, docker-compose"

    # Fail2Ban
    [fail2ban_title]="🛡️ Fail2Ban"
    [fail2ban_desc]="Automatic protection against brute-force attacks.
   WHY: Blocks IP addresses that try to guess your password.
   Uses 4-level system: 10min → 1hour → 24hours → permanent ban.
   PROTECTS: SSH, and any future services"

    # BBR
    [bbr_title]="🚀 BBR + TCP Optimizations"
    [bbr_desc]="Google's network congestion control algorithm.
   WHY: Significantly improves VPN speed and stability,
   especially on high-latency or lossy connections.
   EFFECT: Up to 2-3x faster VPN speeds"

    # Torrent Blocker
    [tblocker_title]="🚫 Torrent Blocker"
    [tblocker_desc]="Blocks BitTorrent traffic through your VPN.
   WHY: Prevents users from downloading torrents,
   which can get your server IP blacklisted.
   USES: Xray traffic analysis"

    # ICMP Block
    [icmp_title]="🔇 ICMP (Ping) Blocking"
    [icmp_desc]="Makes your server invisible to ping requests.
   WHY: Hides server from basic network scans.
   Server won't respond to 'ping your-server-ip'.
   NOTE: Some monitoring tools need ping to work"

    # Swap
    [swap_title]="💾 Swap File (Virtual Memory)"
    [swap_desc]="Creates swap space on disk for when RAM is full.
   WHY: Prevents crashes when memory runs out.
   Recommended for servers with 1-2GB RAM.
   SIZE: Automatically calculated based on RAM"

    # Timezone
    [timezone_title]="🕐 Timezone Configuration"
    [timezone_desc]="Sets server timezone for correct log timestamps.
   WHY: Makes log analysis easier, scheduled tasks
   run at expected times.
   DEFAULT: Will ask you to select or auto-detect"

    # IPv6
    [ipv6_title]="🌐 Disable IPv6"
    [ipv6_desc]="Completely disables IPv6 networking.
   WHY: Most VPNs use IPv4 only. Disabling IPv6
   prevents potential IP leaks and simplifies firewall.
   NOTE: Only disable if you don't need IPv6"

    # Auto-updates
    [autoupdate_title]="🔄 Automatic Security Updates"
    [autoupdate_desc]="Automatically installs critical security patches.
   WHY: Keeps your server protected without manual work.
   Only security updates are auto-installed.
   USES: unattended-upgrades package"

    # Tools
    [tools_title]="🧰 Useful Admin Tools"
    [tools_desc]="Installs helpful utilities for server management.
   INCLUDES:
   • htop - interactive process viewer
   • ncdu - disk usage analyzer
   • vnstat - network traffic monitor
   • tmux - terminal multiplexer (keeps sessions alive)"

    # Panel IPs
    [panel_ips_title]="🎛️ Panel Access IPs"
    [panel_ips_desc]="Restrict Remnawave panel access to specific IPs.
   WHY: Only YOUR IP can connect to the panel port.
   Others will be blocked by firewall.
   FORMAT: Single IP or comma-separated: 1.2.3.4,5.6.7.8"

    # Kernel Hardening
    [kernel_title]="🔒 Kernel Hardening"
    [kernel_desc]="Security settings at the kernel level.
   PROTECTS AGAINST:
   • IP Spoofing - fake sender addresses
   • SYN Flood - DDoS attack on connections
   • ICMP Redirects - traffic hijacking attacks
   • Source Routing - forced packet routing
   WHY: Essential protection for any public VPN server"

    # Network Limits
    [netlimits_title]="📊 Network Limits (Conntrack)"
    [netlimits_desc]="Increases connection tracking limits for high-load VPN.
   DEFAULT: Linux tracks ~65,000 connections
   AFTER: Up to 1,000,000+ connections
   WHY: VPN with 100+ users needs more connections.
   Without this, new connections may be dropped."

    # Logrotate
    [logrotate_title]="📝 Log Rotation (Logrotate)"
    [logrotate_desc]="Automatic log cleanup to prevent disk overflow.
   WHY: VPN logs can fill up disk in months.
   CONFIGURES: Compression, rotation, retention period.
   IMPORTANT: You can set retention period for legal compliance
   (some jurisdictions require 90-365 days log retention)."

    # NTP
    [ntp_title]="⏰ Time Sync (NTP)"
    [ntp_desc]="Synchronizes server time with atomic clocks via internet.
   WHY FOR VPN:
   • TLS certificates require accurate time (otherwise errors)
   • Logs with wrong time are useless for investigations
   • Cron jobs run based on system time
   INSTALLS: chrony (more accurate than ntpd)"

    # Rate Limiting
    [ratelimit_title]="🔥 Rate Limiting (DDoS Protection)"
    [ratelimit_desc]="Limits connections per IP via iptables (kernel level).
   PROTECTS AGAINST:
   • DDoS attacks on SSH and panel ports
   • Rapid repeated connection attempts
   • Works faster than Fail2Ban (kernel level)
   LIMITS: 10 new SSH connections/min per IP
   NOTE: May block legitimate users with dynamic IPs"
)

declare -A DESC_RU=(
    # SSH
    [ssh_port_title]="🔐 Смена SSH-порта"
    [ssh_port_desc]="Меняет SSH со стандартного порта 22 на другой.
   ЗАЧЕМ: Порт 22 постоянно сканируют боты. Другой порт
   снижает автоматические атаки на 99%. Подключение:
   ssh -p ВАШ_ПОРТ root@сервер"

    # Docker
    [docker_title]="🐳 Docker"
    [docker_desc]="Платформа для запуска приложений в контейнерах.
   ЗАЧЕМ: Нода Remnawave работает в Docker. Также удобно
   для запуска других сервисов без конфликтов.
   УСТАНОВИТ: docker, docker-compose"

    # Fail2Ban
    [fail2ban_title]="🛡️ Fail2Ban"
    [fail2ban_desc]="Автоматическая защита от подбора паролей.
   ЗАЧЕМ: Блокирует IP, которые пытаются подобрать пароль.
   4 уровня: 10мин → 1час → 24часа → навсегда.
   ЗАЩИЩАЕТ: SSH и будущие сервисы"

    # BBR
    [bbr_title]="🚀 BBR + Оптимизации TCP"
    [bbr_desc]="Алгоритм управления сетью от Google.
   ЗАЧЕМ: Значительно улучшает скорость и стабильность VPN,
   особенно при плохом соединении.
   ЭФФЕКТ: До 2-3x быстрее VPN"

    # Torrent Blocker
    [tblocker_title]="🚫 Блокировщик торрентов"
    [tblocker_desc]="Блокирует BitTorrent трафик через VPN.
   ЗАЧЕМ: Не даёт пользователям качать торренты,
   из-за которых IP сервера может попасть в чёрные списки.
   ИСПОЛЬЗУЕТ: Анализ трафика Xray"

    # ICMP Block
    [icmp_title]="🔇 Блокировка ICMP (Ping)"
    [icmp_desc]="Делает сервер невидимым для ping-запросов.
   ЗАЧЕМ: Скрывает сервер от базовых сканеров сети.
   Сервер не будет отвечать на 'ping ваш-сервер'.
   ВАЖНО: Некоторые мониторинги используют ping"

    # Swap
    [swap_title]="💾 Swap-файл (виртуальная память)"
    [swap_desc]="Создаёт файл подкачки на диске.
   ЗАЧЕМ: Предотвращает падения при нехватке RAM.
   Рекомендуется для серверов с 1-2 ГБ памяти.
   РАЗМЕР: Автоматически по объёму RAM"

    # Timezone
    [timezone_title]="🕐 Настройка часового пояса"
    [timezone_desc]="Устанавливает временную зону сервера.
   ЗАЧЕМ: Правильное время в логах, задачи по расписанию
   работают в ожидаемое время.
   ПО УМОЛЧАНИЮ: Спросит или определит автоматически"

    # IPv6
    [ipv6_title]="🌐 Отключение IPv6"
    [ipv6_desc]="Полностью отключает IPv6 на сервере.
   ЗАЧЕМ: Большинство VPN используют только IPv4.
   Отключение предотвращает утечки IP и упрощает firewall.
   ВАЖНО: Отключайте только если IPv6 не нужен"

    # Auto-updates
    [autoupdate_title]="🔄 Автоматические обновления безопасности"
    [autoupdate_desc]="Автоматически устанавливает критические патчи.
   ЗАЧЕМ: Сервер защищён без ручной работы.
   Устанавливаются только обновления безопасности.
   ИСПОЛЬЗУЕТ: пакет unattended-upgrades"

    # Tools
    [tools_title]="🧰 Полезные утилиты"
    [tools_desc]="Устанавливает утилиты для администрирования.
   ВКЛЮЧАЕТ:
   • htop - интерактивный просмотр процессов
   • ncdu - анализатор места на диске
   • vnstat - мониторинг сетевого трафика
   • tmux - мультиплексор терминала (сохраняет сессии)"

    # Panel IPs
    [panel_ips_title]="🎛️ IP-адреса для панели"
    [panel_ips_desc]="Ограничивает доступ к панели Remnawave.
   ЗАЧЕМ: Только ВАШ IP сможет подключиться к панели.
   Остальные будут заблокированы.
   ФОРМАТ: Один IP или через запятую: 1.2.3.4,5.6.7.8"

    # Kernel Hardening
    [kernel_title]="🔒 Защита ядра (Kernel Hardening)"
    [kernel_desc]="Настройки безопасности на уровне ядра Linux.
   ЗАЩИЩАЕТ ОТ:
   • IP Spoofing - подмена адреса отправителя
   • SYN Flood - DDoS-атака на соединения
   • ICMP Redirects - перехват трафика
   • Source Routing - принудительная маршрутизация
   ЗАЧЕМ: Базовая защита для любого публичного VPN-сервера"

    # Network Limits
    [netlimits_title]="📊 Сетевые лимиты (Conntrack)"
    [netlimits_desc]="Увеличивает лимиты отслеживания соединений.
   ПО УМОЛЧАНИЮ: Linux отслеживает ~65,000 соединений
   ПОСЛЕ: До 1,000,000+ соединений
   ЗАЧЕМ: VPN со 100+ пользователями требует больше.
   Без этого новые соединения могут отбрасываться."

    # Logrotate
    [logrotate_title]="📝 Ротация логов (Logrotate)"
    [logrotate_desc]="Автоматическая очистка логов от переполнения диска.
   ЗАЧЕМ: Логи VPN могут забить диск за месяцы.
   НАСТРАИВАЕТ: Сжатие, ротацию, срок хранения.
   ВАЖНО: Можно указать срок хранения для соответствия
   законодательству (некоторые требуют 90-365 дней)."

    # NTP
    [ntp_title]="⏰ Синхронизация времени (NTP)"
    [ntp_desc]="Синхронизирует время сервера с атомными часами.
   ЗАЧЕМ ДЛЯ VPN:
   • TLS сертификаты требуют точное время (иначе ошибки)
   • Логи с неправильным временем бесполезны для расследований
   • Cron-задачи работают по системному времени
   УСТАНОВИТ: chrony (точнее чем ntpd)"

    # Rate Limiting
    [ratelimit_title]="🔥 Ограничение соединений (Rate Limiting)"
    [ratelimit_desc]="Ограничивает соединения с одного IP через iptables.
   ЗАЩИЩАЕТ ОТ:
   • DDoS-атак на SSH и порт панели
   • Быстрых повторных подключений
   • Работает быстрее Fail2Ban (уровень ядра)
   ЛИМИТЫ: 10 новых SSH соединений/мин с IP
   ВАЖНО: Может блокировать легитимных пользователей"
)

# Simple messages
declare -A MSG_EN=(
    [welcome]="Welcome to Secure VPS Setup"
    [for_beginners]="Beginner-friendly mode: each option includes an explanation"
    [select_lang]="Select language"
    [checking_system]="Checking system requirements..."
    [os_not_supported]="This script supports only Debian 11+ or Ubuntu 20.04+"
    [detected_os]="Detected OS"
    [run_as_root]="Please run this script as root (sudo)"
    [no_ssh_keys]="No SSH keys found in /root/.ssh/authorized_keys!\nAdd your public key before running this script."
    [ssh_key_found]="SSH key found"
    [enter_ssh_port]="Enter SSH port"
    [random_port_hint]="Suggested random port"
    [invalid_port]="Invalid port. Enter a number between 1024 and 65535"
    [panel_ips_empty]="Leave empty to skip (press Enter)"
    [install_question]="Install/Enable?"
    [selected_settings]="Selected settings"
    [continue_confirm]="Continue with these settings?"
    [cancelled]="Cancelled by user"
    [yes]="yes"
    [no]="no"
    [skipped]="skipped"
    [enabled]="enabled"
    [disabled]="disabled"
    [step]="Step"
    [of]="of"
    [installing]="Installing"
    [configuring]="Configuring"
    [done]="Done"
    [failed]="Failed"
    [backup_created]="Backup created"
    [server_secured]="Server successfully secured!"
    [dry_run_notice]="DRY-RUN MODE: No changes applied"
    [useful_commands]="Useful commands"
    [report_saved]="Report saved to"
    [swap_exists]="Swap already exists"
    [swap_created]="Swap created"
    [current_timezone]="Current timezone"
    [enter_timezone]="Enter timezone (e.g., Europe/Moscow, UTC)"
    [timezone_set]="Timezone set to"
    [ipv6_disabled]="IPv6 disabled"
    [autoupdate_enabled]="Automatic security updates enabled"
    [tools_installed]="Admin tools installed"
    [total_ram]="Total RAM"
    [recommended_swap]="Recommended swap"
    [kernel_hardened]="Kernel hardening enabled"
    [netlimits_configured]="Network limits configured"
    [logrotate_configured]="Log rotation configured"
    [log_retention_prompt]="Log retention period in days"
    [log_retention_examples]="Examples: 30 (1 month), 90 (3 months), 365 (1 year)"
    [ntp_configured]="Time synchronization configured"
    [ratelimit_configured]="Rate limiting configured"
    [step_cleanup]="System Cleanup"
    [cleaning_apt_cache]="Cleaning apt cache..."
    [removing_orphaned]="Removing orphaned packages..."
    [cleaning_temp]="Cleaning old temporary files..."
    [cleanup_complete]="Cleanup complete"
    [freed]="freed"
)

declare -A MSG_RU=(
    [welcome]="Добро пожаловать в Secure VPS Setup"
    [for_beginners]="Режим для начинающих: каждая опция с объяснением"
    [select_lang]="Выберите язык"
    [checking_system]="Проверка системных требований..."
    [os_not_supported]="Скрипт поддерживает только Debian 11+ или Ubuntu 20.04+"
    [detected_os]="Обнаружена ОС"
    [run_as_root]="Запустите скрипт от root (sudo)"
    [no_ssh_keys]="SSH-ключи не найдены в /root/.ssh/authorized_keys!\nДобавьте публичный ключ перед запуском."
    [ssh_key_found]="SSH-ключ найден"
    [enter_ssh_port]="Введите SSH-порт"
    [random_port_hint]="Предложенный случайный порт"
    [invalid_port]="Некорректный порт. Введите число от 1024 до 65535"
    [panel_ips_empty]="Оставьте пустым для пропуска (нажмите Enter)"
    [install_question]="Установить/Включить?"
    [selected_settings]="Выбранные настройки"
    [continue_confirm]="Продолжить с этими настройками?"
    [cancelled]="Отменено пользователем"
    [yes]="да"
    [no]="нет"
    [skipped]="пропущено"
    [enabled]="включено"
    [disabled]="отключено"
    [step]="Шаг"
    [of]="из"
    [installing]="Установка"
    [configuring]="Настройка"
    [done]="Готово"
    [failed]="Ошибка"
    [backup_created]="Бэкап создан"
    [server_secured]="Сервер успешно защищён!"
    [dry_run_notice]="РЕЖИМ DRY-RUN: Изменения не применяются"
    [useful_commands]="Полезные команды"
    [report_saved]="Отчёт сохранён в"
    [swap_exists]="Swap уже существует"
    [swap_created]="Swap создан"
    [current_timezone]="Текущий часовой пояс"
    [enter_timezone]="Введите часовой пояс (напр. Europe/Moscow, UTC)"
    [timezone_set]="Часовой пояс установлен"
    [ipv6_disabled]="IPv6 отключён"
    [autoupdate_enabled]="Автообновления безопасности включены"
    [tools_installed]="Утилиты установлены"
    [total_ram]="Всего RAM"
    [recommended_swap]="Рекомендуемый swap"
    [kernel_hardened]="Защита ядра включена"
    [netlimits_configured]="Сетевые лимиты настроены"
    [logrotate_configured]="Ротация логов настроена"
    [log_retention_prompt]="Срок хранения логов в днях"
    [log_retention_examples]="Примеры: 30 (1 мес), 90 (3 мес), 365 (1 год)"
    [ntp_configured]="Синхронизация времени настроена"
    [ratelimit_configured]="Ограничение соединений настроено"
    [step_cleanup]="Очистка системы"
    [cleaning_apt_cache]="Очистка кэша apt..."
    [removing_orphaned]="Удаление ненужных пакетов..."
    [cleaning_temp]="Очистка старых временных файлов..."
    [cleanup_complete]="Очистка завершена"
    [freed]="освобождено"
)

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

setup_colors() {
    if [[ "$NO_COLOR" == "true" ]] || [[ ! -t 1 ]]; then
        RED="" GREEN="" YELLOW="" BLUE="" CYAN="" MAGENTA="" BOLD="" DIM="" RESET=""
    else
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[1;33m'
        BLUE='\033[0;34m'
        CYAN='\033[0;36m'
        MAGENTA='\033[0;35m'
        BOLD='\033[1m'
        DIM='\033[2m'
        RESET='\033[0m'
    fi
}

msg() {
    local key="$1"
    if [[ "$LANG_CODE" == "ru" ]]; then
        echo "${MSG_RU[$key]:-$key}"
    else
        echo "${MSG_EN[$key]:-$key}"
    fi
}

desc() {
    local key="$1"
    if [[ "$LANG_CODE" == "ru" ]]; then
        echo "${DESC_RU[$key]:-}"
    else
        echo "${DESC_EN[$key]:-}"
    fi
}

log_info() { echo -e "${BLUE}ℹ${RESET}  $*" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${BLUE}ℹ${RESET}  $*"; }
log_success() { echo -e "${GREEN}✅${RESET} $*" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${GREEN}✅${RESET} $*"; }
log_warning() { echo -e "${YELLOW}⚠️${RESET}  $*" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${YELLOW}⚠️${RESET}  $*"; }
log_error() { echo -e "${RED}❌${RESET} $*" | tee -a "$LOG_FILE" 2>/dev/null >&2 || echo -e "${RED}❌${RESET} $*" >&2; }
log_step() { echo -e "\n${BOLD}${CYAN}═══ $* ═══${RESET}" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "\n${BOLD}${CYAN}═══ $* ═══${RESET}"; }

die() { log_error "$1"; exit "${2:-1}"; }
require_root() { [[ $EUID -eq 0 ]] || die "$(msg run_as_root)"; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }
pkg_installed() { dpkg -s "$1" >/dev/null 2>&1; }

is_interactive() {
    if [[ "$INTERACTIVE" == "false" ]]; then return 1
    elif [[ "$INTERACTIVE" == "true" ]]; then return 0
    else [[ -t 0 ]]; fi
}

generate_random_port() {
    echo $((RANDOM % 40000 + 10000))
}

validate_port() {
    local port="$1"
    [[ "$port" =~ ^[0-9]+$ ]] && [[ "$port" -ge 1024 ]] && [[ "$port" -le 65535 ]]
}

validate_ip() {
    local ip="$1"
    [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
}

apt_install() {
    local packages=("$@")
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] apt install -y ${packages[*]}"
        return 0
    fi
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${packages[@]}" >/dev/null 2>&1
}

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp "$file" "${BACKUP_DIR}/$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
    fi
}

write_config() {
    local path="$1"
    local content="$2"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] Would create: $path"
        return 0
    fi
    backup_file "$path"
    mkdir -p "$(dirname "$path")"
    echo "$content" > "$path"
}

systemd_setup() {
    local service="$1"
    local action="${2:-restart}"
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "[DRY-RUN] systemctl $action $service"
        return 0
    fi
    systemctl daemon-reload >/dev/null 2>&1
    systemctl enable "$service" >/dev/null 2>&1
    systemctl "$action" "$service" >/dev/null 2>&1
}

# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE SETUP
# ══════════════════════════════════════════════════════════════════════════════

show_option_and_ask() {
    local title_key="$1"
    local desc_key="$2"
    local default="$3"
    local var_name="$4"
    
    echo ""
    echo -e "${BOLD}${CYAN}$(desc ${title_key})${RESET}"
    echo -e "${DIM}$(desc ${desc_key})${RESET}"
    echo ""
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="${CYAN}$(msg install_question)${RESET} [${YELLOW}Y${RESET}/n]: "
    else
        prompt="${CYAN}$(msg install_question)${RESET} [y/${YELLOW}N${RESET}]: "
    fi
    
    echo -en "$prompt"
    local response
    read -r response
    response="${response:-$default}"
    
    if [[ "$response" =~ ^[Yy] ]]; then
        eval "$var_name=true"
    else
        eval "$var_name=false"
    fi
}

select_language() {
    if [[ "$LANG_CODE" != "auto" ]]; then return; fi
    
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║           🌐 SELECT LANGUAGE / ВЫБЕРИТЕ ЯЗЫК                  ║${RESET}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "  ${CYAN}1)${RESET} English"
    echo -e "  ${CYAN}2)${RESET} Русский"
    echo ""
    echo -en "Choice / Выбор [1]: "
    
    local choice
    read -r choice
    case "$choice" in
        2) LANG_CODE="ru" ;;
        *) LANG_CODE="en" ;;
    esac
}

check_os() {
    log_info "$(msg checking_system)"
    
    if [[ ! -f /etc/os-release ]]; then
        die "$(msg os_not_supported)"
    fi
    
    source /etc/os-release
    local supported=false
    
    if [[ "$ID" == "debian" ]] && [[ "${VERSION_ID:-0}" -ge 11 ]]; then
        supported=true
    elif [[ "$ID" == "ubuntu" ]]; then
        local major_ver="${VERSION_ID%%.*}"
        [[ "$major_ver" -ge 20 ]] && supported=true
    fi
    
    if [[ "$supported" != "true" ]]; then
        die "$(msg os_not_supported)\n$(msg detected_os): $PRETTY_NAME"
    fi
    
    log_success "$(msg detected_os): $PRETTY_NAME"
}

interactive_setup() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║          🔧 $(msg welcome)                      ║${RESET}"
    echo -e "${BOLD}╠═══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}║  ${GREEN}$(msg for_beginners)${RESET}    ${BOLD}║${RESET}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    
    # 1. SSH Port
    show_option_and_ask "ssh_port_title" "ssh_port_desc" "y" "CHANGE_SSH_PORT"
    
    if [[ "$CHANGE_SSH_PORT" == "true" ]]; then
        local suggested_port=$(generate_random_port)
        echo -e "${BLUE}ℹ${RESET}  $(msg random_port_hint): ${GREEN}$suggested_port${RESET}"
        echo -en "${CYAN}$(msg enter_ssh_port)${RESET} [$suggested_port]: "
        read -r SSH_PORT
        SSH_PORT="${SSH_PORT:-$suggested_port}"
        
        while ! validate_port "$SSH_PORT"; do
            log_error "$(msg invalid_port)"
            echo -en "${CYAN}$(msg enter_ssh_port)${RESET}: "
            read -r SSH_PORT
        done
    else
        SSH_PORT="22"
    fi
    
    # 2. Panel IPs
    echo ""
    echo -e "${BOLD}${CYAN}$(desc panel_ips_title)${RESET}"
    echo -e "${DIM}$(desc panel_ips_desc)${RESET}"
    echo ""
    echo -e "${DIM}$(msg panel_ips_empty)${RESET}"
    echo -en "${CYAN}IP:${RESET} "
    read -r PANEL_IPS
    
    # 3-12. Other options
    show_option_and_ask "docker_title" "docker_desc" "y" "INSTALL_DOCKER"
    show_option_and_ask "fail2ban_title" "fail2ban_desc" "y" "INSTALL_FAIL2BAN"
    show_option_and_ask "bbr_title" "bbr_desc" "y" "ENABLE_BBR"
    show_option_and_ask "kernel_title" "kernel_desc" "y" "KERNEL_HARDENING"
    show_option_and_ask "netlimits_title" "netlimits_desc" "y" "SETUP_NETLIMITS"
    show_option_and_ask "logrotate_title" "logrotate_desc" "y" "SETUP_LOGROTATE"
    
    # Ask for log retention if logrotate enabled
    if [[ "$SETUP_LOGROTATE" == "true" ]]; then
        echo ""
        echo -e "${DIM}$(msg log_retention_examples)${RESET}"
        echo -en "${CYAN}$(msg log_retention_prompt)${RESET} [90]: "
        read -r LOG_RETENTION_DAYS
        LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-90}"
        # Validate number
        if ! [[ "$LOG_RETENTION_DAYS" =~ ^[0-9]+$ ]]; then
            LOG_RETENTION_DAYS=90
        fi
    fi
    
    show_option_and_ask "ntp_title" "ntp_desc" "y" "SETUP_NTP"
    show_option_and_ask "swap_title" "swap_desc" "y" "SETUP_SWAP"
    show_option_and_ask "autoupdate_title" "autoupdate_desc" "y" "SETUP_AUTOUPDATE"
    show_option_and_ask "tools_title" "tools_desc" "y" "INSTALL_TOOLS"
    show_option_and_ask "timezone_title" "timezone_desc" "n" "SETUP_TIMEZONE"
    show_option_and_ask "tblocker_title" "tblocker_desc" "n" "INSTALL_TBLOCKER"
    show_option_and_ask "ratelimit_title" "ratelimit_desc" "n" "SETUP_RATELIMIT"
    show_option_and_ask "icmp_title" "icmp_desc" "n" "BLOCK_ICMP"
    show_option_and_ask "ipv6_title" "ipv6_desc" "n" "DISABLE_IPV6"
    
    # Summary
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}║              📋 $(msg selected_settings)                       ║${RESET}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    show_setting() {
        local name="$1" value="$2"
        if [[ "$value" == "true" ]]; then
            echo -e "   $name: ${GREEN}$(msg yes)${RESET}"
        else
            echo -e "   $name: ${YELLOW}$(msg no)${RESET}"
        fi
    }
    
    echo -e "   SSH Port:          ${GREEN}$SSH_PORT${RESET}"
    [[ -n "$PANEL_IPS" ]] && echo -e "   Panel IPs:         ${GREEN}$PANEL_IPS${RESET}"
    show_setting "Docker" "$INSTALL_DOCKER"
    show_setting "Fail2Ban" "$INSTALL_FAIL2BAN"
    show_setting "BBR" "$ENABLE_BBR"
    show_setting "Kernel Hardening" "$KERNEL_HARDENING"
    show_setting "Network Limits" "$SETUP_NETLIMITS"
    show_setting "Logrotate" "$SETUP_LOGROTATE"
    [[ "$SETUP_LOGROTATE" == "true" ]] && echo -e "   Log retention:     ${GREEN}${LOG_RETENTION_DAYS} days${RESET}"
    show_setting "NTP Sync" "$SETUP_NTP"
    show_setting "Swap" "$SETUP_SWAP"
    show_setting "Auto-updates" "$SETUP_AUTOUPDATE"
    show_setting "Admin tools" "$INSTALL_TOOLS"
    show_setting "Timezone" "$SETUP_TIMEZONE"
    show_setting "Torrent Blocker" "$INSTALL_TBLOCKER"
    show_setting "Rate Limiting" "$SETUP_RATELIMIT"
    show_setting "Block ICMP" "$BLOCK_ICMP"
    show_setting "Disable IPv6" "$DISABLE_IPV6"
    
    echo ""
    echo -en "${CYAN}$(msg continue_confirm)${RESET} [Y/n]: "
    local confirm
    read -r confirm
    if [[ "$confirm" =~ ^[Nn] ]]; then
        die "$(msg cancelled)"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ARGUMENT PARSING
# ══════════════════════════════════════════════════════════════════════════════

show_help() {
    cat <<'HELP'
Secure VPS Setup Script

Usage: bash secure-vps-setup.sh [OPTIONS]

Options:
  --dry-run           Preview changes without applying
  --no-interactive    Skip interactive prompts
  --lang LANG         Set language (en/ru)
  --port PORT         Set SSH port
  --panel-ips IPS     Panel access IPs (comma-separated)
  
  --skip-docker       Skip Docker
  --skip-fail2ban     Skip Fail2Ban
  --skip-bbr          Skip BBR
  --skip-swap         Skip Swap
  --skip-autoupdate   Skip auto-updates
  --skip-tools        Skip admin tools
  
  -h, --help          Show this help

Examples:
  ./secure-vps-setup.sh                    # Interactive mode
  ./secure-vps-setup.sh --dry-run          # Preview changes
  ./secure-vps-setup.sh --lang ru          # Russian interface
HELP
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)        DRY_RUN=true ;;
            --no-color)       NO_COLOR=true ;;
            --no-interactive) INTERACTIVE=false ;;
            --lang)           LANG_CODE="$2"; shift ;;
            --port)           SSH_PORT="$2"; CHANGE_SSH_PORT=true; shift ;;
            --panel-ips)      PANEL_IPS="$2"; shift ;;
            --skip-docker)    INSTALL_DOCKER=false ;;
            --skip-fail2ban)  INSTALL_FAIL2BAN=false ;;
            --skip-bbr)       ENABLE_BBR=false ;;
            --skip-kernel)    KERNEL_HARDENING=false ;;
            --skip-netlimits) SETUP_NETLIMITS=false ;;
            --skip-logrotate) SETUP_LOGROTATE=false ;;
            --log-retention)  LOG_RETENTION_DAYS="$2"; shift ;;
            --skip-ntp)       SETUP_NTP=false ;;
            --skip-swap)      SETUP_SWAP=false ;;
            --skip-autoupdate) SETUP_AUTOUPDATE=false ;;
            --skip-tools)     INSTALL_TOOLS=false ;;
            --skip-tblocker)  INSTALL_TBLOCKER=false ;;
            --enable-ratelimit) SETUP_RATELIMIT=true ;;
            --skip-icmp)      BLOCK_ICMP=false ;;
            --skip-ipv6)      DISABLE_IPV6=false ;;
            -h|--help)        show_help; exit 0 ;;
            *) log_warning "Unknown option: $1" ;;
        esac
        shift
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ══════════════════════════════════════════════════════════════════════════════

parse_args "$@"
setup_colors

# Language selection
if is_interactive; then
    select_language
fi
LANG_CODE="${LANG_CODE:-en}"

require_root
check_os

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"
echo "=== VPS Setup $(date) ===" >> "$LOG_FILE"

if [[ "$DRY_RUN" == "true" ]]; then
    echo ""
    log_warning "$(msg dry_run_notice)"
fi

# Interactive configuration
if is_interactive; then
    interactive_setup
fi

# Set defaults for non-interactive
INSTALL_DOCKER="${INSTALL_DOCKER:-true}"
INSTALL_FAIL2BAN="${INSTALL_FAIL2BAN:-true}"
ENABLE_BBR="${ENABLE_BBR:-true}"
KERNEL_HARDENING="${KERNEL_HARDENING:-true}"
SETUP_NETLIMITS="${SETUP_NETLIMITS:-true}"
SETUP_LOGROTATE="${SETUP_LOGROTATE:-true}"
SETUP_NTP="${SETUP_NTP:-true}"
SETUP_SWAP="${SETUP_SWAP:-true}"
SETUP_AUTOUPDATE="${SETUP_AUTOUPDATE:-true}"
INSTALL_TOOLS="${INSTALL_TOOLS:-true}"
INSTALL_TBLOCKER="${INSTALL_TBLOCKER:-false}"
SETUP_RATELIMIT="${SETUP_RATELIMIT:-false}"
BLOCK_ICMP="${BLOCK_ICMP:-false}"
DISABLE_IPV6="${DISABLE_IPV6:-false}"
SETUP_TIMEZONE="${SETUP_TIMEZONE:-false}"
CHANGE_SSH_PORT="${CHANGE_SSH_PORT:-true}"
SSH_PORT="${SSH_PORT:-22}"

export DEBIAN_FRONTEND=noninteractive

STEP=0
TOTAL_STEPS=16

next_step() {
    ((STEP++))
    log_step "$(msg step) $STEP $(msg of) $TOTAL_STEPS: $1"
}

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 1: SSH Configuration
# ══════════════════════════════════════════════════════════════════════════════

next_step "SSH"

if [[ ! -s /root/.ssh/authorized_keys ]]; then
    die "$(msg no_ssh_keys)"
fi
log_success "$(msg ssh_key_found)"

if [[ "$CHANGE_SSH_PORT" == "true" ]] && [[ "$SSH_PORT" != "22" ]]; then
    if [[ "$DRY_RUN" != "true" ]]; then
        grep -Rl "^Port 22" /etc/ssh/sshd_config /etc/ssh/sshd_config.d 2>/dev/null \
            | xargs -r sed -i 's/^Port 22/#Port 22/g' || true
    fi
fi

SSH_CONFIG="# Auto-generated SSH config
Port $SSH_PORT
PasswordAuthentication no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
PermitRootLogin prohibit-password
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowTcpForwarding no"

write_config "$SSH_CONF_PATH" "$SSH_CONFIG"

if [[ "$DRY_RUN" != "true" ]]; then
    if sshd -t 2>/dev/null; then
        systemctl restart ssh >/dev/null 2>&1 || systemctl restart sshd >/dev/null 2>&1
        log_success "SSH configured on port $SSH_PORT"
    else
        log_error "SSH config error!"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 2: Base Packages
# ══════════════════════════════════════════════════════════════════════════════

next_step "$(msg installing) packages"

if [[ "$DRY_RUN" != "true" ]]; then
    apt-get update -y >/dev/null 2>&1
fi

BASE_PKGS=(ca-certificates curl wget gnupg jq unzip nano git ufw cron)
apt_install "${BASE_PKGS[@]}"

# Docker
if [[ "$INSTALL_DOCKER" == "true" ]]; then
    if cmd_exists docker; then
        log_info "Docker already installed"
    else
        log_info "$(msg installing) Docker..."
        if [[ "$DRY_RUN" != "true" ]]; then
            curl -fsSL https://get.docker.com | sh >/dev/null 2>&1
            systemctl enable docker >/dev/null 2>&1
            log_success "Docker installed"
        fi
    fi
fi

# Admin tools
if [[ "$INSTALL_TOOLS" == "true" ]]; then
    log_info "$(msg installing) htop, ncdu, vnstat, tmux..."
    apt_install htop ncdu vnstat tmux
    log_success "$(msg tools_installed)"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 3: UFW Firewall
# ══════════════════════════════════════════════════════════════════════════════

next_step "UFW Firewall"

if [[ "$DRY_RUN" != "true" ]]; then
    ufw disable >/dev/null 2>&1 || true
    ufw --force reset >/dev/null 2>&1
    
    ufw allow 443/tcp comment 'HTTPS' >/dev/null 2>&1
    ufw allow "${SSH_PORT}/tcp" comment 'SSH' >/dev/null 2>&1
    
    if [[ -n "$PANEL_IPS" ]]; then
        IFS=',' read -ra IPS <<< "$PANEL_IPS"
        for ip in "${IPS[@]}"; do
            ip=$(echo "$ip" | xargs)
            ufw allow from "$ip" to any port "$PANEL_PORT" comment 'Panel' >/dev/null 2>&1
            log_info "UFW: $ip → port $PANEL_PORT"
        done
    fi
    
    ufw --force enable >/dev/null 2>&1
    log_success "UFW configured"
fi

# ICMP blocking
if [[ "$BLOCK_ICMP" == "true" ]]; then
    log_info "Blocking ICMP..."
    if [[ "$DRY_RUN" != "true" ]]; then
        iptables -D INPUT -p icmp --icmp-type echo-request -j DROP 2>/dev/null || true
        iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4
        
        # Create systemd service for persistence
        cat > /etc/systemd/system/iptables-restore.service <<'IPTSERVICE'
[Unit]
Description=Restore iptables
Before=network-pre.target
[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables/rules.v4
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
IPTSERVICE
        systemd_setup "iptables-restore.service" "start"
        log_success "ICMP blocked"
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 4: Fail2Ban
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$INSTALL_FAIL2BAN" == "true" ]]; then
    next_step "Fail2Ban"
    
    apt_install fail2ban
    
    # Soft ban (10 min)
    write_config "/etc/fail2ban/jail.d/sshd-softban.conf" "[sshd-softban]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
backend = systemd
maxretry = 3
findtime = 300
bantime = 600"
    
    # Recidive (1 hour)
    write_config "/etc/fail2ban/jail.d/recidive.conf" "[recidive]
enabled = true
logpath = /var/log/fail2ban.log
maxretry = 3
findtime = 86400
bantime = 3600"
    
    # Hard ban (24 hours)
    write_config "/etc/fail2ban/jail.d/sshd-hardban.conf" "[sshd-hardban]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
backend = systemd
maxretry = 10
findtime = 86400
bantime = 86400"
    
    # Permanent ban
    write_config "/etc/fail2ban/jail.d/sshd-permanent.conf" "[sshd-permanent]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
backend = systemd
maxretry = 20
findtime = 86400
bantime = -1"
    
    systemd_setup "fail2ban" "restart"
    log_success "Fail2Ban configured (4 levels)"
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 5: Swap
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$SETUP_SWAP" == "true" ]]; then
    next_step "Swap"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        if swapon --show | grep -q '/'; then
            log_info "$(msg swap_exists)"
        else
            # Calculate swap size
            TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
            TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
            
            if [[ $TOTAL_RAM_GB -le 2 ]]; then
                SWAP_SIZE="2G"
            elif [[ $TOTAL_RAM_GB -le 4 ]]; then
                SWAP_SIZE="4G"
            else
                SWAP_SIZE="4G"
            fi
            
            log_info "$(msg total_ram): ${TOTAL_RAM_GB}GB, $(msg recommended_swap): $SWAP_SIZE"
            
            fallocate -l $SWAP_SIZE /swapfile 2>/dev/null || dd if=/dev/zero of=/swapfile bs=1M count=$((${SWAP_SIZE%G} * 1024)) 2>/dev/null
            chmod 600 /swapfile
            mkswap /swapfile >/dev/null 2>&1
            swapon /swapfile
            
            if ! grep -q '/swapfile' /etc/fstab; then
                echo '/swapfile none swap sw 0 0' >> /etc/fstab
            fi
            
            # Optimize swappiness
            echo 'vm.swappiness=10' > /etc/sysctl.d/99-swap.conf
            sysctl -p /etc/sysctl.d/99-swap.conf >/dev/null 2>&1
            
            log_success "$(msg swap_created): $SWAP_SIZE"
        fi
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 6: BBR & TCP Optimizations
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$ENABLE_BBR" == "true" ]]; then
    next_step "BBR + TCP"
    
    SYSCTL_CONFIG='# Network optimizations
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.ipv4.tcp_rmem=4096 87380 33554432
net.ipv4.tcp_wmem=4096 65536 33554432
net.ipv4.tcp_fastopen=3
net.ipv4.tcp_mtu_probing=1
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_no_metrics_save=1
net.ipv4.tcp_slow_start_after_idle=0'
    
    write_config "/etc/sysctl.d/99-bbr.conf" "$SYSCTL_CONFIG"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        sysctl --system >/dev/null 2>&1
        BBR_STATUS=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "unknown")
        log_success "BBR: $BBR_STATUS"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 7: Kernel Hardening
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$KERNEL_HARDENING" == "true" ]]; then
    next_step "Kernel Hardening"
    
    KERNEL_CONFIG='# Kernel Hardening for VPN Server
# Anti-spoofing (reverse path filtering)
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1

# Ignore ICMP redirects (prevent MITM attacks)
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
net.ipv6.conf.all.accept_redirects=0
net.ipv6.conf.default.accept_redirects=0

# Do not send ICMP redirects
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

# Disable source routing (prevent forced routing)
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0
net.ipv6.conf.default.accept_source_route=0

# SYN flood protection
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.tcp_synack_retries=2
net.ipv4.tcp_syn_retries=2

# Log suspicious packets (martians)
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1

# Ignore ICMP broadcasts (prevent smurf attacks)
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.icmp_ignore_bogus_error_responses=1

# Disable IPv6 router advertisements
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.default.accept_ra=0

# Protect against time-wait assassination
net.ipv4.tcp_rfc1337=1'
    
    write_config "/etc/sysctl.d/99-kernel-hardening.conf" "$KERNEL_CONFIG"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        sysctl --system >/dev/null 2>&1
        log_success "$(msg kernel_hardened)"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 8: Network Limits (Conntrack)
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$SETUP_NETLIMITS" == "true" ]]; then
    next_step "Network Limits"
    
    # Calculate optimal values based on RAM
    if [[ "$DRY_RUN" != "true" ]]; then
        TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        TOTAL_RAM_MB=$((TOTAL_RAM_KB / 1024))
        
        # Each connection uses ~300 bytes, calculate max based on RAM
        # Use 5% of RAM for conntrack (safe default)
        CONNTRACK_MAX=$((TOTAL_RAM_MB * 1024 * 5 / 100 / 300))
        
        # Minimum 131072, maximum 2097152
        [[ $CONNTRACK_MAX -lt 131072 ]] && CONNTRACK_MAX=131072
        [[ $CONNTRACK_MAX -gt 2097152 ]] && CONNTRACK_MAX=2097152
        
        # Hash size = conntrack_max / 4
        HASH_SIZE=$((CONNTRACK_MAX / 4))
    else
        CONNTRACK_MAX=262144
        HASH_SIZE=65536
    fi
    
    NETLIMITS_CONFIG="# Network connection limits for VPN
# Calculated based on RAM: max=$CONNTRACK_MAX

# Connection tracking limits
net.netfilter.nf_conntrack_max=$CONNTRACK_MAX
net.nf_conntrack_max=$CONNTRACK_MAX

# Hash table size (conntrack_max / 4)
net.netfilter.nf_conntrack_buckets=$HASH_SIZE

# Timeout optimizations for VPN
net.netfilter.nf_conntrack_tcp_timeout_established=3600
net.netfilter.nf_conntrack_tcp_timeout_time_wait=30
net.netfilter.nf_conntrack_tcp_timeout_close_wait=15
net.netfilter.nf_conntrack_tcp_timeout_fin_wait=30
net.netfilter.nf_conntrack_udp_timeout=30
net.netfilter.nf_conntrack_udp_timeout_stream=60

# Increase local port range
net.ipv4.ip_local_port_range=1024 65535

# Increase socket backlog
net.core.somaxconn=65535
net.core.netdev_max_backlog=65535

# File descriptors
fs.file-max=2097152
fs.nr_open=2097152"
    
    write_config "/etc/sysctl.d/99-netlimits.conf" "$NETLIMITS_CONFIG"
    
    # Also set conntrack hashsize via modprobe
    write_config "/etc/modprobe.d/nf_conntrack.conf" "options nf_conntrack hashsize=$HASH_SIZE"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        # Load conntrack module if not loaded
        modprobe nf_conntrack 2>/dev/null || true
        
        # Apply settings
        sysctl --system >/dev/null 2>&1
        
        # Try to set hashsize directly
        echo $HASH_SIZE > /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || true
        
        log_success "$(msg netlimits_configured): max=$CONNTRACK_MAX"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 9: Logrotate
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$SETUP_LOGROTATE" == "true" ]]; then
    next_step "Logrotate"
    
    # Calculate rotate count (daily rotation, keep for LOG_RETENTION_DAYS)
    ROTATE_COUNT="${LOG_RETENTION_DAYS:-90}"
    
    # Main VPN/Remnawave logs
    LOGROTATE_VPN="/var/log/remnanode/*.log {
    daily
    rotate $ROTATE_COUNT
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    dateext
    dateformat -%Y%m%d
}"
    
    write_config "/etc/logrotate.d/remnanode" "$LOGROTATE_VPN"
    
    # VPS Setup logs
    LOGROTATE_SETUP="/var/log/vps-setup.log {
    weekly
    rotate 12
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}"
    
    write_config "/etc/logrotate.d/vps-setup" "$LOGROTATE_SETUP"
    
    # Auth logs (SSH attempts) - important for security
    LOGROTATE_AUTH="/var/log/auth.log {
    daily
    rotate $ROTATE_COUNT
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    dateext
    dateformat -%Y%m%d
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate 2>/dev/null || true
    endscript
}"
    
    write_config "/etc/logrotate.d/auth-custom" "$LOGROTATE_AUTH"
    
    # Fail2ban logs
    LOGROTATE_FAIL2BAN="/var/log/fail2ban.log {
    daily
    rotate $ROTATE_COUNT
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root adm
    postrotate
        fail2ban-client flushlogs 2>/dev/null || true
    endscript
}"
    
    write_config "/etc/logrotate.d/fail2ban-custom" "$LOGROTATE_FAIL2BAN"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        # Create log directory if not exists
        mkdir -p /var/log/remnanode
        
        # Test logrotate config
        logrotate -d /etc/logrotate.d/remnanode >/dev/null 2>&1 || true
        
        log_success "$(msg logrotate_configured): ${ROTATE_COUNT} days"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 10: NTP Time Sync
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$SETUP_NTP" == "true" ]]; then
    next_step "NTP"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        # Stop and disable conflicting services
        systemctl stop systemd-timesyncd 2>/dev/null || true
        systemctl disable systemd-timesyncd 2>/dev/null || true
        
        # Install chrony (more accurate than ntpd)
        apt_install chrony
        
        # Configure chrony with reliable servers
        CHRONY_CONFIG="# Chrony configuration for VPN server
# Use pool servers
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst
pool 2.pool.ntp.org iburst
pool 3.pool.ntp.org iburst

# Use Google NTP as fallback
server time.google.com iburst

# Record the rate at which the system clock gains/losses time
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC)
rtcsync

# Enable hardware timestamping on all interfaces
#hwtimestamp *

# Specify directory for log files
logdir /var/log/chrony"
        
        write_config "/etc/chrony/chrony.conf" "$CHRONY_CONFIG"
        
        systemd_setup "chrony" "restart"
        
        # Force initial sync
        chronyc makestep >/dev/null 2>&1 || true
        
        # Check sync status
        sleep 2
        SYNC_STATUS=$(chronyc tracking 2>/dev/null | grep "Leap status" | awk '{print $4}' || echo "unknown")
        
        log_success "$(msg ntp_configured): $SYNC_STATUS"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 11: Timezone
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$SETUP_TIMEZONE" == "true" ]]; then
    next_step "Timezone"
    
    CURRENT_TZ=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
    log_info "$(msg current_timezone): $CURRENT_TZ"
    
    if is_interactive; then
        echo -en "${CYAN}$(msg enter_timezone)${RESET} [$CURRENT_TZ]: "
        read -r NEW_TZ
        NEW_TZ="${NEW_TZ:-$CURRENT_TZ}"
    else
        NEW_TZ="UTC"
    fi
    
    if [[ "$DRY_RUN" != "true" ]]; then
        timedatectl set-timezone "$NEW_TZ" 2>/dev/null || true
        log_success "$(msg timezone_set): $NEW_TZ"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 12: Auto-updates
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$SETUP_AUTOUPDATE" == "true" ]]; then
    next_step "Auto-updates"
    
    apt_install unattended-upgrades apt-listchanges
    
    AUTOUPDATE_CONFIG='APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";'
    
    write_config "/etc/apt/apt.conf.d/20auto-upgrades" "$AUTOUPDATE_CONFIG"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        dpkg-reconfigure -f noninteractive unattended-upgrades >/dev/null 2>&1 || true
        log_success "$(msg autoupdate_enabled)"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 13: Disable IPv6
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$DISABLE_IPV6" == "true" ]]; then
    next_step "Disable IPv6"
    
    IPV6_CONFIG='net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1'
    
    write_config "/etc/sysctl.d/99-disable-ipv6.conf" "$IPV6_CONFIG"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        sysctl --system >/dev/null 2>&1
        log_success "$(msg ipv6_disabled)"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 14: Torrent Blocker
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$INSTALL_TBLOCKER" == "true" ]]; then
    next_step "Torrent Blocker"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        curl -fsSL https://repo.remna.dev/xray-tools/public.gpg \
            | gpg --yes --dearmor -o /usr/share/keyrings/openrepo-xray-tools.gpg 2>/dev/null
        
        echo "deb [arch=any signed-by=/usr/share/keyrings/openrepo-xray-tools.gpg] https://repo.remna.dev/xray-tools/ stable main" \
            > /etc/apt/sources.list.d/openrepo-xray-tools.list
        
        apt-get update -y >/dev/null 2>&1
        apt_install tblocker
        
        mkdir -p /var/log/remnanode /opt/tblocker
        
        TBLOCKER_CONFIG='LogFile: "/var/log/remnanode/access.log"
BlockDuration: 10
TorrentTag: "TORRENT"
BlockMode: "iptables"
BypassIPS: ["127.0.0.1", "::1"]
StorageDir: "/opt/tblocker"'
        
        write_config "/opt/tblocker/config.yaml" "$TBLOCKER_CONFIG"
        systemd_setup "tblocker" "restart"
        log_success "Torrent Blocker installed"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
#  STEP 15: Rate Limiting (Optional)
# ══════════════════════════════════════════════════════════════════════════════

if [[ "$SETUP_RATELIMIT" == "true" ]]; then
    next_step "Rate Limiting"
    
    if [[ "$DRY_RUN" != "true" ]]; then
        # Create rate limiting rules for SSH
        # Limit: 10 new connections per minute per IP
        
        # Remove existing rules if any
        iptables -D INPUT -p tcp --dport "$SSH_PORT" -m state --state NEW -m recent --set --name SSH 2>/dev/null || true
        iptables -D INPUT -p tcp --dport "$SSH_PORT" -m state --state NEW -m recent --update --seconds 60 --hitcount 10 --name SSH -j DROP 2>/dev/null || true
        
        # Add new rules
        iptables -A INPUT -p tcp --dport "$SSH_PORT" -m state --state NEW -m recent --set --name SSH
        iptables -A INPUT -p tcp --dport "$SSH_PORT" -m state --state NEW -m recent --update --seconds 60 --hitcount 10 --name SSH -j DROP
        
        # Limit concurrent connections per IP (max 20)
        iptables -D INPUT -p tcp --dport "$SSH_PORT" -m connlimit --connlimit-above 20 -j DROP 2>/dev/null || true
        iptables -A INPUT -p tcp --dport "$SSH_PORT" -m connlimit --connlimit-above 20 -j DROP
        
        # Panel port rate limiting if configured
        if [[ -n "$PANEL_IPS" ]]; then
            iptables -D INPUT -p tcp --dport "$PANEL_PORT" -m state --state NEW -m recent --set --name PANEL 2>/dev/null || true
            iptables -D INPUT -p tcp --dport "$PANEL_PORT" -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name PANEL -j DROP 2>/dev/null || true
            
            iptables -A INPUT -p tcp --dport "$PANEL_PORT" -m state --state NEW -m recent --set --name PANEL
            iptables -A INPUT -p tcp --dport "$PANEL_PORT" -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name PANEL -j DROP
        fi
        
        # Save rules
        mkdir -p /etc/iptables
        iptables-save > /etc/iptables/rules.v4
        
        log_success "$(msg ratelimit_configured)"
    fi
else
    ((TOTAL_STEPS--))
fi

# ══════════════════════════════════════════════════════════════════════════════
# 🧹 STEP: SYSTEM CLEANUP (always runs - safe operations)
# ══════════════════════════════════════════════════════════════════════════════

next_step "🧹 $(msg step_cleanup)"

# Get initial disk usage
DISK_BEFORE=$(df / --output=used -B1 2>/dev/null | tail -1)

# Clean apt cache
log_info "$(msg cleaning_apt_cache)"
apt-get clean >/dev/null 2>&1 || true
apt-get autoclean >/dev/null 2>&1 || true

# Remove orphaned packages
log_info "$(msg removing_orphaned)"
apt-get autoremove -y >/dev/null 2>&1 || true

# Clean old temporary files (older than 7 days)
log_info "$(msg cleaning_temp)"
find /tmp -type f -atime +7 -delete 2>/dev/null || true
find /var/tmp -type f -atime +7 -delete 2>/dev/null || true

# Clean old systemd journal (keep only last 100M)
if command -v journalctl >/dev/null 2>&1; then
    journalctl --vacuum-size=100M >/dev/null 2>&1 || true
fi

# Get final disk usage and calculate freed space
DISK_AFTER=$(df / --output=used -B1 2>/dev/null | tail -1)
if [[ -n "$DISK_BEFORE" && -n "$DISK_AFTER" && "$DISK_BEFORE" -gt "$DISK_AFTER" ]]; then
    FREED_BYTES=$((DISK_BEFORE - DISK_AFTER))
    if [[ "$FREED_BYTES" -gt 1073741824 ]]; then
        FREED_HUMAN="$(echo "scale=2; $FREED_BYTES/1073741824" | bc) GB"
    elif [[ "$FREED_BYTES" -gt 1048576 ]]; then
        FREED_HUMAN="$(echo "scale=2; $FREED_BYTES/1048576" | bc) MB"
    else
        FREED_HUMAN="$((FREED_BYTES/1024)) KB"
    fi
    log_success "$(msg cleanup_complete): $FREED_HUMAN $(msg freed)"
else
    log_success "$(msg cleanup_complete)"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  FINAL REPORT
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}╔═══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║                    📊 SETUP COMPLETE                          ║${RESET}"
echo -e "${BOLD}╚═══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  🔐 SSH Port:        ${GREEN}$SSH_PORT${RESET}"
echo -e "  🧱 UFW:             ${GREEN}$(msg enabled)${RESET}"
[[ "$INSTALL_FAIL2BAN" == "true" ]] && echo -e "  🛡️  Fail2Ban:        ${GREEN}$(msg enabled)${RESET}"
[[ "$ENABLE_BBR" == "true" ]] && echo -e "  🚀 BBR:             ${GREEN}$(msg enabled)${RESET}"
[[ "$KERNEL_HARDENING" == "true" ]] && echo -e "  🔒 Kernel:          ${GREEN}$(msg enabled)${RESET}"
[[ "$SETUP_NETLIMITS" == "true" ]] && echo -e "  📊 Net Limits:      ${GREEN}$(msg enabled)${RESET}"
[[ "$SETUP_LOGROTATE" == "true" ]] && echo -e "  📝 Logrotate:       ${GREEN}$(msg enabled)${RESET}"
[[ "$SETUP_NTP" == "true" ]] && echo -e "  ⏰ NTP:             ${GREEN}$(msg enabled)${RESET}"
[[ "$SETUP_SWAP" == "true" ]] && echo -e "  💾 Swap:            ${GREEN}$(msg enabled)${RESET}"
[[ "$INSTALL_DOCKER" == "true" ]] && echo -e "  🐳 Docker:          ${GREEN}$(msg enabled)${RESET}"
[[ "$SETUP_AUTOUPDATE" == "true" ]] && echo -e "  🔄 Auto-updates:    ${GREEN}$(msg enabled)${RESET}"
[[ "$ENABLE_RATELIMIT" == "true" ]] && echo -e "  🔥 Rate Limit:      ${GREEN}$(msg enabled)${RESET}"
echo -e "  🧹 Cleanup:         ${GREEN}$(msg done)${RESET}"
echo ""

# Save report
REPORT_FILE="/root/vps-setup-$(date +%Y%m%d_%H%M%S).txt"
{
    echo "VPS Setup Report - $(date)"
    echo "================================"
    echo "SSH Port: $SSH_PORT"
    echo "Docker: $INSTALL_DOCKER"
    echo "Fail2Ban: $INSTALL_FAIL2BAN"
    echo "BBR: $ENABLE_BBR"
    echo "Kernel Hardening: $KERNEL_HARDENING"
    echo "Network Limits: $SETUP_NETLIMITS"
    echo "Logrotate: $SETUP_LOGROTATE"
    [[ "$SETUP_LOGROTATE" == "true" ]] && echo "Log Retention: ${LOG_RETENTION_DAYS} days"
    echo "NTP Sync: $SETUP_NTP"
    echo "Swap: $SETUP_SWAP"
    echo "Auto-updates: $SETUP_AUTOUPDATE"
    echo "Rate Limiting: $ENABLE_RATELIMIT"
    echo "Torrent Blocker: $INSTALL_TBLOCKER"
    echo "================================"
} > "$REPORT_FILE" 2>/dev/null || true

log_info "$(msg report_saved) $REPORT_FILE"

echo ""
echo -e "${BOLD}📋 $(msg useful_commands):${RESET}"
echo -e "   ${CYAN}ssh -p $SSH_PORT root@YOUR_SERVER${RESET}"
echo -e "   ${CYAN}ufw status${RESET}"
[[ "$INSTALL_FAIL2BAN" == "true" ]] && echo -e "   ${CYAN}fail2ban-client status${RESET}"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    log_warning "$(msg dry_run_notice)"
else
    echo -e "${GREEN}${BOLD}✅ $(msg server_secured)${RESET}"
fi

EOF

bash /tmp/secure_ssh.sh "$@" && rm -f /tmp/secure_ssh.sh
