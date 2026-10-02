import Foundation

/// Fixed addresses and build facts.
enum AppConfig {
    /// The InFocus Portal (shows, live, announcements, push). Info.plist `InFocusPortalURL`.
    static let portalURL: URL = {
        #if DEBUG
        // Debug builds can point at a local Portal: `-InFocusPortalURL http://127.0.0.1:3000`.
        if let raw = UserDefaults.standard.string(forKey: "InFocusPortalURL"), let url = URL(string: raw) { return url }
        #endif
        let raw = Bundle.main.object(forInfoDictionaryKey: "InFocusPortalURL") as? String
        return raw.flatMap(URL.init(string:)) ?? URL(string: "https://infocuspaly.com")!
    }()

    static let newsSiteURL = URL(string: "https://infocusnews.tv/")!
    static let aboutURL = URL(string: "https://infocusnews.tv/about/")!
    static let privacyURL = URL(string: "https://infocusnews.tv/about/")!

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    /// Which APNs host accepts this build's device token.
    static var pushEnvironment: String {
        #if DEBUG
        "development"
        #else
        "production"
        #endif
    }
}
