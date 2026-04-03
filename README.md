MESLab4_0
=========

### Startup Infrastructure

Run : docker compose up -d        

### Update Database Initialization

docker rm -f production-db

docker volume rm mes_mysql_data

docker compose up -d db