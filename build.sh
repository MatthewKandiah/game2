#!/usr/bin/env bash

set -eu

rm -rf ./build
mkdir ./build

echo "Compiling shaders..."
glslc -o build/vert.spv shaders/main.vert -g
glslc -o build/sprite-frag.spv shaders/sprite.frag -g
glslc -o build/mask-frag.spv shaders/mask.frag -g

echo "Building main..."
# -o:speed / -o:minimal
odin build main -out:build/main.bin -debug -o:minimal

