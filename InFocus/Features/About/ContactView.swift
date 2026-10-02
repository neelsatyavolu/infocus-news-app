import SwiftUI

/// infocusnews.tv/contact-us, with the page's email addresses as buttons.
struct ContactView: View {
    @State private var model = PageModel(slug: "contact-us")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Nameplate(eyebrow: "Contact", title: "Get in touch", subtitle: "Questions, story tips and feedback")
                content.padding(Brand.gutter)
            }
            .frame(maxWidth: 720)
        }
        .brandBackground()
        .readableMargins()
        .navigationTitle("Contact")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .refreshable { await model.load(force: true) }
    }

    @ViewBuilder private var content: some View {
        switch model.state {
        case .idle, .loading:
            ArticleSkeleton()
        case .failed(let message):
            ErrorStateView(title: "Couldn't load Contact", message: message) {
                Task { await model.load(force: true) }
            }
        case .loaded(let page):
            let emails = ArticleHTML.emails(page.html)
            VStack(alignment: .leading, spacing: 24) {
                ArticleView(blocks: ArticleHTML.blocks(page.html))
                VStack(spacing: 10) {
                    ForEach(Array(emails.enumerated()), id: \.offset) { index, email in
                        if let url = URL(string: "mailto:\(email)") {
                            if index == 0 {
                                Link(destination: url) { Label("Email \(email)", systemImage: "envelope") }
                                    .buttonStyle(.brandPrimary)
                            } else {
                                Link(destination: url) { Label("Email \(email)", systemImage: "envelope") }
                                    .buttonStyle(.brandSecondary)
                            }
                        }
                    }
                    Link(destination: page.link) { Label("Open on infocusnews.tv", systemImage: "safari") }
                        .buttonStyle(.brandSecondary)
                }
            }
        }
    }
}
