#!/usr/bin/env bash
set -eu

fastlane snapshot
cp fastlane/screenshots/en-US/iPhone\ 11\ Pro\ Max-01Receptive.png media/screenshot.png
