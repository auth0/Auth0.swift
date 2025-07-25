# Testing Best Practices & Expectations

## General Principles

- **All new functionality must be covered by tests.**
- **All changed or fixed functionality must have updated tests.**
- **All tests must pass before merging.**
- **All new functionality must be documented.**

## Coding Guidelines

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use `camelCase` for variables and functions
- All functions must be documented with a comment explaining their purpose
- Avoid force-unwrapping (`!`) unless it’s 100% safe
- Only set default value method parameters in Extensions
- Use defaultScope instead of "openid profile email"

## Test Frameworks

- Use [Quick](https://github.com/Quick/Quick) and [Nimble](https://github.com/Quick/Nimble) for BDD-style unit and integration tests.
- Tests should be placed in the `Auth0Tests/` directory, mirroring the structure of the main source code where possible.

## Test Structure

- Use `describe`, `context`, and `it` blocks to organize tests for clarity and maintainability.
- Use `beforeEach` and `afterEach` for setup and teardown.
- Use expressive, behavior-driven test names that describe the expected outcome.

## Stubbing & Mocking

- Use the provided `NetworkStub` and `StubURLProtocol` utilities to stub network requests and responses.
- Avoid making real network calls in tests.
- Use test doubles (mocks, stubs, spies) for dependencies and side effects.

## Test Coverage

- Cover all public APIs, edge cases, and error conditions.
- Test both success and failure scenarios.
- For model objects, test decoding/encoding, required/optional fields, and invalid data.
- Tests should also cover methods that have default paramters 
- Tests should include error outcomes

## Platform Support

- Tests should run on all supported platforms: iOS, tvOS, watchOS, visionOS.
- Add simulators for all platforms as needed.

## Running Tests

- All tests must pass locally and in CI before merging.
- Use `carthage bootstrap --use-xcframeworks` to set up dependencies before running tests.
- Open `Auth0.xcodeproj` in Xcode to run and debug tests.

## Pull Request Expectations

- PRs must include tests for all new/changed code.
- PRs must not break existing tests.
- PRs should be reviewed for test completeness and quality.

## Example Test Pattern

```swift
import Quick
import Nimble

class MyFeatureSpec: QuickSpec {
    override class func spec() {
        describe("MyFeature") {
            context("when condition") {
                it("does something expected") {
                    // Arrange
                    // Act
                    // Assert
                    expect(result).to(equal(expected))
                }
            }
        }
    }
}
```

## Additional Resources

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [Quick Documentation](https://github.com/Quick/Quick)
- [Nimble Documentation](https://github.com/Quick/Nimble)

---

**By following these guidelines, you help ensure the reliability, maintainability, and quality of the Auth0.swift codebase.** 