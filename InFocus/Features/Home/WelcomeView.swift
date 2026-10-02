import SwiftUI

/// First run: what the app is, and which alerts to turn on (the iOS prompt
/// only comes after the person chooses to).
struct WelcomeView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(PushManager.self) private var push
    @State private var asking = false

    var body: some View {
        @Bindable var preferences = preferences
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 16) {
                    Image("Wordmark").resizable().scaledToFit().frame(height: 44)
                        .accessibilityLabel("InFocus")
                    Text("Paly's student broadcast network, in your pocket.")
                        .headline(.display, tracking: -0.6)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Watch every InFocus News episode, read the latest stories, catch games live, and send your own announcements for the show.")
                        .font(.bodyText)
                        .foregroundStyle(Brand.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 48)

                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("Alert me when").padding(.bottom, 6)
                    Toggle("A new show is up", isOn: $preferences.notifyShows).frame(minHeight: 44)
                    Divider().overlay(Brand.line)
                    Toggle("A new story is posted", isOn: $preferences.notifyStories).frame(minHeight: 44)
                    Divider().overlay(Brand.line)
                    Toggle("InFocus goes live", isOn: $preferences.notifyLive).frame(minHeight: 44)
                }
                .font(.bodyText)
                .toggleStyle(SwitchToggleStyle(tint: Brand.fill))
                .card()
            }
            .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 10) {
                Button {
                    Task {
                        asking = true
                        if preferences.wantsAnyAlerts { await push.requestPermission() }
                        asking = false
                        preferences.onboarded = true
                    }
                } label: {
                    Text(preferences.wantsAnyAlerts ? "Turn on notifications" : "Get started")
                }
                .buttonStyle(.brandPrimary)
                .disabled(asking)
                if preferences.wantsAnyAlerts {
                    Button("Not now") { preferences.onboarded = true }
                        .font(.button)
                        .foregroundStyle(Brand.muted)
                        .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Brand.background)
        }
        .brandBackground()
        .interactiveDismissDisabled()
    }
}
