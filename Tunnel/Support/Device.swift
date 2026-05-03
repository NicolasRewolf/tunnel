import Foundation

/// Hardware capability flags. Distinct from runtime `#available` checks —
/// these reflect *physical* device features (buttons, sensors), not the iOS
/// version. Used to hide UI guidance for hardware the user does not have.
enum Device {
    /// True if the device ships with the Action Button (the customizable
    /// side button that replaced the ring/silent switch).
    ///
    /// Hardware history:
    ///  - iPhone 14 and earlier → ring/silent switch (no Action Button)
    ///  - iPhone 15 / 15 Plus   → ring/silent switch (no Action Button)
    ///  - iPhone 15 Pro / Pro Max → first Action Button (`iPhone16,1` / `,2`)
    ///  - iPhone 16 series and later → Action Button on every model
    ///
    /// Apple's internal model numbering is offset from the marketing year,
    /// hence `iPhone16,*` = iPhone 15 Pro family.
    static let hasActionButton: Bool = hasActionButton(identifier: identifier)

    /// Pure function over a model identifier — exposed for unit testing the
    /// hardware-mapping logic without relying on `utsname`.
    static func hasActionButton(identifier: String) -> Bool {
        guard identifier.hasPrefix("iPhone") else { return false }
        let parts = identifier.dropFirst("iPhone".count).split(separator: ",")
        guard parts.count == 2,
              let major = Int(parts[0]),
              let minor = Int(parts[1])
        else { return false }
        if major == 16, minor >= 1 { return true }   // iPhone 15 Pro / Pro Max
        if major >= 17 { return true }               // iPhone 16+ (all models)
        return false
    }

    /// Hardware model identifier, e.g. `"iPhone17,1"`.
    /// In the simulator, returns the *simulated* device's identifier so the
    /// flags above evaluate against the device the developer chose, not the
    /// host Mac.
    static var identifier: String {
        if let sim = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"],
           !sim.isEmpty {
            return sim
        }
        var sys = utsname()
        uname(&sys)
        return withUnsafePointer(to: &sys.machine) { ptr in
            ptr.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
                String(cString: $0)
            }
        }
    }
}
