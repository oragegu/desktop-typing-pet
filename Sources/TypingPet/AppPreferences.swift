import AppKit

enum PetSize: Int, CaseIterable {
    case small = 0
    case normal = 1
    case large = 2
    case extraLarge = 3

    var title: String {
        switch self {
        case .small: return "Small"
        case .normal: return "Normal"
        case .large: return "Large"
        case .extraLarge: return "Extra Large"
        }
    }

    var windowSize: NSSize {
        switch self {
        case .small: return NSSize(width: 240, height: 150)
        case .normal: return NSSize(width: 320, height: 200)
        case .large: return NSSize(width: 400, height: 250)
        case .extraLarge: return NSSize(width: 520, height: 325)
        }
    }
}

final class AppPreferences {
    static let shared = AppPreferences()
    private let defaults = UserDefaults.standard

    var petSize: PetSize {
        get { PetSize(rawValue: defaults.integer(forKey: "petSize")) ?? .normal }
        set { defaults.set(newValue.rawValue, forKey: "petSize") }
    }

    var alwaysOnTop: Bool {
        get { defaults.object(forKey: "alwaysOnTop") == nil ? true : defaults.bool(forKey: "alwaysOnTop") }
        set { defaults.set(newValue, forKey: "alwaysOnTop") }
    }

    var positionLocked: Bool {
        get { defaults.bool(forKey: "positionLocked") }
        set { defaults.set(newValue, forKey: "positionLocked") }
    }

    var imagePaths: [String: String] {
        get { defaults.dictionary(forKey: "imagePaths") as? [String: String] ?? [:] }
        set { defaults.set(newValue, forKey: "imagePaths") }
    }

    var savedOrigin: NSPoint? {
        get {
            guard defaults.object(forKey: "windowX") != nil,
                  defaults.object(forKey: "windowY") != nil else { return nil }
            return NSPoint(x: defaults.double(forKey: "windowX"),
                           y: defaults.double(forKey: "windowY"))
        }
        set {
            guard let newValue else {
                defaults.removeObject(forKey: "windowX")
                defaults.removeObject(forKey: "windowY")
                return
            }
            defaults.set(newValue.x, forKey: "windowX")
            defaults.set(newValue.y, forKey: "windowY")
        }
    }
}
