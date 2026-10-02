import SwiftUI

/// Stories saved for later on this device.
struct SavedView: View {
    @Environment(SavedStore.self) private var saved

    var body: some View {
        Group {
            if saved.stories.isEmpty {
                ScrollView {
                    EmptyStateView(title: "Nothing saved yet",
                                   message: "Tap the bookmark on any story to read or watch it later.")
                }
            } else {
                List {
                    ForEach(saved.stories) { story in
                        NavigationLink(value: story) { StoryRow(story: story) }
                            .listRowBackground(Brand.background)
                            .listRowSeparatorTint(Brand.line)
                    }
                    .onDelete { saved.remove(at: $0) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .brandBackground()
        .navigationTitle("Saved")
    }
}
