import Foundation

extension Notification.Name {
    static let interfaceLanguageDidChange = Notification.Name("InterfaceLanguageDidChange")
}

enum AppLocalizer {
    private static let interfaceLanguageKey = "interface_language"

    private final class BundleToken {}

    static var language: InterfaceLanguage {
        get {
            UserDefaults.standard.string(forKey: interfaceLanguageKey)
                .flatMap(InterfaceLanguage.init(rawValue:)) ?? .english
        }
        set {
            guard language != newValue else { return }
            UserDefaults.standard.set(newValue.rawValue, forKey: interfaceLanguageKey)
            NotificationCenter.default.post(name: .interfaceLanguageDidChange, object: newValue)
        }
    }

    static func string(_ key: String) -> String {
        guard language != .traditionalChinese else { return key }
        guard let path = Bundle(for: BundleToken.self).path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: "Localizable")
    }
}
