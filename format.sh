#!/usr/bin/env bash

find . -name '*.odin' -exec odinfmt -w {} \;
