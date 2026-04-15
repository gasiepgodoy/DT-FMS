MESLab4_0
=========

### Startup Infrastructure

Run : docker compose up -d        

### Update Database Initialization

docker rm -f production-db

docker volume rm mes_mysql_data

docker compose up -d db



docker exec -it production-nodered bash -c "cd /data && npm install node-red-contrib-aedes@0.13.0"

docker restart production-nodered   
