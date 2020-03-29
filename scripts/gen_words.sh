#!/usr/bin/env bash
set -eu

python scripts/gen_words.py

git add .
git commit -m "chore: regenerate words list"

echo "Done."
