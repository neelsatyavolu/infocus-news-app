import SwiftUI

/// Lexend for everything people read; Geist Mono only for data (durations,
/// dates in lists, counts). Sizes scale with Dynamic Type.
extension Font {
    enum LexendWeight: String {
        case regular = "Regular", medium = "Medium", semibold = "SemiBold", bold = "Bold"
    }

    static func lexend(_ size: CGFloat, _ weight: LexendWeight = .regular,
                       relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("Lexend-\(weight.rawValue)", size: size, relativeTo: style)
    }

    static func mono(_ size: CGFloat, medium: Bool = false, relativeTo style: Font.TextStyle = .caption) -> Font {
        .custom(medium ? "GeistMono-Medium" : "GeistMono-Regular", size: size, relativeTo: style)
    }

    // The type scale (DESIGN.md §10), sized for a phone.
    static let display = lexend(30, .semibold, relativeTo: .largeTitle)
    static let h1 = lexend(26, .semibold, relativeTo: .title)
    static let h2 = lexend(21, .semibold, relativeTo: .title2)
    static let h3 = lexend(17, .semibold, relativeTo: .headline)
    static let bodyText = lexend(16, .regular, relativeTo: .body)
    static let small = lexend(13, .regular, relativeTo: .footnote)
    static let button = lexend(15, .medium, relativeTo: .body)
}

extension View {
    /// Headline tracking: −2% for display/H1, −1% for H2/H3.
    func headline(_ font: Font, tracking: CGFloat = -0.3) -> some View {
        self.font(font).tracking(tracking).foregroundStyle(Brand.text)
    }
}

/// ALL CAPS label with wide tracking: kickers, section titles, tags.
struct Eyebrow: View {
    let text: String
    var color: Color = Brand.green
    var size: CGFloat = 11

    init(_ text: String, color: Color = Brand.green, size: CGFloat = 11) {
        self.text = text
        self.color = color
        self.size = size
    }

    var body: some View {
        Text(text.uppercased())
            .font(.lexend(size, .medium, relativeTo: .caption))
            .tracking(size * 0.16)
            .foregroundStyle(color)
            .lineLimit(1)
    }
}
