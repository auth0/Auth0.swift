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
        XCTAssertNil(SemVer("1.0.0-"))
        XCTAssertNil(SemVer("1.0.0-alpha..1"))
        XCTAssertNil(SemVer("01.2.3"))
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

    func testStableKeepsPreviousMajorStable() {
        // Current major (3) → current release; previous major (2) → its latest
        // stable. Older majors (1) fall outside the two-line window.
        let keep = Retention.versionsToKeep(
            current: SemVer("3.0.0")!,
            existing: versions("2.22.0", "2.21.2", "1.36.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["3.0.0", "2.22.0"])
    }

    func testStableDropsOldCurrentMajorVersions() {
        // Publishing within the current major drops that major's older versions;
        // with no other major present only the current release remains.
        let keep = Retention.versionsToKeep(
            current: SemVer("2.24.0")!,
            existing: versions("2.23.0", "2.22.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["2.24.0"])
    }

    func testStableKeepsLiveNextMajorBeta() {
        // Latest major (3) is a live beta with no stable yet → keep the beta.
        // Previous major (2) → its latest stable.
        let keep = Retention.versionsToKeep(
            current: SemVer("2.24.0")!,
            existing: versions("3.0.0-beta.2", "3.0.0-beta.1", "2.23.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["3.0.0-beta.2", "2.24.0"])
    }

    func testStablePatchKeepsLiveNextMajorBetaAndDropsOldCurrentMajor() {
        // Releasing 2.25.0 while a 3.0.0 beta is live: current major (2) collapses
        // to 2.25.0 (2.24.0 dropped), next major (3) keeps its live beta.
        let keep = Retention.versionsToKeep(
            current: SemVer("2.25.0")!,
            existing: versions("3.0.0-beta.2", "2.24.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["3.0.0-beta.2", "2.25.0"])
    }

    func testStablePromotionDropsOwnBetaAndKeepsPreviousMajorStable() {
        // Promoting the 3.0.0 beta to stable: the beta is an old version of the
        // current major (3) and is dropped (stable wins); previous major (2)
        // keeps its latest stable.
        let keep = Retention.versionsToKeep(
            current: SemVer("3.0.0")!,
            existing: versions("3.0.0-beta.2", "2.24.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["3.0.0", "2.24.0"])
    }

    func testStableWithNoOtherMajorKeepsOnlyItself() {
        let keep = Retention.versionsToKeep(
            current: SemVer("1.0.0")!,
            existing: versions("1.0.0-beta.1")
        )
        XCTAssertEqual(keep.map { $0.description }, ["1.0.0"])
    }

    func testPrereleaseKeepsCurrentPlusEarlierStableMajor() {
        let keep = Retention.versionsToKeep(
            current: SemVer("3.0.0-beta.2")!,
            existing: versions("3.0.0-beta.1", "2.23.0", "2.22.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["3.0.0-beta.2", "2.23.0"])
    }

    func testPrereleaseKeepsSameMajorStable() {
        let keep = Retention.versionsToKeep(
            current: SemVer("2.24.0-beta.1")!,
            existing: versions("2.23.0", "2.22.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["2.24.0-beta.1", "2.23.0"])
    }

    func testPrereleaseWithNoEarlierStableKeepsOnlyItself() {
        let keep = Retention.versionsToKeep(
            current: SemVer("1.0.0-alpha.1")!,
            existing: versions("1.0.0-alpha.0")
        )
        XCTAssertEqual(keep.map { $0.description }, ["1.0.0-alpha.1"])
    }
}
