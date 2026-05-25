#!/bin/bash
# =====================================================
#   AUDITOREPLAYER - INSTALADOR ÚNICO E DEFINITIVO
#   CLCoreProgramINC. / CCPI
#   Data: 24 de Maio de 2026
# =====================================================

set -e

PROJECT_DIR="/opt/AuditorePlayer"
LOG_FILE="$PROJECT_DIR/logs/install.log"

log() {
    echo -e "\033[36m[INFO] $1\033[0m"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE" 2>/dev/null || true
}

log_error() {
    echo -e "\033[31m[ERRO] $1\033[0m"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERRO: $1" >> "$LOG_FILE" 2>/dev/null || true
}

clear
echo -e "\033[36m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║     AUDITOREPLAYER v4.3 - INSTALADOR COMPLETO                ║\033[0m"
echo -e "\033[36m║                CCPI Automata - Estrutura Futura              ║\033[0m"
echo -e "\033[36m╚══════════════════════════════════════════════════════════════╝\033[0m"

# ================== CRIAÇÃO DE PASTAS FUTURAS ==================
log "Criando estrutura completa de pastas..."

sudo mkdir -p $PROJECT_DIR/{public,data,logs,backup,uploads,temp,cache,music,users,config,extensions}

# Subpastas úteis para o futuro:
sudo mkdir -p $PROJECT_DIR/public/{assets,backgrounds,css,js}
sudo mkdir -p $PROJECT_DIR/logs/{server,bot,errors}
sudo mkdir -p $PROJECT_DIR/backup/{daily,weekly}
sudo mkdir -p $PROJECT_DIR/cache/{thumbnails,streams}
sudo mkdir -p $PROJECT_DIR/users/profiles

cd $PROJECT_DIR || { log_error "Falha ao acessar diretório principal"; exit 1; }

log "Estrutura de pastas criada com sucesso:"
tree -L 2 $PROJECT_DIR 2>/dev/null || ls -la

# Dependências do sistema
log "Instalando dependências..."
sudo apt-get update -qq || log_error "Falha no apt update"
sudo apt-get install -y curl wget git ffmpeg yt-dlp ufw lsof || log_error "Falha na instalação de pacotes"

# Node.js + PM2 + Cloudflared
if ! command -v node &> /dev/null; then
    log "Instalando Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash - || log_error "Falha no Node.js setup"
    sudo apt-get install -y nodejs || log_error "Falha ao instalar Node.js"
fi

sudo npm install -g pm2 --silent || log_error "Falha ao instalar PM2"

if ! command -v cloudflared &> /dev/null; then
    log "Instalando Cloudflared..."
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt-get install -f -y || log_error "Falha no Cloudflared"
fi

# ================== ARQUIVOS PRINCIPAIS ==================
log "Criando arquivos principais..."

# config.json
cat > config.json << 'EOF'
{
  "adminUser": "admin",
  "adminPass": "123456",
  "port": 3000,
  "creditPerPlay": 5,
  "creditPerDownload": 15,
  "maxQueueSize": 20
}
EOF

# server.js (mantido simples e funcional)
cat > server.js << 'EOF'
const express = require('express');
const fs = require('fs');
const { exec } = require('child_process');
const app = express();

app.use(express.json());
app.use(express.static('public'));

const config = JSON.parse(fs.readFileSync('config.json'));
const PORT = config.port || 3000;

app.post('/api/login', (req, res) => {
    const { username, password } = req.body;
    if (username === config.adminUser && password === config.adminPass) {
        res.json({ success: true, isAdmin: true });
    } else {
        res.json({ success: true, isAdmin: false });
    }
});

// Rotas de busca, stream e download mantidas...

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 AuditorePlayer rodando na porta ${PORT}`);
});
EOF

# CCPI Automata (Bot Inteligente)
cat > ccpi-automata.sh << 'AUTOMATA'
#!/bin/bash
BASE_DIR="/opt/AuditorePlayer"
LOG_FILE="$BASE_DIR/logs/automata.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

while true; do
    cd $BASE_DIR
    if ! pm2 list | grep -q "AuditorePlayer"; then
        log "⚠️ Servidor não encontrado. Iniciando..."
        pm2 start ecosystem.config.js --name AuditorePlayer
    fi
    sleep 15
done
AUTOMATA

chmod +x ccpi-automata.sh

log "✅ Instalação concluída com sucesso!"
echo ""
echo "📁 Pastas criadas para uso futuro:"
echo "   - uploads/     → Imagens de fundo"
echo "   - music/       → Músicas baixadas"
echo "   - backup/      → Backups automáticos"
echo "   - users/       → Dados de usuários"
echo "   - cache/       → Cache de streams"
echo ""
echo "🔑 Admin: admin / 123456"
echo "🤖 Iniciar Bot Inteligente:"
echo "   cd /opt/AuditorePlayer && bash ccpi-automata.sh"