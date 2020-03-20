#!/usr/bin/env bash
set -eu

destination=${1:-"platform=iOS Simulator,OS=13.3,name=iPhone 11"}
xcodebuild clean test -project Fingerspelling.xcodeproj -scheme FingerspellingUITests -destination "$destination"
