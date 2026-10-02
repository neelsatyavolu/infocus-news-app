import SwiftUI

/// One staff member: portrait, role, bio (when they wrote one) and their stories.
struct StaffDetailView: View {
    let member: StaffMember
    let model: StaffModel
    @State private var profile: Loadable<StaffProfile?> = .idle
    @State private var stories: [Story] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Thumbnail(url: member.photoURL, ratio: 4 / 5)
                    .frame(maxWidth: 360)
                    .frame(maxWidth: .infinity)
                    .background(Brand.card)
                Nameplate(eyebrow: member.role, title: member.name, subtitle: "InFocus staff \(member.year)")
                VStack(alignment: .leading, spacing: 28) {
                    bio
                    if !stories.isEmpty { storyList }
                    Link(destination: member.profileURL) { Label("Open on infocusnews.tv", systemImage: "safari") }
                        .buttonStyle(.brandSecondary)
                }
                .padding(Brand.gutter)
            }
            .frame(maxWidth: 720)
        }
        .brandBackground()
        .readableMargins()
        .navigationTitle(member.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: member.id) { await load() }
    }

    @ViewBuilder private var bio: some View {
        switch profile {
        case .idle, .loading:
            ArticleSkeleton()
        case .loaded(let found?) where !found.bio.isEmpty:
            ArticleView(blocks: found.bio)
        default:
            EmptyView()
        }
    }

    private var storyList: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "Stories by \(member.name)")
            ForEach(stories) { story in
                NavigationLink(value: story) { StoryRow(story: story) }.buttonStyle(.plain)
                if story.id != stories.last?.id { Divider().overlay(Brand.line) }
            }
        }
    }

    private func load() async {
        guard case .idle = profile else { return }
        profile = .loading
        do {
            let found = try await model.profile(for: member)
            profile = .loaded(found)
            if let termID = found?.staffTermID {
                stories = (try? await WordPressClient.shared.stories(.init(staff: [termID], perPage: 10), page: 1))?.stories ?? []
            }
        } catch is CancellationError {
            profile = .idle
        } catch {
            profile = .failed(Loadable<StaffProfile?>.message(for: error))
        }
    }
}
