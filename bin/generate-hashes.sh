#!/bin/bash

set -xe

for d in out/*/ ; do
  bin/make-bundle.sh "$d" > "$d"/bundle.json || rm "$d"/bundle.json
done

find out/ -name 'bundle.json' -exec sha256sum {} +
