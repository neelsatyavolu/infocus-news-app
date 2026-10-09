import SwiftUI

/// One staff member: portrait, role, bio (when they wrote one) and their stories.
struct StaffDetailView: View {
    let member: StaffMember
    let model: StaffModel
    @State private var profile: Loadable<StaffProfile?> = .idle
    @State private var stories: [Story] = []
    @State private var storiesError: String?
    @State private var storiesLoading = false
    @State private var storiesLoaded = false
    @State private var loadedMemberID: String?

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
                    if storiesLoading && stories.isEmpty {
                        ProgressView()
                    } else if let storiesError {
                        ErrorStateView(title: "Couldn't load stories", message: storiesError) {
                            Task { await loadStories(force: true) }
                        }
                    } else if !stories.isEmpty {
                        storyList
                    }
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
        .task(id: member.id) {
            if loadedMemberID != member.id {
                profile = .idle
                stories = []
                storiesError = nil
                storiesLoading = false
                storiesLoaded = false
                loadedMemberID = member.id
            }
            await load()
        }
    }

    @ViewBuilder private var bio: some View {
        switch profile {
        case .idle, .loading:
            ArticleSkeleton()
        case .failed(let message):
            ErrorStateView(title: "Couldn't load this profile", message: message) {
                Task { await load(force: true) }
            }
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

    private func load(force: Bool = false) async {
        if force {
            profile = .idle
            stories = []
            storiesError = nil
            storiesLoading = false
            storiesLoaded = false
        }
        if case .idle = profile {
            profile = .loading
            do {
                let found = try await model.profile(for: member)
                guard loadedMemberID == member.id else { return }
                profile = .loaded(found)
            } catch is CancellationError {
                if case .loading = profile { profile = .idle }
                return
            } catch {
                guard loadedMemberID == member.id else { return }
                profile = .failed(Loadable<StaffProfile?>.message(for: error))
                return
            }
        }
        await loadStories(force: force)
    }

    private func loadStories(force: Bool = false) async {
        guard case .loaded(let found) = profile else { return }
        if storiesLoaded, !force { return }
        storiesError = nil
        guard let termID = found?.staffTermID else {
            storiesLoaded = true
            return
        }
        storiesLoading = true
        defer { storiesLoading = false }
        do {
            let page = try await WordPressClient.shared.stories(.init(staff: [termID], perPage: 10), page: 1)
            guard loadedMemberID == member.id else { return }
            stories = page.stories
            storiesLoaded = true
        } catch is CancellationError {
            return
        } catch {
            guard loadedMemberID == member.id else { return }
            storiesError = Loadable<[Story]>.message(for: error)
        }
    }
}
