import SwiftUI

/// Card: raised surface, 1px line, 6px radius, no shadow.
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: Brand.radius))
            .overlay(RoundedRectangle(cornerRadius: Brand.radius).strokeBorder(Brand.line))
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View { modifier(CardBackground(padding: padding)) }

    /// The page background, edge to edge.
    func brandBackground() -> some View { background(Brand.background.ignoresSafeArea()) }

    /// For a ScrollView or List: its content in one centered column of
    /// readable width. No change on iPhone; no stretched rows or giant
    /// players on iPad.
    func readableMargins() -> some View { modifier(ReadableMargins()) }
}

private struct ReadableMargins: ViewModifier {
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.horizontal, max(0, (width - Brand.readableWidth) / 2), for: .scrollContent)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}

/// The web nameplate (DESIGN.md §10): a square plate with a 4px InFocus
/// Green strip along the bottom: eyebrow, SemiBold headline, one quiet line.
struct Nameplate<Trailing: View>: View {
    let eyebrow: String
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(eyebrow)
                    Text(title)
                        .headline(.h2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle {
                        Text(subtitle)
                            .font(.small)
                            .foregroundStyle(Brand.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                trailing
            }
            .padding(16)
            Rectangle().fill(Brand.fill).frame(height: 4)
        }
        .background(Brand.card)
        .accessibilityElement(children: .combine)
    }
}

extension Nameplate where Trailing == EmptyView {
    init(eyebrow: String, title: String, subtitle: String? = nil) {
        self.init(eyebrow: eyebrow, title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// Section title row: eyebrow on the left, optional action on the right.
struct SectionHeader: View {
    let title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Eyebrow(title, color: Brand.muted, size: 12)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.lexend(14, .medium, relativeTo: .subheadline))
                    .foregroundStyle(Brand.green)
                    .frame(minHeight: 44)
            }
        }
    }
}

/// An Ink tag with the one Record Red dot and LIVE in label style.
struct LiveTag: View {
    var label = "Live"

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(Brand.recordRed).frame(width: 7, height: 7)
            Text(label.uppercased())
                .font(.lexend(11, .medium, relativeTo: .caption))
                .tracking(1.6)
                .foregroundStyle(Brand.softWhite)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Brand.ink, in: RoundedRectangle(cornerRadius: Brand.tagRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

/// Small neutral tag (category, duration on a thumbnail).
struct Tag: View {
    let text: String
    var mono = false

    var body: some View {
        Text(mono ? text : text.uppercased())
            .font(mono ? .mono(11, medium: true) : .lexend(10, .medium, relativeTo: .caption2))
            .tracking(mono ? 0 : 1.2)
            .monospacedDigit()
            .foregroundStyle(Brand.softWhite)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Brand.ink.opacity(0.86), in: RoundedRectangle(cornerRadius: Brand.tagRadius))
    }
}
