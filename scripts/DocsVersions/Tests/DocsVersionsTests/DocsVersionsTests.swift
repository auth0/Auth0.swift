import XCTest
@testable import DocsVersions

final class SemVerTests: XCTestCase {
    func testParsesCoreVersion() {
        let v = SemVer("2.21.2")
        XCTAssertEqual(v?.major, 2)
        XCTAssertEqual(v?.minor, 21)
        XCTAssertEqual(v?.patch, 2)
        XCTAssertEqual(v?.isPrerelease, false)
    }

    func testParsesPrerelease() {
        let v = SemVer("3.0.0-beta.2")
        XCTAssertEqual(v?.major, 3)
        XCTAssertEqual(v?.isPrerelease, true)
        XCTAssertEqual(v?.description, "3.0.0-beta.2")
    }

    func testToleratesLeadingV() {
        XCTAssertEqual(SemVer("v1.2.3")?.description, "1.2.3")
    }

    func testRejectsMalformed() {
        XCTAssertNil(SemVer("1.2"))
        XCTAssertNil(SemVer("x.y.z"))
    }

    func testStableOutranksPrerelease() {
        XCTAssertTrue(SemVer("3.0.0-beta.2")! < SemVer("3.0.0")!)
    }

    func testPrereleaseOrdering() {
        XCTAssertTrue(SemVer("3.0.0-beta.1")! < SemVer("3.0.0-beta.2")!)
        XCTAssertTrue(SemVer("3.0.0-alpha")! < SemVer("3.0.0-beta")!)
    }

    func testCoreOrdering() {
        XCTAssertTrue(SemVer("2.21.2")! < SemVer("2.22.0")!)
        XCTAssertTrue(SemVer("2.22.0")! < SemVer("3.0.0")!)
    }
}

final class RetentionTests: XCTestCase {
    private func versions(_ raw: String...) -> [SemVer] {
        raw.compactMap(SemVer.init)
    }

    func testStableKeepsTwoMostRecentMajors() {
        let keep = Retention.versionsToKeep(
            current: SemVer("3.1.0")!,
            existing: versions("3.0.0", "2.22.0", "2.21.2", "1.36.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["3.1.0", "2.22.0"])
    }

    func testStableUsesHighestPatchPerMajor() {
        let keep = Retention.versionsToKeep(
            current: SemVer("2.22.0")!,
            existing: versions("2.21.2", "2.21.1", "1.36.0", "1.35.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["2.22.0", "1.36.0"])
    }

    func testPrereleaseKeepsCurrentPlusEarlierStableMajor() {
        let keep = Retention.versionsToKeep(
            current: SemVer("3.0.0-beta.2")!,
            existing: versions("3.0.0-beta.1", "2.22.0", "2.21.2")
        )
        XCTAssertEqual(keep.map { $0.description }, ["3.0.0-beta.2", "2.22.0"])
    }

    func testPrereleaseWithNoEarlierStableKeepsOnlyItself() {
        let keep = Retention.versionsToKeep(
            current: SemVer("1.0.0-alpha.1")!,
            existing: versions("1.0.0-alpha.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["1.0.0-alpha.1"])
    }
}
