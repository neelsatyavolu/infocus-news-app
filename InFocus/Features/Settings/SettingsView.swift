import SwiftUI

/// Alerts, appearance and about.
struct SettingsView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(PushManager.self) private var push
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var preferences = preferences
        Form {
            Section {
                switch push.permission {
                case .denied:
                    Label("Notifications are off for InFocus in iOS Settings.", systemImage: "bell.slash")
                        .font(.small)
                        .foregroundStyle(Brand.warning)
                    Button("Open iOS Settings") { push.openSystemSettings() }
                case .notDetermined:
                    Button("Turn on notifications") { Task { await push.requestPermission() } }
                case .allowed:
                    EmptyView()
                }
                Toggle("New shows", isOn: $preferences.notifyShows)
                Toggle("New stories", isOn: $preferences.notifyStories)
                Toggle("Going live", isOn: $preferences.notifyLive)
            } header: {
                Text("Notifications")
            } footer: {
                if let error = push.lastError {
                    Label("Couldn't update alerts: \(error)", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(Brand.danger)
                } else {
                    Text("Get an alert when a new episode is up, a story is posted, or InFocus starts streaming a game or event.")
                }
            }
            .disabled(push.permission == .denied)

            Section("Appearance") {
                Picker("Theme", selection: $preferences.appearance) {
                    ForEach(Appearance.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Section("About") {
                Link(destination: AppConfig.newsSiteURL) { Label("infocusnews.tv", systemImage: "safari") }
                Link(destination: YouTube.channelURL) { Label("InFocus on YouTube", systemImage: "play.rectangle") }
                Link(destination: AppConfig.aboutURL) { Label("About InFocus", systemImage: "info.circle") }
                Link(destination: AppConfig.privacyURL) { Label("Privacy", systemImage: "hand.raised") }
                LabeledContent("Version") {
                    Text("\(AppConfig.version) (\(AppConfig.build))").font(.mono(14))
                }
            }
        }
        .font(.bodyText)
        .scrollContentBackground(.hidden)
        .brandBackground()
        .navigationTitle("Settings")
        .onChange(of: preferences.notifyShows) { push.scheduleSync() }
        .onChange(of: preferences.notifyStories) { push.scheduleSync() }
        .onChange(of: preferences.notifyLive) { push.scheduleSync() }
        .onChange(of: scenePhase) { _, phase in
            // Back from iOS Settings: pick up a permission change.
            if phase == .active { Task { await push.sync() } }
        }
        .task { await push.refreshPermission() }
    }
}
