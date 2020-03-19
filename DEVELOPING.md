# Developing

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
