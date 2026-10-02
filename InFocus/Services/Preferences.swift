import SwiftUI
import Observation

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// What the person chose, stored in UserDefaults.
@MainActor @Observable
final class Preferences {
    private let defaults: UserDefaults

    var appearance: Appearance { didSet { defaults.set(appearance.rawValue, forKey: Keys.appearance) } }
    var notifyShows: Bool { didSet { defaults.set(notifyShows, forKey: Keys.shows) } }
    var notifyStories: Bool { didSet { defaults.set(notifyStories, forKey: Keys.stories) } }
    var notifyLive: Bool { didSet { defaults.set(notifyLive, forKey: Keys.live) } }
    var onboarded: Bool { didSet { defaults.set(onboarded, forKey: Keys.onboarded) } }
    /// Remembered for the next announcement.
    var announcerName: String { didSet { defaults.set(announcerName, forKey: Keys.announcerName) } }
    var announcerEmail: String { didSet { defaults.set(announcerEmail, forKey: Keys.announcerEmail) } }

    var wantsAnyAlerts: Bool { notifyShows || notifyStories || notifyLive }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Keys.shows: true, Keys.stories: true, Keys.live: true])
        appearance = Appearance(rawValue: defaults.string(forKey: Keys.appearance) ?? "") ?? .system
        notifyShows = defaults.bool(forKey: Keys.shows)
        notifyStories = defaults.bool(forKey: Keys.stories)
        notifyLive = defaults.bool(forKey: Keys.live)
        onboarded = defaults.bool(forKey: Keys.onboarded)
        announcerName = defaults.string(forKey: Keys.announcerName) ?? ""
        announcerEmail = defaults.string(forKey: Keys.announcerEmail) ?? ""
    }

    private enum Keys {
        static let appearance = "appearance"
        static let shows = "notify.shows"
        static let stories = "notify.stories"
        static let live = "notify.live"
        static let onboarded = "onboarded"
        static let announcerName = "announce.name"
        static let announcerEmail = "announce.email"
    }
}
