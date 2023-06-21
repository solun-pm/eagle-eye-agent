#!/bin/bash

# Setze die URL für das Daemon-Skript
SCRIPT_URL="https://github.com/solun-pm/eagle-eye-agent/raw/main/eagle-eye.sh"

# Frage nach der URL des API-Servers
echo "Please enter the API server URL(https://your.domain.com:port):"
read API_URL

# Speichere die API-URL in einer Konfigurationsdatei
echo $API_URL > /bin/eagle-eye-agent/api_url.conf

# Prüfen, ob das System auf Debian oder Red Hat basiert
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
fi

# Installiere die notwendigen Tools je nach Betriebssystem
case $OS in
    "Ubuntu"|"Debian GNU/Linux")
        if ! command -v curl &> /dev/null; then
            echo "curl could not be found. Installing now..."
            sudo apt-get install curl -y
        fi
        if ! command -v jq &> /dev/null; then
            echo "jq could not be found. Installing now..."
            sudo apt-get install jq -y
        fi
        ;;

    "CentOS Linux"|"Fedora"|"Red Hat Enterprise Linux")
        if ! command -v curl &> /dev/null; then
            echo "curl could not be found. Installing now..."
            sudo yum install curl -y
        fi
        if ! command -v jq &> /dev/null; then
            echo "jq could not be found. Installing now..."
            sudo yum install jq -y
        fi
        ;;
esac

# Lade das Daemon-Skript herunter und kopiere es an den gewünschten Speicherort
sudo curl -o /bin/eagle-eye-agent/eagle-eye.sh $SCRIPT_URL
sudo chmod +x /bin/eagle-eye-agent/eagle-eye.sh

# Erstelle die systemd service Datei
cat <<EOF | sudo tee /etc/systemd/system/eagle-eye-agent.service
[Unit]
Description=Eagle Eye Agent
After=network.target

[Service]
ExecStart=/bin/eagle-eye-agent/eagle-eye.sh
Restart=on-failure
User=root
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# Starte und aktiviere den systemd Dienst
sudo systemctl daemon-reload
sudo systemctl start eagle-eye-agent
sudo systemctl enable eagle-eye-agent

echo "Installation is complete. The Eagle Eye Agent is now running as a systemd service."

# Lösche das Installations-Skript
rm -- "$0"

