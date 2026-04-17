# To start up the database

docker network create influx-net

docker run --detach \
  --name influxdb3-explorer \
  --network influx-net \
  --publish 8888:80 \
  influxdata/influxdb3-ui:1.6.2

docker run --detach \
  --name influxdb3-core \
  --network influx-net \
  --publish 8181:8181 \
  --volume influxdb3-data:/var/lib/influxdb3 \
  influxdb:3-core influxdb3 serve \
  --node-id mon_serveur_local \
  --object-store file \
  --data-dir /var/lib/influxdb3

docker exec -it influxdb3-core influxdb3 create token --admin
 

Please note the token

http://localhost:8888/ and then add http://host.docker.internal:8181


docker exec -it influxdb3-core influxdb3 create database test --token apiv3_g9y2pYnssUrxxc5Ung8N4664dqqQ_jMzcyI1dm1uO09NljcgAkuE14S1frblIgI5QgYx0b03AYrGjBr0BCPCPw
