import SwiftUI

/// Submit an announcement, saved stories, settings.
struct MoreView: View {
    @Environment(SavedStore.self) private var saved

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: AnnounceRoute()) {
                        row("Submit an announcement", "Get your news read on the show", "megaphone")
                    }
                    NavigationLink(value: SavedRoute()) {
                        row("Saved stories", saved.stories.isEmpty ? "Nothing saved yet" : "\(saved.stories.count) saved",
                            "bookmark")
                    }
                }
                Section {
                    NavigationLink(value: SettingsRoute()) {
                        row("Settings", "Notifications and appearance", "gearshape")
                    }
                }
                Section {
                    Link(destination: AppConfig.newsSiteURL) {
                        row("infocusnews.tv", "The full website", "safari")
                    }
                    Link(destination: YouTube.channelURL) {
                        row("YouTube", "@infocusnews", "play.rectangle")
                    }
                }
            }
            .listRowBackground(Brand.card)
            .scrollContentBackground(.hidden)
            .brandBackground()
            .navigationTitle("More")
            .navigationDestination(for: AnnounceRoute.self) { _ in AnnounceView() }
            .navigationDestination(for: SavedRoute.self) { _ in SavedView() }
            .navigationDestination(for: SettingsRoute.self) { _ in SettingsView() }
            .navigationDestination(for: Story.self) { StoryDetailView(story: $0) }
        }
    }

    private func row(_ title: String, _ detail: String, _ icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(Brand.green)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.lexend(16, .medium, relativeTo: .body)).foregroundStyle(Brand.text)
                Text(detail).font(.small).foregroundStyle(Brand.muted)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SettingsRoute: Hashable {}
