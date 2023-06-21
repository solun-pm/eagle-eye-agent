 #!/bin/bash

# Stoppe den systemd Dienst
sudo systemctl stop eagle-eye-agent
sudo systemctl disable eagle-eye-agent

# Lösche den systemd service
sudo rm /etc/systemd/system/eagle-eye-agent.service

# Lösche das Verzeichnis mit den Agent-Dateien
sudo rm -rf /bin/eagle-eye-agent

# Lösche die API-URL Konfigurationsdatei
sudo rm /bin/eagle-eye-agent/api_url.conf

echo "Uninstallation is complete. The Eagle Eye Agent has been removed."
