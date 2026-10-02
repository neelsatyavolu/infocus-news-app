import SwiftUI

/// Solid InFocus Green with Soft White text. One per view.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundStyle(Brand.softWhite)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? Brand.fillPressed : Brand.fill,
                        in: RoundedRectangle(cornerRadius: Brand.radius))
            .opacity(isEnabled ? 1 : 0.45)
            .contentShape(Rectangle())
    }
}

/// Outlined: 1px line, transparent fill, raised fill while pressed.
struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Brand.text

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.button)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 46)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? Brand.raised : Color.clear,
                        in: RoundedRectangle(cornerRadius: Brand.radius))
            .overlay(RoundedRectangle(cornerRadius: Brand.radius).strokeBorder(Brand.controlLine))
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var brandPrimary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var brandSecondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

/// A filter chip: green fill when selected, quiet outline otherwise.
struct Chip: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.lexend(14, .medium, relativeTo: .subheadline))
                .foregroundStyle(selected ? Brand.softWhite : Brand.secondary)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(selected ? Brand.fill : Brand.card, in: RoundedRectangle(cornerRadius: Brand.radius))
                .overlay(RoundedRectangle(cornerRadius: Brand.radius).strokeBorder(selected ? Color.clear : Brand.line))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
