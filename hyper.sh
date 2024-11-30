#!/bin/bash

# Функция для проверки и установки Git
install_git() {
    if ! [ -x "$(command -v git)" ]; then
        echo "Git не установлен. Устанавливаем Git..."
        sudo apt-get update && sudo apt-get install -y git
    else
        echo "Git уже установлен."
    fi
}

# Функция для установки и запуска ноды
install_and_run_node() {
    # Обновление пакетов и установка необходимых инструментов
    sudo apt-get update && sudo apt-get install -y \
    curl iptables build-essential git wget jq make gcc nano tmux htop nvme-cli \
    pkg-config libssl-dev libgmp3-dev tar clang bsdmainutils ncdu unzip llvm \
    libudev-dev protobuf-compiler cmake cargo openssl

    # Установка Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    source $HOME/.cargo/env

    # Установка Foundry
    curl -L https://foundry.paradigm.xyz | bash
    source ~/.bashrc
    foundryup

    # Установка NVM (Node Version Manager) и Node.js LTS
    curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
    source ~/.nvm/nvm.sh
    nvm install --lts
    nvm use --lts

    # Проверка версии npm и установка Hyperlane CLI
    npm --version
    npm install -g @hyperlane-xyz/cli
    hyperlane --version

    # Установка screen
    sudo apt install -y screen

    # Настройка конфигурации Hyperlane
    echo "Настраиваем конфигурацию Hyperlane..."
    hyperlane core init --advanced

    # Проверка успешного завершения
    if grep -q "✅ Core contract deployments complete:" <<< "$(hyperlane core init --advanced)"; then
        echo "Настройка агента Hyperlane..."
        export CONFIG_FILES=$HOME/configs/agent-config.json
        mkdir -p /tmp/hyperlane-validator-signatures-base
        export VALIDATOR_SIGNATURES_DIR=/tmp/hyperlane-validator-signatures-base
        mkdir -p $VALIDATOR_SIGNATURES_DIR
    fi
}

# Функция для просмотра ключа SSH
view_ssh_key() {
    # Генерация SSH ключа
    echo "Генерация SSH ключа..."
    ssh-keygen -t rsa -b 4096 -C Hyperlane

    # Проверка успешного завершения
    if grep -q "SHA256" <<< "$(ssh-keygen -t rsa -b 4096 -C Hyperlane)"; then
        sleep 5
        cat ~/.ssh/id_rsa.pub
        sleep 120
        git clone git@github.com:hyperlane-xyz/hyperlane-monorepo.git
    fi
}

# Функция для просмотра логов
view_logs() {
    echo "Просмотр логов ноды..."
    screen -r hyperlane
}

# Функция для удаления ноды
remove_node() {
    echo "Удаление ноды..."
    screen -S hyperlane -X quit
    rm -rf $HOME/hyperlane-monorepo
    rm -rf /tmp/hyperlane-validator-signatures-base
    echo "Нода полностью удалена."
}

# Основное меню
PS3="Выберите действие: "
options=("Установить и запустить ноду" "Просмотр ключа SSH" "Просмотр логов" "Удалить ноду" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Установить и запустить ноду")
            install_git
            install_and_run_node
            ;;
        "Просмотр ключа SSH")
            view_ssh_key
            ;;
        "Просмотр логов")
            view_logs
            ;;
        "Удалить ноду")
            remove_node
            ;;
        "Выход")
            break
            ;;
        *) echo "Неверный вариант $REPLY";;
    esac
done
