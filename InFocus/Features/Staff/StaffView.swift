import SwiftUI

/// This year's staff in the site's order (producers first), any past year a tap away.
struct StaffView: View {
    @State private var model = StaffModel()
    private let columns = [GridItem(.flexible(), spacing: 12, alignment: .top),
                           GridItem(.flexible(), spacing: 12, alignment: .top)]

    var body: some View {
        ScrollView {
            content.padding(Brand.gutter)
        }
        .brandBackground()
        .readableMargins()
        .navigationTitle(model.selectedYear.map { "Staff \($0)" } ?? "Staff")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: StaffMember.self) { StaffDetailView(member: $0, model: model) }
        .toolbar {
            if model.years.count > 1 {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(model.years, id: \.self) { year in
                            Button {
                                Task { await model.load(year: year) }
                            } label: {
                                if year == model.selectedYear { Label(year, systemImage: "checkmark") } else { Text(year) }
                            }
                        }
                    } label: {
                        Label("School year", systemImage: "calendar")
                    }
                }
            }
        }
        .task { await model.load() }
        .refreshable { await model.load(year: model.selectedYear, force: true) }
    }

    @ViewBuilder private var content: some View {
        switch model.directory {
        case .idle, .loading:
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(0..<6, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        Skeleton().aspectRatio(4 / 5, contentMode: .fit)
                        Skeleton(height: 12).frame(width: 80)
                        Skeleton(height: 16)
                    }
                }
            }
        case .failed(let message):
            ErrorStateView(title: "Couldn't load the staff", message: message) {
                Task { await model.load(year: model.selectedYear, force: true) }
            }
        case .loaded(let directory) where directory.members.isEmpty:
            EmptyStateView(title: "No staff listed", message: "The \(directory.year) staff isn't posted yet.")
        case .loaded(let directory):
            LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                ForEach(directory.members) { member in
                    NavigationLink(value: member) { StaffTile(member: member) }
                        .buttonStyle(.plain)
                }
            }
        }
    }
}

/// Portrait, role and name.
private struct StaffTile: View {
    let member: StaffMember

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Thumbnail(url: member.photoURL, ratio: 4 / 5)
                .clipShape(RoundedRectangle(cornerRadius: Brand.radius))
            Text(member.role.uppercased())
                .font(.lexend(10, .medium, relativeTo: .caption2))
                .tracking(1.4)
                .foregroundStyle(Brand.green)
                .fixedSize(horizontal: false, vertical: true)
            Text(member.name)
                .font(.lexend(16, .semibold, relativeTo: .headline))
                .foregroundStyle(Brand.text)
                .lineLimit(2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(member.name), \(member.role)")
    }
}
