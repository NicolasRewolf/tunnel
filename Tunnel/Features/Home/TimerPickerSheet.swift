import SwiftUI

struct TimerPickerSheet: View {
    let onSelect: (Int) -> Void

    @State private var customHours: Int = 0
    @State private var customMinutes: Int = 20

    private static let options: [Int] = [5, 10, 15, 30, 45, 60]

    private var customTotalMinutes: Int {
        customHours * 60 + customMinutes
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Déclencher dans…")
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Une notification te préviendra. Touche-la pour lancer l’appel, même iPhone verrouillé.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 12)
            .padding(.horizontal, 24)

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 12),
                    count: 3
                ),
                spacing: 12
            ) {
                ForEach(Self.options, id: \.self) { minutes in
                    Button {
                        onSelect(minutes)
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(minutes)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("min")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 70)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Déclencher dans \(minutes) minutes")
                }
            }
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 0.5)
                Text("ou personnalisé")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                Rectangle()
                    .fill(Color.secondary.opacity(0.25))
                    .frame(height: 0.5)
            }
            .padding(.horizontal, 24)
            .accessibilityHidden(true)

            HStack(spacing: 0) {
                Picker("Heures", selection: $customHours) {
                    ForEach(0..<6) { hour in
                        Text("\(hour) h").tag(hour)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Heures")

                Picker("Minutes", selection: $customMinutes) {
                    ForEach(0..<60) { min in
                        Text("\(min) min").tag(min)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("Minutes")
            }
            .frame(height: 150)
            .padding(.horizontal, 20)

            Button {
                onSelect(customTotalMinutes)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "timer")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Programmer · \(Self.formatDuration(minutes: customTotalMinutes))")
                        .font(.system(size: 17, weight: .semibold))
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .tint(Theme.green)
            .padding(.horizontal, 20)
            .disabled(customTotalMinutes <= 0)
            .accessibilityLabel("Programmer le minuteur sur \(Self.formatDuration(minutes: customTotalMinutes))")

            Spacer(minLength: 0)
        }
        .padding(.bottom, 24)
    }

    private static func formatDuration(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let mins = minutes % 60
        if mins == 0 {
            return "\(hours) h"
        }
        return "\(hours) h \(String(format: "%02d", mins))"
    }
}
