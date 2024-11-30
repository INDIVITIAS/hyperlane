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

# Функция для установки и настройки ноды
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
    
    hyperlane core init --advanced | while read line; do
        echo "$line"
        if echo "$line" | grep -q "✅ Successfully created new core deployment config."; then
            echo "Выполняем hyperlane core deploy..."
            hyperlane core deploy
        fi
        if echo "$line" | grep -q "✅ Core contract deployments complete:"; then
            echo "Настраиваем агента Hyperlane..."
            hyperlane registry agent-config --chains base

            export CONFIG_FILES=$HOME/configs/agent-config.json
            mkdir -p /tmp/hyperlane-validator-signatures-base
            export VALIDATOR_SIGNATURES_DIR=/tmp/hyperlane-validator-signatures-base
            mkdir -p $VALIDATOR_SIGNATURES_DIR
        fi
    done
    echo "Настройка ноды завершена."
}

# Функция для генерации SSH ключа
generate_ssh_key() {
    echo "Генерация SSH ключа..."
    ssh-keygen -t rsa -b 4096 -C Hyperlane
    cat ~/.ssh/id_rsa.pub
}

# Функция для запуска ноды
start_node() {
    read -p "Введите ваш приватный ключ EVM: " private_key
    echo "Запускаем ноду..."
    git clone git@github.com:hyperlane-xyz/hyperlane-monorepo.git
    screen -S hyperlane
    cd hyperlane-monorepo
    cd rust
    cd main
    cargo run --release --bin validator -- \
        --db ./hyperlane_db_validator_base\
        --originChainName base\
        --checkpointSyncer.type localStorage \
        --checkpointSyncer.path $VALIDATOR_SIGNATURES_DIR \
        --validator.key "0x${private_key}"
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
options=("Установить и настроить ноду" "Генерация ключа SSH" "Запустить ноду" "Просмотр логов" "Удалить ноду" "Выход")
select opt in "${options[@]}"
do
    case $opt in
        "Установить и настроить ноду")
            install_git
            install_and_configure_node
            ;;
        "Генерация ключа SSH")
            generate_ssh_key
            ;;
        "Запустить ноду")
            start_node
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
