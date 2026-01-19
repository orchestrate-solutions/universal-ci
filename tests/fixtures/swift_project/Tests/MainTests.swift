import XCTest

final class MainTests: XCTestCase {
    func testAdd() {
        XCTAssertEqual(add(5, 3), 8)
        XCTAssertEqual(add(0, 0), 0)
        XCTAssertEqual(add(-2, -3), -5)
    }
}
