#!/bin/bash

echo "Checking internet connection..."
curl -sSf tx.fhir.org > /dev/null

if [ $? -eq 0 ]; then
    echo "Online"
    txoption=""
else
    echo "Offline"
    txoption="-tx n/a"
fi

echo "$txoption"

# Run IG Publisher using Docker
docker run --rm \
  -v "$(pwd)":/tmp/ig \
  ghcr.io/trifork/ig-publisher:latest \
  -ig /tmp/ig $txoption "$@"
