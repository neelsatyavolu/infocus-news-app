import SwiftUI

/// "Open in YouTube" and Share, under a player.
struct VideoActions: View {
    let url: URL
    let shareTitle: String

    var body: some View {
        HStack(spacing: 12) {
            Link(destination: url) {
                Label("Open in YouTube", systemImage: "arrow.up.right.square")
            }
            .buttonStyle(.brandSecondary)
            ShareLink(item: url, subject: Text(shareTitle), message: Text(shareTitle)) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.brandSecondary)
        }
    }
}
