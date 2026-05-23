import Foundation

/// Presets for the subtitle shown under the caller name (like Phone.app labels).
enum ContactSubtitlePreset: String, CaseIterable, Identifiable {
    case portable
    case fixe
    case bureau
    case domicile
    case personnalise

    var id: String { rawValue }

    var label: String {
        switch self {
        case .portable: return "Portable"
        case .fixe: return "Fixe"
        case .bureau: return "Bureau"
        case .domicile: return "Domicile"
        case .personnalise: return "Autre…"
        }
    }

    /// Value stored in `CallProfile.contactSubtitle`.
    var storedValue: String {
        switch self {
        case .portable: return "Portable"
        case .fixe: return "Fixe"
        case .bureau: return "Bureau"
        case .domicile: return "Domicile"
        case .personnalise: return ""
        }
    }

    static func matching(_ string: String) -> ContactSubtitlePreset {
        let t = string.trimmingCharacters(in: .whitespacesAndNewlines)
        for preset in ContactSubtitlePreset.allCases where preset != .personnalise {
            if preset.storedValue.caseInsensitiveCompare(t) == .orderedSame { return preset }
        }
        return .personnalise
    }
}
