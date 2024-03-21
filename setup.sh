#!bin/bash
docker-compose -f ./cloudflare/docker-compose.yml up -d
docker-compose -f ./duplicati/docker-compose.yml up -d
docker-compose -f ./filebrowser/docker-compose.yml up -d
docker-compose -f ./heimdall/docker-compose.yml up -d
docker-compose -f ./monitoring/docker-compose.yml up -d

