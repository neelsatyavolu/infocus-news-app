import SwiftUI

/// Native rendering of a site page: Lexend headings, body text, green
/// square bullets, bold and tappable links (mailto opens Mail).
struct ArticleView: View {
    let blocks: [ArticleBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                view(for: block)
                    .padding(.top, topSpacing(index))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private func view(for block: ArticleBlock) -> some View {
        switch block {
        case .heading(let level, let text) where level <= 3:
            Text(text).headline(.h2).fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
        case .heading(_, let text):
            Eyebrow(text, color: Brand.green, size: 12)
                .accessibilityAddTraits(.isHeader)
        case .paragraph(let text):
            body(text)
        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Rectangle().fill(Brand.green).frame(width: 6, height: 6)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] + 3 }
                body(text)
            }
        }
    }

    private func body(_ text: AttributedString) -> some View {
        Text(Self.styled(text))
            .font(.bodyText)
            .lineSpacing(4)
            .foregroundStyle(Brand.text)
            .tint(Brand.green)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// More room above a section heading than between paragraphs.
    private func topSpacing(_ index: Int) -> CGFloat {
        guard index > 0, case .heading(let level, _) = blocks[index] else { return 0 }
        return level <= 3 ? 20 : 8
    }

    /// Bold runs in Lexend SemiBold (no synthesized bold), links underlined in green.
    static func styled(_ text: AttributedString) -> AttributedString {
        var result = text
        for run in result.runs {
            if run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
                result[run.range].font = .lexend(16, .semibold, relativeTo: .body)
                result[run.range].inlinePresentationIntent = nil
            }
            if run.link != nil {
                result[run.range].foregroundColor = Brand.green
                result[run.range].underlineStyle = .single
            }
        }
        return result
    }
}

/// Loads a site page by slug; shows skeleton / error / content.
@MainActor @Observable
final class PageModel {
    private(set) var state: Loadable<WordPressClient.Page> = .idle
    let slug: String

    init(slug: String) {
        self.slug = slug
    }

    func load(force: Bool = false) async {
        if !force, state.value != nil || state.isLoading { return }
        if state.value == nil { state = .loading }
        do {
            state = .loaded(try await WordPressClient.shared.page(slug: slug))
        } catch is CancellationError {
            if state.isLoading { state = .idle }
        } catch {
            if state.value == nil { state = .failed(Loadable<WordPressClient.Page>.message(for: error)) }
        }
    }
}

/// Paragraph-shaped skeleton for page bodies.
struct ArticleSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Skeleton(height: 24).frame(width: 220)
            ForEach(0..<3, id: \.self) { _ in
                Skeleton(height: 14)
                Skeleton(height: 14)
                Skeleton(height: 14).frame(width: 200).padding(.bottom, 8)
            }
        }
    }
}
