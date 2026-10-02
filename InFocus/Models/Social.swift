import Foundation

/// InFocus elsewhere. Plain https links: iOS opens the network's app when
/// it's installed (universal links) and Safari otherwise.
struct SocialLink: Identifiable, Hashable, Sendable {
    let network: String
    let handle: String
    let url: URL
    let symbol: String

    var id: String { network }

    static let all: [SocialLink] = [
        SocialLink(network: "Instagram", handle: "@infocusnews",
                   url: URL(string: "https://www.instagram.com/infocusnews")!, symbol: "camera"),
        SocialLink(network: "YouTube", handle: "@infocusnews",
                   url: YouTube.channelURL, symbol: "play.rectangle"),
        SocialLink(network: "TikTok", handle: "@palyinfocus",
                   url: URL(string: "https://www.tiktok.com/@palyinfocus")!, symbol: "music.note"),
        SocialLink(network: "X", handle: "@palyinfocus",
                   url: URL(string: "https://x.com/palyinfocus")!, symbol: "at"),
        SocialLink(network: "Website", handle: "infocusnews.tv",
                   url: AppConfig.newsSiteURL, symbol: "safari"),
    ]
}
