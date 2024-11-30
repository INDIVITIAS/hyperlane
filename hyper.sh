#!/bin/bash

# Определение цветов
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

# Иконки для меню
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

# Вывод ASCII-логотипа
display_ascii() {
    echo -e "${CYAN}   ____   _  __   ___    ____ _   __   ____ ______   ____   ___    ____${RESET}"
    echo -e "${CYAN}  /  _/  / |/ /  / _ \\  /  _/| | / /  /  _//_  __/  /  _/  / _ |  / __/${RESET}"
    echo -e "${CYAN} _/ /   /    /  / // / _/ /  | |/ /  _/ /   / /    _/ /   / __ | _\\ \\  ${RESET}"
    echo -e "${CYAN}/___/  /_/|_/  /____/ /___/  |___/  /___/  /_/    /___/  /_/ |_|/___/  ${RESET}"
    echo -e ""
    echo -e "${YELLOW}Подписывайтесь на Telegram: https://t.me/CryptalikBTC${RESET}"
    echo -e "${YELLOW}Подписывайтесь на YouTube: https://www.youtube.com/@Cryptalik${RESET}"
    echo -e "${YELLOW}Здесь про аирдропы и ноды: https://t.me/indivitias${RESET}"
    echo -e ""
}

# Установить Git
install_git() {
    if ! [ -x "$(command -v git)" ]; then
        echo -e "${RED}Git не установлен. Устанавливаем Git...${RESET}"
        sudo apt-get update && sudo apt-get install -y git
    else
        echo -e "${GREEN}Git уже установлен.${RESET}"
    fi
}

# Установка и настройка ноды
install_and_configure_node() {
    echo -e "${CYAN}Устанавливаем и настраиваем ноду...${RESET}"
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

    echo -e "${CYAN}Настраиваем конфигурацию Hyperlane...${RESET}"
    hyperlane core init --advanced | tee /tmp/hyperlane_core_init.log

    echo -e "${YELLOW}Ожидание завершения настройки... Пожалуйста, введите все необходимые данные.${RESET}"

    while true; do
        if grep -q "✅ Successfully created new core deployment config." /tmp/hyperlane_core_init.log; then
            echo -e "${GREEN}Конфигурация завершена, продолжаем...${RESET}"
            break
        fi
        sleep 5
    done

    echo -e "${CYAN}Выполняем hyperlane core deploy...${RESET}"
    hyperlane core deploy | tee /tmp/hyperlane_core_deploy.log

    echo -e "${YELLOW}Ожидание завершения развертывания...${RESET}"

    while true; do
        if grep -q "✅ Core contract deployments complete:" /tmp/hyperlane_core_deploy.log; then
            echo -e "${GREEN}Развертывание завершено, продолжаем...${RESET}"
            break
        fi
        sleep 5
    done

    echo -e "${CYAN}Настраиваем агента Hyperlane...${RESET}"
    hyperlane registry agent-config --chains base

    export CONFIG_FILES=$HOME/configs/agent-config.json
    mkdir -p /tmp/hyperlane-validator-signatures-base
    export VALIDATOR_SIGNATURES_DIR=/tmp/hyperlane-validator-signatures-base
    mkdir -p $VALIDATOR_SIGNATURES_DIR

    echo -e "${GREEN}Настройка ноды завершена.${RESET}"
}

# Генерация SSH ключа
generate_ssh_key() {
    echo -e "${CYAN}Генерация SSH ключа...${RESET}"
    ssh-keygen -t rsa -b 4096 -C Hyperlane
    cat ~/.ssh/id_rsa.pub
}

# Запуск ноды
start_node() {
    if [ ! -f "$HOME/.private_key" ]; then
        read -p "Введите ваш приватный ключ EVM: " private_key

        if [ -z "$private_key" ]; then
            echo -e "${RED}Ошибка: Приватный ключ не может быть пустым. Возвращение в главное меню.${RESET}"
            return
        fi

        echo "$private_key" > $HOME/.private_key
    else
        private_key=$(cat $HOME/.private_key)
    fi

    echo -e "${CYAN}Запускаем ноду...${RESET}"
    git clone git@github.com:hyperlane-xyz/hyperlane-monorepo.git
    screen -S hyperlane
    cd hyperlane-monorepo
    cd rust
    cd main
    cargo run --release --bin validator -- \
        --db ./hyperlane_db_validator_base \
        --originChainName base \
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path $VALIDATOR_SIGNATURES_DIR \
        --validator.key "0x${private_key}"
}

# Перезапуск ноды
restart_node() {
    echo -e "${CYAN}Перезапускаем ноду...${RESET}"
    screen -S hyperlane -p 0 -X quit
    start_node
}

# Просмотр логов
view_logs() {
    echo -e "${CYAN}Просмотр логов ноды...${RESET}"
    screen -r hyperlane
}

# Удаление ноды
remove_node() {
    echo -e "${CYAN}Удаление ноды...${RESET}"
    screen -ls | grep ".hyperlane" | awk '{print $1}' | xargs -I{} screen -S {} -X quit
    rm -rf $HOME/hyperlane-monorepo
    rm -rf /tmp/hyperlane-validator-signatures-base
    rm -f $HOME/.private_key
    echo -e "${GREEN}Нода полностью удалена.${RESET}"
}

# Отображение меню
show_menu() {
    clear
    draw_top_border
    display_ascii
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

# Основное меню
PS3="Выберите действие: "
while true; do
    show_menu
    options=("Установить и настроить ноду" "Генерация ключа SSH" "Запустить ноду" "Перезапустить ноду" "Просмотр логов" "Удалить ноду" "Выход")
    select opt in "${options[@]}"
    do
        case $opt in
            "Установить и настроить ноду")
                install_git
                install_and_configure_node
                break
                ;;
            "Генерация ключа SSH")
                generate_ssh_key
                break
                ;;
            "Запустить ноду")
                start_node
                break
                ;;
            "Перезапустить ноду")
                restart_node
                break
                ;;
            "Просмотр логов")
                view_logs
                break
                ;;
            "Удалить ноду")
                remove_node
                break
                ;;
            "Выход")
                echo -e "${RED}Выход из программы. Спасибо за использование!${RESET}"
                exit 0
                ;;
            *) echo -e "${RED}Неверный выбор. Попробуйте снова.${RESET}" ;;
        esac
    done
done
