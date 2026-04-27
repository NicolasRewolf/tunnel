import SwiftUI

/// Home screen: hero icon, name, primary CTA (or armed-timer cancel),
/// secondary Raccourcis / Réglages.
///
/// Two states drive the layout, both read from `AppState.armedDeadline`:
///  - **Idle** — timer button (circular glass) + "Sortir du tunnel" CTA.
///  - **Armed** — CTA morphs into a destructive countdown; the hero icon
///    gains a progression ring that drains to the deadline.
struct HomeView: View {
    let appState: AppState
    @State private var pulseRing = false
    @State private var showTimerPicker = false

    private var isArmed: Bool { appState.armedDeadline != nil }

    var body: some View {
        ZStack {
            backgroundLayer

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                heroIcon
                    .padding(.bottom, 40)

                VStack(spacing: 8) {
                    Text("Tunnel")
                        .font(.largeTitle.weight(.bold))
                        .tracking(-0.8)

                    subtitle
                }

                Spacer()

                primaryControls

                HStack(spacing: 12) {
                    Button { appState.openOnboarding() } label: {
                        Label("Raccourcis", systemImage: "hand.tap.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityLabel("Configurer les raccourcis de déclenchement")

                    Button { appState.openSettings() } label: {
                        Label("Réglages", systemImage: "gearshape.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .accessibilityLabel("Ouvrir les réglages")
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .overlay(alignment: .top) { errorToast }
        .animation(.easeOut(duration: 0.25), value: appState.lastTriggerError)
        .animation(.easeInOut(duration: 0.35), value: isArmed)
        .sheet(isPresented: $showTimerPicker) {
            TimerPickerSheet { minutes in
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                appState.armTimer(duration: TimeInterval(minutes * 60))
                showTimerPicker = false
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Subtitle

    @ViewBuilder
    private var subtitle: some View {
        if let deadline = appState.armedDeadline {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text("Sortie du tunnel dans \(Self.countdown(until: deadline, at: context.date))")
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Theme.green)
                    .contentTransition(.numericText(countsDown: true))
            }
        } else {
            Text("Sortir d'une conversation en un geste.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Primary controls (idle vs armed)

    @ViewBuilder
    private var primaryControls: some View {
        if let deadline = appState.armedDeadline {
            armedCTA(deadline: deadline)
        } else {
            idleControls
        }
    }

    private var idleControls: some View {
        HStack(spacing: 12) {
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                showTimerPicker = true
            } label: {
                Image(systemName: "timer")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.glass)
            .clipShape(Circle())
            .accessibilityLabel("Programmer un faux appel plus tard")

            Button(action: triggerCall) {
                HStack(spacing: 10) {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 17, weight: .semibold))
                    Text("Sortir du tunnel")
                        .font(.system(size: 17, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(Theme.green)
            .accessibilityLabel("Sortir du tunnel, déclenche un faux appel")
        }
    }

    private func armedCTA(deadline: Date) -> some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Button(action: cancelTimer) {
                HStack(spacing: 10) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Annuler · \(Self.countdown(until: deadline, at: context.date))")
                        .font(.system(size: 17, weight: .semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.extraLarge)
            .tint(Theme.red)
            .accessibilityLabel("Annuler le minuteur")
            .accessibilityValue("Sortie du tunnel dans \(Self.countdown(until: deadline, at: context.date))")
        }
    }

    // MARK: - Error toast

    @ViewBuilder
    private var errorToast: some View {
        if let message = appState.lastTriggerError {
            ErrorToast(message: message)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: message) {
                    try? await Task.sleep(for: .seconds(3))
                    appState.acknowledgeTriggerError()
                }
        }
    }

    // MARK: - Actions

    private func triggerCall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        appState.triggerFakeCallNow()
    }

    private func cancelTimer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        appState.disarmTimer()
    }

    // MARK: - Hero

    private var backgroundLayer: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.green.opacity(0.15), .clear],
                center: .init(x: 0.5, y: 0.22),
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.accentColor.opacity(0.10), .clear],
                center: .init(x: 0.5, y: 0.85),
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()
        }
    }

    private var heroIcon: some View {
        ZStack {
            if isArmed {
                progressionRing
            } else {
                pulseRings
            }

            Image(systemName: isArmed ? "timer" : "phone.fill")
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 130, height: 130)
                .glassEffect(.regular.tint(Theme.green), in: .circle)
                .shadow(color: Theme.greenDeep.opacity(0.5), radius: 22, x: 0, y: 10)
                .contentTransition(.symbolEffect(.replace))
        }
        .onAppear { pulseRing = true }
    }

    private var pulseRings: some View {
        ZStack {
            Circle()
                .stroke(Theme.green.opacity(0.25), lineWidth: 1)
                .frame(width: 170, height: 170)
                .scaleEffect(pulseRing ? 1.12 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false),
                    value: pulseRing
                )

            Circle()
                .stroke(Theme.green.opacity(0.35), lineWidth: 1)
                .frame(width: 150, height: 150)
                .scaleEffect(pulseRing ? 1.15 : 1.0)
                .opacity(pulseRing ? 0 : 1)
                .animation(
                    .easeOut(duration: 2.2).repeatForever(autoreverses: false).delay(0.6),
                    value: pulseRing
                )
        }
    }

    @ViewBuilder
    private var progressionRing: some View {
        if let deadline = appState.armedDeadline, appState.armedTotalDuration > 0 {
            let total = appState.armedTotalDuration
            TimelineView(.animation(minimumInterval: 0.05, paused: false)) { context in
                let remaining = max(0, deadline.timeIntervalSince(context.date))
                let progress = max(0, min(1, 1 - (remaining / total)))
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Theme.green,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 158, height: 158)
            }
        }
    }

    // MARK: - Countdown helper

    /// Formats `mm:ss` remaining between `now` and `deadline`, clamped at 0.
    /// Rounds up so the first second shown matches the arming duration
    /// (arming at 15:00.000 shows 15:00, not 14:59).
    private static func countdown(until deadline: Date, at now: Date) -> String {
        let remaining = max(0, Int(deadline.timeIntervalSince(now).rounded(.up)))
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    HomeView(appState: AppState.shared)
}

// MARK: - Timer picker sheet

private struct TimerPickerSheet: View {
    let onSelect: (Int) -> Void

    private static let options: [Int] = [5, 10, 15, 30, 45, 60]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Déclencher dans…")
                    .font(.title2.weight(.semibold))
                Text("Une notification te préviendra à l’heure dite. Tu peux verrouiller l’iPhone ; touche la notification pour lancer le faux appel.")
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
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.primary)
                            Text("min")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 76)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel("Déclencher dans \(minutes) minutes")
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 0)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - Error toast

private struct ErrorToast: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.red)
                .padding(.top, 1)

            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }
}
