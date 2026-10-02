import Foundation
import Observation

/// Stories saved for later, kept only on this device (Application Support JSON).
@MainActor @Observable
final class SavedStore {
    private(set) var stories: [Story] = []
    private let fileURL: URL

    init(fileURL: URL = SavedStore.defaultURL) {
        self.fileURL = fileURL
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([Story].self, from: data) {
            stories = saved
        }
    }

    func contains(_ story: Story) -> Bool { stories.contains { $0.id == story.id } }

    func toggle(_ story: Story) {
        if contains(story) {
            stories.removeAll { $0.id == story.id }
        } else {
            stories.insert(story, at: 0)
        }
        persist()
    }

    func remove(at offsets: IndexSet) {
        stories.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(stories).write(to: fileURL, options: .atomic)
        } catch {
            print("InFocus: couldn't save stories: \(error.localizedDescription)")
        }
    }

    nonisolated static var defaultURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "saved-stories.json")
    }
}
