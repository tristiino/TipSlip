import Foundation

enum AppTheme: String, Codable, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
}

struct UserSettings: Codable {
    var theme:                AppTheme
    var language:             String
    var taxRate:              Double
    var payPeriodStartAnchor: String?  // "yyyy-MM-dd", null for new users
    var payPeriodLengthDays:  Int
    var morningStart:         String?  // "HH:mm:ss"
    var eveningStart:         String?  // "HH:mm:ss"
    var nightStart:           String?  // "HH:mm:ss"
}
