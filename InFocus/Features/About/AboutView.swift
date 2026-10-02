import SwiftUI

/// infocusnews.tv/about: what InFocus is and its editorial policy.
struct AboutView: View {
    @State private var model = PageModel(slug: "about")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Nameplate(eyebrow: "About us", title: "InFocus", subtitle: "Palo Alto High School's student broadcast network")
                content.padding(Brand.gutter)
            }
            .frame(maxWidth: 720)
        }
        .brandBackground()
        .navigationTitle("About us")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .refreshable { await model.load(force: true) }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .idle, .loading:
            ArticleSkeleton()
        case .failed(let message):
            ErrorStateView(title: "Couldn't load About us", message: message) {
                Task { await model.load(force: true) }
            }
        case .loaded(let page):
            VStack(alignment: .leading, spacing: 24) {
                ArticleView(blocks: ArticleHTML.blocks(page.html))
                Link(destination: page.link) { Label("Open on infocusnews.tv", systemImage: "safari") }
                    .buttonStyle(.brandSecondary)
            }
        }
    }
}
