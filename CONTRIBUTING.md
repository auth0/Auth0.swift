# Contributing

> **Note**
> Tests must be added for all new functionality. Existing tests must be updated for all changed/fixed functionality, where applicable. All tests must complete without errors. All new functionality must be documented as well.

## Environment setup

We use [Carthage](https://github.com/Carthage/Carthage) to manage Auth0.swift's dependencies. 

1. Clone this repository and enter its root directory.
2. Run `carthage bootstrap --use-xcframeworks` to fetch and build the dependencies.
3. Open `Auth0.xcodeproj` in Xcode.
4. To build a framework target for the first time, build the respective test app first. This is necessary due to the way the dependencies are set up.
