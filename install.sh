#!/bin/bash
# =====================================================
#   AUDITOREPLAYER - INSTALADOR DEFINITIVO
#   CLCoreProgramINC. / CCPI
#   Data: 24 de Maio de 2026
# =====================================================

clear
echo -e "\033[36m╔══════════════════════════════════════════════════════════════╗\033[0m"
echo -e "\033[36m║           AUDITOREPLAYER v4.3 - INSTALAÇÃO DEFINITIVA        ║\033[0m"
echo -e "\033[36m║                    CCPI Automata                             ║\033[0m"
echo -e "\033[36m╚══════════════════════════════════════════════════════════════╝\033[0m"

PROJECT_DIR="/opt/AuditorePlayer"
sudo mkdir -p $PROJECT_DIR/{public,data,logs,backup}
cd $PROJECT_DIR

echo "[1/5] Instalando dependências..."
sudo apt-get update -qq && sudo apt-get install -y curl wget git ffmpeg yt-dlp ufw lsof

if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash -
    sudo apt-get install -y nodejs
fi

sudo npm install -g pm2 --silent

if ! command -v cloudflared &> /dev/null; then
    wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
    sudo dpkg -i cloudflared-linux-amd64.deb || sudo apt-get install -f -y
fi

echo "[2/5] Criando arquivos principais..."

# config.json
cat > config.json << 'EOF'
{
  "adminUser": "admin",
  "adminPass": "123456",
  "port": 3000,
  "creditPerPlay": 5,
  "creditPerDownload": 15
}
EOF

# server.js
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

app.get('/api/search', (req, res) => {
    const query = req.query.q;
    exec(`yt-dlp "ytsearch10:${query}" --dump-json`, (error, stdout) => {
        if (error) return res.json([]);
        const results = stdout.trim().split('\n').map(l => JSON.parse(l));
        res.json(results);
    });
});

app.get('/api/stream/:videoId', (req, res) => {
    const videoId = req.params.videoId;
    const url = `https://www.youtube.com/watch?v=${videoId}`;
    res.set('Content-Type', 'audio/mpeg');
    exec(`yt-dlp -f bestaudio --output - "${url}"`, {maxBuffer: 200*1024*1024}, (err, stdout) => {
        if (err) return res.status(500).send("Stream error");
        res.send(stdout);
    });
});

app.get('/api/download/:videoId/:title', (req, res) => {
    const { videoId, title } = req.params;
    const safeTitle = title.replace(/[^a-zA-Z0-9]/g, '_');
    res.set('Content-Disposition', `attachment; filename="${safeTitle}.mp3"`);
    const url = `https://www.youtube.com/watch?v=${videoId}`;
    exec(`yt-dlp -f bestaudio --extract-audio --audio-format mp3 -o - "${url}"`, {maxBuffer: 500*1024*1024}, (err, stdout) => {
        if (err) return res.status(500).send("Download error");
        res.send(stdout);
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 AuditorePlayer rodando na porta ${PORT}`);
});
EOF

# ecosystem.config.js
cat > ecosystem.config.js << 'EOF'
module.exports = {
  apps: [{
    name: 'AuditorePlayer',
    script: 'server.js',
    watch: false,
    max_restarts: 15,
    restart_delay: 4000,
    env: { NODE_ENV: 'production' }
  }]
};
EOF

echo "[3/5] Criando CCPI Automata (Bot Inteligente)..."
cat > ccpi-automata.sh << 'AUTOMATA'
#!/bin/bash
# CCPI AUTOMATA - Bot Inteligente
BOT_NAME="CCPI Automata"
BASE_DIR="/opt/AuditorePlayer"
LOG_FILE="$BASE_DIR/logs/automata.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

smart_repair() {
    if ! pm2 list | grep -q "AuditorePlayer"; then
        log "⚠️ Servidor caído. Reiniciando..."
        pm2 start ecosystem.config.js --name AuditorePlayer
    fi
    if (( $(ps aux | grep node | grep -v grep | wc -l) == 0 )); then
        log "🔄 Reiniciando serviço completo..."
        pm2 restart AuditorePlayer
    fi
}

while true; do
    cd $BASE_DIR
    smart_repair
    sleep 20
done
AUTOMATA

chmod +x ccpi-automata.sh

echo "[5/5] Instalação Concluída!"
echo "🔑 Admin: admin / 123456"
echo "🤖 Para iniciar o Bot Inteligente:"
echo "   cd /opt/AuditorePlayer && bash ccpi-automata.sh"