#!bin/bash
docker-compose -f ./docker/cloudflare/docker-compose.yml up -d
docker-compose -f ./docker/duplicati/docker-compose.yml up -d
docker-compose -f ./docker/filebrowser/docker-compose.yml up -d
docker-compose -f ./docker/heimdall/docker-compose.yml up -d
docker-compose -f ./docker/monitoring/docker-compose.yml up -d

