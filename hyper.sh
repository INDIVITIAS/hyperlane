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
    read -p "Введите адрес вашего EVM кошелька: " owner_address
    echo $owner_address
    echo "Выбираем messageIdMultisigIsm"
    echo $owner_address
    echo "Введите адреса валидаторов (через запятую): " $owner_address
    echo "1"
    echo "Выбираем merkleTreeHook"
    echo "Выбираем aggregationHook"
    echo "Введите адрес владельца для hook: " $owner_address
    echo "YES"
    echo "Введите максимальный протокольный сбор: 100000000000000000000"
    echo "Введите протокольный сбор: 0.1"
    echo "Введите адрес владельца ProxyAdmin: " $owner_address
    echo "hyperlane core deploy"
    read -p "Введите ваш приватный ключ EVM: " HYP_Key
    echo "0x${HYP_Key}"
    echo "Выбираем сеть (mainnet/testnet): " 
    read -p "Выберите сеть для подключения: " network
    echo $network
    echo "NO"
    echo "YES"
    echo "YES"
    echo "hyperlane registry agent-config --chains base"
    export CONFIG_FILES=$HOME/configs/agent-config.json
    mkdir -p /tmp/hyperlane-validator-signatures-base
    export VALIDATOR_SIGNATURES_DIR=/tmp/hyperlane-validator-signatures-base
    mkdir -p $VALIDATOR_SIGNATURES_DIR

    # Генерация SSH ключа и настройка GitHub
    echo "Генерация SSH ключа..."
    ssh-keygen -t rsa -b 4096 -C Hyperlane
    cat ~/.ssh/id_rsa.pub

    echo "Скопируйте ключ и добавьте его в GitHub -> Settings -> SSH and GPG keys -> New SSH key"

    # Клонирование репозитория Hyperlane
    echo "Клонирование репозитория Hyperlane..."
    git clone git@github.com:hyperlane-xyz/hyperlane-monorepo.git
    cd hyperlane-monorepo
    cd rust
    cd main

    # Запуск ноды
    echo "Запуск ноды..."
    screen -S hyperlane -d -m cargo run --release --bin validator -- \
        --db ./hyperlane_db_validator_base\
        --originChainName base\
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path $VALIDATOR_SIGNATURES_DIR \
        --validator.key "0x${HYP_Key}"

    echo "Установка завершена. Нода запущена и работает."
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
options=("Установить и запустить ноду" "Просмотр логов" "Удалить ноду" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Установить и запустить ноду")
            install_git
            install_and_run_node
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
