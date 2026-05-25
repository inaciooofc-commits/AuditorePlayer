#!/bin/bash
# =====================================================
#   CCPI AUTOMATA v4.3
#   Bot Inteligente de Gerenciamento - CLCoreProgramINC.
#   Data: 24 de Maio de 2026
# =====================================================

BOT_NAME="CCPI Automata"
PROJECT_NAME="AuditorePlayer"
BASE_DIR="/opt/AuditorePlayer"
LOG_FILE="$BASE_DIR/logs/automata.log"
CHECK_INTERVAL=15   # segundos

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 $BOT_NAME iniciado - Modo Inteligente"

# Auto-descoberta do projeto
find_project() {
    if [ ! -d "$BASE_DIR" ]; then
        log "🔍 Projeto não encontrado em $BASE_DIR. Buscando..."
        BASE_DIR=$(find /opt -name "server.js" -type f 2>/dev/null | head -n1 | xargs dirname 2>/dev/null)
        if [ -z "$BASE_DIR" ]; then
            log "❌ Projeto AuditorePlayer não encontrado!"
            exit 1
        fi
        log "✅ Projeto encontrado em: $BASE_DIR"
    fi
    cd "$BASE_DIR" || exit 1
}

# Verifica e corrige erros comuns
smart_repair() {
    log "🔧 Iniciando diagnóstico inteligente..."

    # Verifica se PM2 está rodando
    if ! pm2 list | grep -q "$PROJECT_NAME"; then
        log "⚠️ Servidor não está rodando. Iniciando..."
        pm2 start ecosystem.config.js --name "$PROJECT_NAME" 2>/dev/null || pm2 start server.js --name "$PROJECT_NAME"
    fi

    # Verifica porta 3000 em uso
    if ss -tlnp | grep -q ":3000"; then
        log "🔄 Porta 3000 ocupada. Reiniciando serviço..."
        pm2 restart "$PROJECT_NAME"
    fi

    # Verifica uso excessivo de memória
    MEM_USAGE=$(ps aux | grep node | grep -v grep | awk '{print $4}' | head -n1)
    if (( $(echo "$MEM_USAGE > 85" | bc -l) )); then
        log "🧠 Uso alto de memória ($MEM_USAGE%). Reiniciando..."
        pm2 restart "$PROJECT_NAME"
    fi

    # Verifica logs de erro recentes
    if tail -n 50 "$LOG_FILE" | grep -q "Error\|Failed\|Crash"; then
        log "🚨 Erro detectado nos logs. Executando reparo completo..."
        pm2 restart "$PROJECT_NAME"
        sleep 3
    fi

    log "✅ Diagnóstico concluído - Sistema saudável"
}

# Loop Principal Inteligente
main_loop() {
    while true; do
        find_project
        smart_repair
        
        echo "[$BOT_NAME] $(date '+%H:%M:%S') - Monitorando AuditorePlayer... (Intervalo: ${CHECK_INTERVAL}s)"
        sleep $CHECK_INTERVAL
    done
}

# Menu
show_menu() {
    clear
    echo -e "\033[36m╔══════════════════════════════════════════════════════════════╗\033[0m"
    echo -e "\033[36m║               CCPI AUTOMATA - MODO INTELIGENTE               ║\033[0m"
    echo -e "\033[36m╚══════════════════════════════════════════════════════════════╝\033[0m"
    echo ""
    echo "1) Iniciar Monitoramento Inteligente"
    echo "2) Forçar Reparo Agora"
    echo "3) Ver Status Completo"
    echo "4) Parar Todos Serviços"
    echo "5) Ver Logs do Automata"
    echo "6) Sair"
    read -p "→ Escolha: " choice
}

# Execução
find_project

while true; do
    show_menu
    case $choice in
        1) log "🟢 Monitoramento inteligente ativado"; main_loop ;;
        2) smart_repair ;;
        3) 
            echo "=== STATUS ==="
            pm2 list
            ss -tlnp | grep -E "node|cloudflared"
            ;;
        4) 
            pm2 stop all
            log "🛑 Todos serviços parados"
            ;;
        5) tail -n 100 "$LOG_FILE" ;;
        6) log "👋 $BOT_NAME encerrado"; exit 0 ;;
        *) echo "Opção inválida!" ;;
    esac
done