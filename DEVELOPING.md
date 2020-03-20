# Developing

## Running tests

From the command line:

```
./scripts/tests.sh
```

Or press Cmd+U in Xcode.

## Adding pre-commit hooks

Ensure pre-commit is installed:

```
brew install pre-commit
```

Install the hooks:

```
pre-commit install
```

To manually run formatters on all files:

```
pre-commit run --all-files
```

## Generating screenshots

Install fastlane:

```
brew install fastlane
```

Run the screenshots:

```
fastlane screenshots
```

## Bumping version

Bump build number:

```
xcrun agvtool next-version -all
```

Bump marketing version:

```
xcrun agvtool new-marketing-version YYYY.X
```

## Releasing

1. In Xcode, choose the "Fingerspelling" scheme and "Generic iOS Device" as the device.
1. Click Product > Archive and wait for the build to finish (this takes a while).
1. Click "Distribute app". Hit Next through the following Menus.
1. Add a new version on App Store Connect then submit the new version.
