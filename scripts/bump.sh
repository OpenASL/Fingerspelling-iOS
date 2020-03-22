#!/usr/bin/env bash
set -eu

marketing_version=$1

xcrun agvtool next-version -all
xcrun agvtool new-marketing-version $marketing_version

build=$(xcrun agvtool vers -terse)

git add .
git commit -m "chore: bump version and build number"
git tag "$marketing_version-$build"

echo "Done."
