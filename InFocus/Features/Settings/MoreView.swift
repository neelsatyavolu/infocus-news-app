import SwiftUI

/// Get involved, About InFocus, Follow, and the app itself.
struct MoreView: View {
    @Environment(SavedStore.self) private var saved
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.morePath) {
            List {
                Section("Get involved") {
                    NavigationLink(value: MoreRoute.announce) {
                        MoreRow(title: "Submit an announcement", detail: "Get your news read on the show", symbol: "megaphone")
                    }
                    NavigationLink(value: MoreRoute.saved) {
                        MoreRow(title: "Saved stories",
                                detail: saved.stories.isEmpty ? "Nothing saved yet" : "\(saved.stories.count) saved",
                                symbol: "bookmark")
                    }
                }
                Section("About InFocus") {
                    NavigationLink(value: MoreRoute.about) {
                        MoreRow(title: "About us", detail: "Who we are and our editorial policy", symbol: "info.circle")
                    }
                    NavigationLink(value: MoreRoute.staff) {
                        MoreRow(title: "Staff", detail: "The students behind InFocus", symbol: "person.2")
                    }
                    NavigationLink(value: MoreRoute.contact) {
                        MoreRow(title: "Contact", detail: "Questions, tips and feedback", symbol: "envelope")
                    }
                }
                Section("Follow InFocus") {
                    ForEach(SocialLink.all) { social in
                        ExternalRow(url: social.url, title: social.network, detail: social.handle, symbol: social.symbol)
                            .accessibilityHint("Opens \(social.network)")
                    }
                }
                Section {
                    NavigationLink(value: MoreRoute.settings) {
                        MoreRow(title: "Settings", detail: "Notifications and appearance", symbol: "gearshape")
                    }
                    ExternalRow(url: AppConfig.supportURL, title: "Help & support", detail: "Answers and how to reach us",
                                symbol: "questionmark.circle")
                    ExternalRow(url: AppConfig.privacyURL, title: "Privacy policy", detail: "What the app collects",
                                symbol: "hand.raised")
                } header: {
                    Text("App")
                } footer: {
                    Text("InFocus \(AppConfig.version) (\(AppConfig.build))")
                        .font(.mono(12))
                        .foregroundStyle(Brand.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
            }
            .scrollContentBackground(.hidden)
            .brandBackground()
            .readableMargins()
            .navigationTitle("More")
            .navigationDestination(for: MoreRoute.self) { route in
                switch route {
                case .announce: AnnounceView()
                case .saved: SavedView()
                case .about: AboutView()
                case .staff: StaffView()
                case .contact: ContactView()
                case .settings: SettingsView()
                }
            }
            .navigationDestination(for: Story.self) { StoryDetailView(story: $0) }
        }
    }
}

enum MoreRoute: Hashable {
    case announce, saved, about, staff, contact, settings
}

private struct MoreRow: View {
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Brand.green)
                .frame(width: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.lexend(16, .medium, relativeTo: .body)).foregroundStyle(Brand.text)
                Text(detail).font(.small).foregroundStyle(Brand.muted)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A row that leaves the app (another app or Safari), marked with ↗.
private struct ExternalRow: View {
    let url: URL
    let title: String
    let detail: String
    let symbol: String

    var body: some View {
        Link(destination: url) {
            HStack {
                MoreRow(title: title, detail: detail, symbol: symbol)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.muted)
                    .accessibilityHidden(true)
            }
        }
    }
}
