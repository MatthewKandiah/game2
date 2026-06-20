#!/usr/bin/env bash

set -eu

./build.sh
echo "Running main..."
./build/main.bin

