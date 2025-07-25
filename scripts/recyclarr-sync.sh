#!/bin/bash

cd "$(dirname "$0")/.."

docker compose run --rm recyclarr sync "$@"
