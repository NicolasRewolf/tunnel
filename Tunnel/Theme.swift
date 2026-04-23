import SwiftUI

/// Single source of truth for Tunnel's brand colors.
/// Any green, red, or accent used in the UI should come from here.
enum Theme {
    /// Signature green used for the primary CTA, accept actions, and brand pulse.
    static let green = Color(red: 0.20, green: 0.78, blue: 0.35)

    /// Darker shade of the brand green, used in shadows and depth.
    static let greenDeep = Color(red: 0.16, green: 0.70, blue: 0.30)

    /// Red used for decline, end-call, and destructive actions.
    static let red = Color(red: 0.97, green: 0.26, blue: 0.28)
}
