import XCTest
@testable import PrintClockKit

final class UpdateCheckerTests: XCTestCase {
    func testNormaliseStripsVersionPrefix() {
        XCTAssertEqual(UpdateChecker.normalise("v1.2.3"), "1.2.3")
        XCTAssertEqual(UpdateChecker.normalise("V1.2.3"), "1.2.3")
        XCTAssertEqual(UpdateChecker.normalise("1.2.3"), "1.2.3")
    }

    func testNewerVersionComparison() {
        XCTAssertTrue(UpdateChecker.isNewer("1.0.1", than: "1.0.0"))
        XCTAssertTrue(UpdateChecker.isNewer("1.1", than: "1.0.9"))
        XCTAssertTrue(UpdateChecker.isNewer("2.0", than: "1.9.9"))
        XCTAssertTrue(UpdateChecker.isNewer("1.10", than: "1.9"))
        XCTAssertFalse(UpdateChecker.isNewer("1.0", than: "1.0.0"))
        XCTAssertFalse(UpdateChecker.isNewer("1.0.0", than: "1.0"))
        XCTAssertFalse(UpdateChecker.isNewer("0.9", than: "1.0"))
    }

    func testSameVersionIsNotNewer() {
        XCTAssertFalse(UpdateChecker.isNewer("v1.2.3", than: "1.2.3"))
    }
}
