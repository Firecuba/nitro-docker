#!/bin/bash
set -e
DEST=/home/firecuba/habbo/nitro-docker/tls
cp /etc/letsencrypt/live/atom.firecuba.com/fullchain.pem "$DEST/cert.pem"
cp /etc/letsencrypt/live/atom.firecuba.com/privkey.pem "$DEST/privkey.pem"
chown firecuba:firecuba "$DEST/cert.pem" "$DEST/privkey.pem"
chmod 644 "$DEST/cert.pem"
chmod 600 "$DEST/privkey.pem"
cd /home/firecuba/habbo/nitro-docker
docker compose restart arcturus tls-proxy
