import SwiftUI

/// Home screen: hero icon, name, primary CTA (or armed-timer cancel),
/// secondary Raccourcis / Réglages.
struct HomeView: View {
    let appState: AppState
    @State private var pulseRing = false
    @State private var showTimerPicker = false
    @State private var showShortcutAnnouncement = false
    @State private var pendingUpdate: UpdateChecker.Outcome?

    private var isArmed: Bool { appState.armedDeadline != nil }

    var body: some View {
        ZStack {
            HomeBackgroundLayer()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                HomeHeroIcon(
                    isArmed: isArmed,
                    armedDeadline: appState.armedDeadline,
                    armedTotalDuration: appState.armedTotalDuration,
                    pulseRing: $pulseRing
                )
                .padding(.bottom, 40)

                VStack(spacing: 8) {
                    Text("Tunnel")
                        .font(.largeTitle.weight(.bold))
                        .tracking(-0.8)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel("Untunnel")

                    HomeSubtitle(armedDeadline: appState.armedDeadline)
                }

                Spacer()

                HomePrimaryControls(
                    armedDeadline: appState.armedDeadline,
                    onShowTimerPicker: presentTimerPicker,
                    onTriggerCall: triggerCall,
                    onCancelTimer: cancelTimer
                )

                HomeSecondaryActions(
                    onOpenOnboarding: { appState.openOnboarding() },
                    onOpenSettings: { appState.openSettings() }
                )
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
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: routedSheetBinding(for: .settings)) {
            SettingsView(appState: appState)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: routedSheetBinding(for: .onboarding)) {
            OnboardingView(appState: appState)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showShortcutAnnouncement, onDismiss: markShortcutAnnouncementSeen) {
            ShortcutAnnouncementSheet(
                onOpenShortcuts: openShortcutsFromAnnouncement,
                onDismiss: { showShortcutAnnouncement = false }
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $pendingUpdate) { outcome in
            UpdateAvailableSheet(
                latestVersion: outcome.latestVersion,
                onUpdate: { openAppStore(outcome) },
                onDismiss: dismissUpdatePrompt
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .task { await presentStartupSheetsIfNeeded() }
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

    // MARK: - Sheet routing

    private func routedSheetBinding(for screen: AppState.Screen) -> Binding<Bool> {
        Binding(
            get: { appState.screen == screen },
            set: { isPresented in
                if !isPresented && appState.screen == screen {
                    appState.screen = .home
                }
            }
        )
    }

    // MARK: - Actions

    private func presentTimerPicker() {
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        showTimerPicker = true
    }

    private func triggerCall() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        appState.triggerFakeCallNow()
    }

    private func cancelTimer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        appState.disarmTimer()
    }

    private func markShortcutAnnouncementSeen() {
        appState.markShortcutAnnouncementSeen()
    }

    private func openShortcutsFromAnnouncement() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
        showShortcutAnnouncement = false
    }

    private func openAppStore(_ outcome: UpdateChecker.Outcome) {
        UIApplication.shared.open(outcome.appStoreURL)
        pendingUpdate = nil
    }

    private func dismissUpdatePrompt() {
        UpdateChecker.snooze()
        pendingUpdate = nil
    }

    private func presentStartupSheetsIfNeeded() async {
        if appState.shouldOfferShortcutAnnouncement {
            showShortcutAnnouncement = true
            return
        }
        pendingUpdate = await UpdateChecker.checkForAvailableUpdate()
    }
}

// MARK: - Secondary actions

private struct HomeSecondaryActions: View {
    let onOpenOnboarding: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onOpenOnboarding) {
                Label("Raccourcis", systemImage: "hand.tap.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .accessibilityLabel("Configurer les raccourcis de déclenchement")

            Button(action: onOpenSettings) {
                Label("Réglages", systemImage: "gearshape.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .accessibilityLabel("Ouvrir les réglages")
        }
    }
}

#Preview {
    HomeView(appState: AppState.shared)
}
