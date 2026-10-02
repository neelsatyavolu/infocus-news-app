import SwiftUI

/// Pulsing Ink 3 block while content loads (still when Reduce Motion is on).
struct Skeleton: View {
    var height: CGFloat? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var dim = false

    var body: some View {
        RoundedRectangle(cornerRadius: Brand.radius)
            .fill(Brand.raised)
            .frame(height: height)
            .opacity(dim ? 0.45 : 1)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.9).repeatForever()) { dim = true }
            }
            .accessibilityHidden(true)
    }
}

/// A list-shaped placeholder: thumbnail + two lines, repeated.
struct SkeletonList: View {
    var rows = 5

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 12) {
                    Skeleton().frame(width: 128, height: 72)
                    VStack(alignment: .leading, spacing: 8) {
                        Skeleton(height: 12).frame(width: 70)
                        Skeleton(height: 16)
                        Skeleton(height: 16).frame(width: 140)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Loading")
    }
}

/// "Couldn't load": an icon, words and Try again (never color alone).
struct ErrorStateView: View {
    let title: String
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 30, weight: .regular))
                .foregroundStyle(Brand.danger)
                .accessibilityHidden(true)
            Text(title).headline(.h3)
            Text(message)
                .font(.small)
                .foregroundStyle(Brand.secondary)
                .multilineTextAlignment(.center)
            Button("Try again", action: retry)
                .buttonStyle(.brandSecondary)
                .frame(maxWidth: 220)
                .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

/// Empty state: the mark, one SemiBold line, one quiet line, optional action.
struct EmptyStateView: View {
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 12) {
            Image("Mark")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .accessibilityHidden(true)
            Text(title).headline(.h3)
            Text(message)
                .font(.small)
                .foregroundStyle(Brand.secondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.brandPrimary)
                    .frame(maxWidth: 260)
                    .padding(.top, 4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

/// A 16:9 image with an Ink 3 placeholder; never stretches.
struct Thumbnail: View {
    let url: URL?
    var ratio: CGFloat = 16 / 9

    var body: some View {
        Rectangle()
            .fill(Brand.raised)
            .aspectRatio(ratio, contentMode: .fit)
            .overlay {
                AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else if case .failure = phase {
                        Image("Mark").resizable().scaledToFit().padding(18).opacity(0.35)
                    }
                }
            }
            .clipped()
            .accessibilityHidden(true)
    }
}
