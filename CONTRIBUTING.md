# Contributing

> [!IMPORTANT]
> Tests must be added for all new functionality. Existing tests must be updated for all changed/fixed functionality, where applicable. All tests must complete without errors. All new functionality must be documented as well.

## Prerequisites

We use [Carthage](https://github.com/Carthage/Carthage) to manage Auth0.swift's dependencies. You can install it using Homebrew:

```bash
brew install carthage
```

You will also need simulators for the following platorms:
- iOS
- tvOS
- watchOS
- visionOS

See [Adding additional simulators](https://developer.apple.com/documentation/safari-developer-tools/adding-additional-simulators) for more information on how to add any missing simulators.

## Set up the development environment

1. Clone this repository and enter its root directory.
2. Run `carthage bootstrap --use-xcframeworks` to fetch and build the dependencies.
3. Open `Auth0.xcodeproj` in Xcode.
