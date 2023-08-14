#!/bin/bash
DATE=$(date '+%Y/%m/%d às %H:%M:%S')
SERVICE_NAME="Apache"
STATUS=""
MESSAGE=""
LOG_DIR="/mnt/efs/kevin"
LOG_INDEX_FILE="$LOG_DIR/log_index.txt"
MAX_LOG_FILES=5

# Verificar se o serviço Apache está ativo
if sudo systemctl is-active --quiet httpd; then
    STATUS="Online"
    MESSAGE="O serviço Apache está ONLINE. \nEndereço IP: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
    FILENAME="online_$(date '+%Y%m%d%H%M%S').txt"
else
    STATUS="Offline"
    MESSAGE="O serviço Apache está offline."
    FILENAME="offline_$(date '+%Y%m%d%H%M%S').txt"
fi

# Criar arquivo de saída com os detalhes da validação
echo -e "Data e Hora: $DATE\nServiço: $SERVICE_NAME\nStatus: $STATUS\nMensagem: $MESSAGE" | sudo tee "$LOG_DIR/$FILENAME" > /dev/null

# Atualizar o arquivo de índice de logs
cd "$LOG_DIR"
#ls -t | head > "$LOG_INDEX_FILE"
echo "$FILENAME" >> "$LOG_INDEX_FILE"

# Manter apenas os últimos 5 arquivos de log
ls -t | tail -n +$((MAX_LOG_FILES + 1)) | xargs -I {} rm {}