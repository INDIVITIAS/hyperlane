#!/bin/bash

# Определения цветов и форматирования
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# Иконки для пунктов меню
ICON_TELEGRAM="🚀"
ICON_INSTALL="🛠️"
ICON_SSH="🔑"
ICON_START="▶️"
ICON_RESTART="🔄"
ICON_LOGS="📄"
ICON_DELETE="🗑️"
ICON_EXIT="❌"

# Функции для рисования границ
draw_top_border() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════╗${RESET}"
}

draw_middle_border() {
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════════╣${RESET}"
}

draw_bottom_border() {
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════╝${RESET}"
}

print_telegram_icon() {
    echo -e "          ${MAGENTA}${ICON_TELEGRAM} Подписывайтесь на наш Telegram!${RESET}"
}

# Логотип и информация
display_ascii() {
    echo -e "${CYAN}   ____   _  __   ___    ____ _   __   ____ ______   ____   ___    ____${RESET}"
    echo -e "${CYAN}  /  _/  / |/ /  / _ \\  /  _/| | / /  /  _//_  __/  /  _/  / _ |  / __/${RESET}"
    echo -e "${CYAN} _/ /   /    /  / // / _/ /  | |/ /  _/ /   / /    _/ /   / __ | _\\ \\  ${RESET}"
    echo -e "${CYAN}/___/  /_/|_/  /____/ /___/  |___/  /___/  /_/    /___/  /_/ |_|/___/  ${RESET}"
    echo -e ""
    echo -e "${YELLOW}Подписывайтесь на Telegram: https://t.me/CryptalikBTC${RESET}"
    echo -e "${YELLOW}Подписывайтесь на YouTube: https://www.youtube.com/@Cryptalik${RESET}"
    echo -e "${YELLOW}Здесь про аирдропы и ноды: https://t.me/indivitias${RESET}"
    echo -e "${YELLOW}Купи мне крипто бутылочку... ${ICON_KEFIR}кефира 😏${RESET} ${MAGENTA} 👉  https://bit.ly/4eBbfIr  👈 ${MAGENTA}"
    echo -e ""
    echo -e "${CYAN}Полезные команды:${RESET}"
    echo -e "  - ${YELLOW}Просмотр файлов директории:${RESET} ll"
    echo -e "  - ${YELLOW}Вход в директорию:${RESET} cd hyperlane"
    echo -e "  - ${YELLOW}Выход из директории:${RESET} cd .."
    echo -e "  - ${YELLOW}Запуск меню скрипта (не установка) из директории hyperlane:${RESET} bash hyper.sh"
    echo -e ""
}

# Функция для получения IP-адреса
get_ip_address() {
    ip_address=$(hostname -I | awk '{print $1}')
    if [[ -z "$ip_address" ]]; then
        echo -ne "${YELLOW}Не удалось автоматически определить IP-адрес.${RESET}"
        echo -ne "${YELLOW} Пожалуйста, введите IP-адрес:${RESET} "
        read ip_address
    fi
    echo "$ip_address"
}

# Отображение меню
show_menu() {
    clear
    draw_top_border
    display_ascii
    draw_middle_border
    print_telegram_icon
    echo -e "    ${BLUE}Криптан, подпишись!: ${YELLOW}https://t.me/indivitias${RESET}"
    draw_middle_border

    # Текущая директория и IP-адрес
    current_dir=$(pwd)
    ip_address=$(get_ip_address)
    echo -e "    ${GREEN}Текущая директория:${RESET} ${current_dir}"
    echo -e "    ${GREEN}IP-адрес:${RESET} ${ip_address}"
    draw_middle_border
    echo -e " ${GREEN}Выберите действие:${RESET}"
    echo -e "  ${ICON_INSTALL} ${YELLOW}1) Установить и настроить ноду${RESET}"
    echo -e "  ${ICON_SSH} ${YELLOW}2) Генерация ключа SSH${RESET}"
    echo -e "  ${ICON_START} ${YELLOW}3) Запустить ноду${RESET}"
    echo -e "  ${ICON_RESTART} ${YELLOW}4) Перезапустить ноду${RESET}"
    echo -e "  ${ICON_LOGS} ${YELLOW}5) Просмотр логов${RESET}"
    echo -e "  ${ICON_DELETE} ${YELLOW}6) Удалить ноду${RESET}"
    echo -e "  ${ICON_EXIT} ${YELLOW}7) Выход${RESET}"
    draw_bottom_border
}

# Функция для проверки и установки Git
install_git() {
    if ! [ -x "$(command -v git)" ]; then
        echo "Git не установлен. Устанавливаем Git..."
        sudo apt-get update && sudo apt-get install -y git
    else
        echo "Git уже установлен."
    fi
}

