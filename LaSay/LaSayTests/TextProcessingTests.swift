import XCTest
@testable import LaSay

final class TextProcessingTests: XCTestCase {
    func testTechnicalTerms() {
        XCTAssertEqual(TechTermsDictionary.apply(to: "javascript 和 fastapi"), "JavaScript 和 FastAPI")
    }

    func testChineseOutputScripts() {
        XCTAssertEqual(ChineseOutputConverter.convert("繁體中文", to: .simplified), "繁体中文")
        XCTAssertEqual(ChineseOutputConverter.convert("繁体中文", to: .traditional), "繁體中文")
    }
}
