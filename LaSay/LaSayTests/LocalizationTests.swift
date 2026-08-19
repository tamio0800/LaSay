import XCTest
@testable import LaSay

final class LocalizationTests: XCTestCase {
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: "interface_language")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "interface_language")
        super.tearDown()
    }

    func testLookupChangesWithInterfaceLanguage() {
        AppLocalizer.language = .english
        XCTAssertEqual(AppLocalizer.string("結束 LaSay"), "Quit LaSay")
        XCTAssertEqual(AppLocalizer.string("介面語言"), "Interface Language")

        AppLocalizer.language = .traditionalChinese
        XCTAssertEqual(AppLocalizer.string("結束 LaSay"), "結束 LaSay")
        XCTAssertEqual(AppLocalizer.string("介面語言"), "介面語言")

        AppLocalizer.language = .simplifiedChinese
        XCTAssertEqual(AppLocalizer.string("結束 LaSay"), "退出 LaSay")
        XCTAssertEqual(AppLocalizer.string("介面語言"), "界面语言")
    }
}