# Функции из оригинального скрипта
install_and_configure_node() {
    echo "Устанавливаем и настраиваем ноду..."
    sudo apt-get update && sudo apt-get install -y \
    curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli \
    pkg-config libssl-dev libgmp3-dev tar clang bsdmainutils ncdu unzip llvm \
    libudev-dev protobuf-compiler cmake cargo openssl
    
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup
    
    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
    source ~/.nvm/nvm.sh
    nvm install --lts
    nvm use --lts
    
    npm --version
    npm install -g @hyperlane-xyz/cli
    hyperlane --version
    
    sudo apt install -y screen
   # Установка rustup, если он еще не установлен
    if ! command -v rustup &> /dev/null; then
        echo "rustup не найден. Устанавливаем rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
    fi

    echo "Обновляем Rust до последней версии..."
    rustup update stable

    echo "Настраиваем конфигурацию Hyperlane..."
    hyperlane core init --advanced | tee /tmp/hyperlane_core_init.log

    echo "Ожидание завершения настройки... Пожалуйста, введите все необходимые данные."
    
    while true; do
        if grep -q "✅ Successfully created new core deployment config." /tmp/hyperlane_core_init.log; then
            echo "Конфигурация завершена, продолжаем..."
            break
        fi
        sleep 5
    done

    echo "Выполняем hyperlane core deploy..."
    hyperlane core deploy | tee /tmp/hyperlane_core_deploy.log

    echo "Ожидание завершения развертывания..."
    
    while true; do
        if grep -q "✅ Core contract deployments complete:" /tmp/hyperlane_core_deploy.log; then
            echo "Развертывание завершено, продолжаем..."
            break
        fi
        sleep 5
    done

    echo "Настраиваем агента Hyperlane..."
    hyperlane registry agent-config --chains base

    export CONFIG_FILES=$HOME/configs/agent-config.json
    mkdir -p /tmp/hyperlane-validator-signatures-base
    export VALIDATOR_SIGNATURES_DIR=/tmp/hyperlane-validator-signatures-base
    mkdir -p $VALIDATOR_SIGNATURES_DIR

    echo "Настройка ноды завершена."
}

generate_ssh_key() {
    echo "Генерация SSH ключа..."
    ssh-keygen -t rsa -b 4096 -C Hyperlane
    cat ~/.ssh/id_rsa.pub
}

start_node() {
    if [ ! -f "$HOME/.private_key" ]; then
        read -p "Введите ваш приватный ключ EVM: " private_key

        if [ -z "$private_key" ]; then
            echo "Ошибка: Приватный ключ не может быть пустым. Возвращение в главное меню."
            return
        fi

        echo "$private_key" > $HOME/.private_key
    else
        private_key=$(cat $HOME/.private_key)
    fi

    echo "Запускаем ноду..."
    git clone git@github.com:hyperlane-xyz/hyperlane-monorepo.git
    sleep 20
    screen -d -m -S hyperlane bash -c "cd hyperlane-monorepo/rust/main && cargo run --release --bin validator -- \
        --db ./hyperlane_db_validator_base \
        --originChainName base \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path $VALIDATOR_SIGNATURES_DIR \
        --validator.key 0x${private_key}"
    
    echo "Нода запущена. Чтобы присоединиться к сеансу, используйте команду: screen -r hyperlane"
}

restart_node() {
    echo "Перезапускаем ноду..."
    screen -S hyperlane -p 0 -X quit
    start_node
}

view_logs() {
    echo "Просмотр логов ноды..."
    screen -r hyperlane
}

remove_node() {
    echo "Удаление ноды..."
    screen -ls | grep ".hyperlane" | awk '{print $1}' | xargs -I{} screen -S {} -X quit
    rm -rf $HOME/hyperlane-monorepo
    rm -rf /tmp/hyperlane-validator-signatures-base
    rm -f $HOME/.private_key
    echo "Нода полностью удалена."
}

# Основной цикл программы
while true; do
    show_menu
    read -p "Введите номер действия: " choice
    case $choice in
        1)
            install_git
            install_and_configure_node
            ;;
        2)
            generate_ssh_key
            ;;
        3)
            start_node
            ;;
        4)
            restart_node
            ;;
        5)
            view_logs
            ;;
        6)
            remove_node
            ;;
        7)
            echo -e "${RED}Выход из программы. Спасибо за использование!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Попробуйте снова.${RESET}"
            ;;
    esac
    read -p "Нажмите Enter, чтобы вернуться в меню..."
done
