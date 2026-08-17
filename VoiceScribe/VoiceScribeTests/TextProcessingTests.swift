import XCTest
@testable import LaSay

final class TextProcessingTests: XCTestCase {
    func testPunctuationStyles() {
        XCTAssertEqual(PunctuationConverter.convert("你好,世界!", to: .fullWidth), "你好，世界！")
        XCTAssertEqual(PunctuationConverter.convert("你好，世界！", to: .halfWidth), "你好,世界!")
        XCTAssertEqual(PunctuationConverter.convert("你好，世界！", to: .spaces), "你好 世界 ")
    }

    func testTechnicalTerms() {
        XCTAssertEqual(TechTermsDictionary.apply(to: "javascript 和 fastapi"), "JavaScript 和 FastAPI")
    }
}
