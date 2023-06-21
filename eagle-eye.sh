#!/bin/bash

# Lese die API-URL aus der Konfigurationsdatei
API_URL=$(cat /bin/eagle-eye-agent/api_url.conf)

# Initialisiere die Variable für den letzten Handcheck
last_handcheck=0

while true
do
    # Daten sammeln
    memory=$(free -m | awk 'NR==2{printf "%.2f", $3*100/$2 }')
    cpu=$(top -bn1 | grep load | awk '{printf "%.2f", $(NF-2)}')
    uptime=$(uptime -p)
    net_log=$(ifconfig | grep "RX packets" | awk '{print $3 " " $4}')
    hostname=$(hostname)

    # Daten an den API-Server senden
    response=$(curl -s -X POST $API_URL -d "memory=$memory&cpu=$cpu&uptime=$uptime&net_log=$net_log&hostname=$hostname")
    
    # Heartbeat aus der Antwort extrahieren und speichern
    heartbeat=$(echo $response | jq -r '.heartbeat')
    last_handcheck=$(date +%s)

    # Überprüfe, ob der Heartbeat abgelaufen ist
    now=$(date +%s)
    difference=$(($now - $last_handcheck))

    if (( $difference > 30 ))
    then
        curl -s -X POST $API_URL -d "message=Heartbeat is older than 30 seconds"
    fi

    if (( $difference > 60 ))
    then
        sudo service networking restart
    fi

    if (( $difference > 90 ))
    then
        sudo reboot
    fi

    if (( $difference > 120 ))
    then
        curl -s -X POST $API_URL -d "message=Heartbeat is older than 120 seconds"
    fi

    # Warte 10 Sekunden bevor die nächste Iteration beginnt
    sleep 10
done

