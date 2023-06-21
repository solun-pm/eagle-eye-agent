#!/bin/bash

# Setze die URL für das Daemon-Skript
SCRIPT_URL="https://github.com/solun-pm/eagle-eye-agent/raw/main/eagle-eye.sh"
# Setze die URL für das Uninstall-Skript
UNINSTALL_SCRIPT_URL="https://github.com/solun-pm/eagle-eye-agent/raw/main/uninstall.sh"

# Frage nach der URL des API-Servers
echo "Please enter the API server URL(https://your.domain.com:port):"
read API_URL

# Speichere die API-URL in einer Konfigurationsdatei
sudo mkdir -p /bin/eagle-eye-agent
echo $API_URL | sudo tee /bin/eagle-eye-agent/api_url.conf > /dev/null

# Prüfen, ob das System auf Debian, Red Hat oder Pacman basiert
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
fi

# Installiere die notwendigen Tools je nach Betriebssystem
case $OS in
    "Ubuntu"|"Debian")
        if ! command -v curl &> /dev/null; then
            echo "curl could not be found. Installing now..."
            sudo apt-get install curl -y
        fi
        if ! command -v jq &> /dev/null; then
            echo "jq could not be found. Installing now..."
            sudo apt-get install jq -y
        fi
        ;;
    "CentOS"|"Fedora"|"Red Hat Enterprise Linux")
        if ! command -v curl &> /dev/null; then
            echo "curl could not be found. Installing now..."
            sudo yum install curl -y
        fi
        if ! command -v jq &> /dev/null; then
            echo "jq could not be found. Installing now..."
            sudo yum install jq -y
        fi
        ;;
    "Arch Linux"|"Manjaro Linux")
        if ! command -v curl &> /dev/null; then
            echo "curl could not be found. Installing now..."
            sudo pacman -Sy curl --noconfirm
        fi
        if ! command -v jq &> /dev/null; then
            echo "jq could not be found. Installing now..."
            sudo pacman -Sy jq --noconfirm
        fi
        ;;
    *)
        echo "Unsupported operating system."
        exit 1
        ;;
esac

# Erstelle das Verzeichnis, falls es noch nicht vorhanden ist
sudo mkdir -p /bin/eagle-eye-agent

# Lade das Daemon-Skript herunter und kopiere es an den gewünschten Speicherort
sudo curl -o /bin/eagle-eye-agent/eagle-eye.sh $SCRIPT_URL
sudo chmod +x /bin/eagle-eye-agent/eagle-eye.sh

# Lade das Uninstall-Skript herunter
sudo curl -o /bin/eagle-eye-agent/uninstall.sh $UNINSTALL_SCRIPT_URL
sudo chmod +x /bin/eagle-eye-agent/uninstall.sh

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
