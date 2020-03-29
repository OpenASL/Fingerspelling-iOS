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

## Regenerating words list

```
./scripts/gen_words.sh
```

## Bumping version and build number

Replace `X` with release number.

```
./scripts/bump.sh 2020.X
```

## Releasing

1. Bump version: `./scripts/bump.sh 2020.X`.
1. Push: `git push --tags origin master`
1. In Xcode, choose the "Fingerspelling" scheme and "Generic iOS Device" as the device.
1. Click Product > Archive and wait for the build to finish (this takes a while).
1. Click "Distribute app". Hit Next through the following Menus.
1. Add a new version on App Store Connect. If necessary, regenerate snapshots (see above) and upload them.
1. Submit the new version.
