import SwiftUI
import Observation

enum AppTab: Hashable {
    case home, shows, stories, live, more
}

/// Which tab is showing, and anything opened from outside (a notification).
@MainActor @Observable
final class Router {
    var tab: AppTab = .home
    /// Shown as a sheet over whatever tab is open.
    var presented: Destination?
    /// Switches to Stories with its search field focused (Home's search button).
    var focusStorySearch = false

    func open(_ destination: Destination) {
        presented = destination
    }

    #if DEBUG
    /// Screenshots and manual checks: `-InFocusTab stories`, `-InFocusOpen story:2619`.
    func applyLaunchArguments(_ defaults: UserDefaults = .standard) {
        switch defaults.string(forKey: "InFocusTab") {
        case "shows": tab = .shows
        case "stories": tab = .stories
        case "live": tab = .live
        case "more": tab = .more
        default: break
        }
        let parts = defaults.string(forKey: "InFocusOpen")?.split(separator: ":").map(String.init) ?? []
        guard parts.count == 2 else { return }
        switch parts[0] {
        case "story": Int(parts[1]).map { open(.story(id: $0)) }
        case "show": open(.show(videoId: parts[1], title: nil))
        case "live": open(.live(videoId: parts[1], title: nil))
        default: break
        }
    }
    #endif
}

/// Everything the app shares, created once.
@MainActor
final class AppModel {
    static let shared = AppModel()

    let preferences = Preferences()
    let shows = ShowsStore()
    let live = LiveStore()
    let saved = SavedStore()
    let router: Router = {
        let router = Router()
        #if DEBUG
        router.applyLaunchArguments()
        #endif
        return router
    }()
    lazy var push = PushManager(preferences: preferences)
}
