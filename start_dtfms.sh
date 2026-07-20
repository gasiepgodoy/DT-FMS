#!/bin/bash
echo Demarrage DT-FMS...
cd ~/Desktop/scolarité/4A/DT-FMS/NodeRed-MES
docker compose up -d
docker start basyx-server 2>/dev/null || docker run -d -p 8081:8081 --name basyx-server eclipsebasyx/aas-environment:2.0.0-milestone-03
echo Attente BaSyx...
until curl -s http://localhost:8081/shells > /dev/null 2>&1; do sleep 2; done
echo BaSyx pret !
/opt/homebrew/bin/python3.11 ~/Desktop/scolarité/4A/DT-FMS/load_polimi_aas_basyx.py
echo Stack prete ! MES: http://localhost:1880/ui BaSyx: http://localhost:8081/shells
echo Lance dans un autre terminal: node-red -u ~/Desktop/scolarité/4A/DT-FMS/NodeRed-MES
